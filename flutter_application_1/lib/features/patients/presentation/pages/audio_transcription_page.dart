import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/llm_normalization_service.dart';
import '../../../../core/services/tflite_extractor.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'audio_confirmation_page.dart';

enum _RecordState { idle, recording, transcribing }

class AudioTranscriptionPage extends StatefulWidget {
  final String pacienteId;
  final String pacienteNombre;

  AudioTranscriptionPage({
    super.key,
    required this.pacienteId,
    required this.pacienteNombre,
  });

  @override
  State<AudioTranscriptionPage> createState() => _AudioTranscriptionPageState();
}

class _AudioTranscriptionPageState extends State<AudioTranscriptionPage> {
  // ── Model state ───────────────────────────────────────────────────────────
  bool _modelReady = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _downloadError = false;

  // ── Recording / transcription state ───────────────────────────────────────
  _RecordState _recordState = _RecordState.idle;
  DateTime? _recordingStart;
  String? _pendingAudioPath;

  // ── NER processing state ──────────────────────────────────────────────────
  bool _isProcessing = false;

  // ── Core objects ──────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  final Whisper _whisper = Whisper(model: WhisperModel.tiny);
  final TextEditingController _transcriptionController =
      TextEditingController();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _transcriptionController.dispose();
    super.dispose();
  }

  // ── Model management ──────────────────────────────────────────────────────

  Future<String> _modelPath() async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/ggml-tiny.bin';
  }

  Future<void> _checkModel() async {
    final path = await _modelPath();
    if (File(path).existsSync()) {
      if (mounted) setState(() => _modelReady = true);
    } else {
      await _downloadModel();
    }
  }

  Future<void> _downloadModel() async {
    if (!mounted) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadError = false;
    });

    final path = await _modelPath();
    try {
      await Dio().download(
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
        path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _modelReady = true;
        });
      }
    } catch (_) {
      try {
        File(path).deleteSync();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadError = true;
        });
      }
    }
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  Future<void> _toggleRecording() async {
    if (_recordState == _RecordState.recording) {
      final path = await _recorder.stop();

      final elapsed = _recordingStart != null
          ? DateTime.now().difference(_recordingStart!).inSeconds
          : 99;

      if (elapsed < 2) {
        if (mounted) setState(() => _recordState = _RecordState.idle);
        _showSnack(
            'Grabación muy corta. Habla más tiempo e intenta de nuevo.');
        if (path != null) _deleteFile(path);
        return;
      }

      if (path == null) {
        if (mounted) setState(() => _recordState = _RecordState.idle);
        return;
      }

      // Un WAV válido (cabecera + PCM) pesa más de 44 bytes. Si el permiso de
      // micrófono fue denegado, record_android no captura audio y genera un
      // archivo vacío/corrupto que Whisper no puede abrir.
      final file = File(path);
      if (!file.existsSync() || file.lengthSync() <= 44) {
        if (mounted) setState(() => _recordState = _RecordState.idle);
        _showSnack(
            'No se capturó audio. Revisa el permiso de micrófono en Ajustes.');
        _deleteFile(path);
        return;
      }

      _pendingAudioPath = path;
      if (mounted) setState(() => _recordState = _RecordState.transcribing);
      await _transcribeAudio(path);
    } else {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showSnack(
            'Se necesita permiso de micrófono para grabar. Actívalo en Ajustes.');
        return;
      }

      _transcriptionController.clear();
      _recordingStart = DateTime.now();

      final tempDir = await getTemporaryDirectory();
      final audioPath =
          '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: audioPath,
      );

      if (mounted) setState(() => _recordState = _RecordState.recording);
    }
  }

  // ── Transcription ─────────────────────────────────────────────────────────

  Future<void> _transcribeAudio(String audioPath) async {
    try {
      final response = await _whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: 'es',
          isTranslate: false,
        ),
      );

      final text = response.text.trim();
      if (!mounted) return;
      setState(() {
        _transcriptionController.text = text;
        _recordState = _RecordState.idle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _recordState = _RecordState.idle);
      _showSnack(
          'No se pudo transcribir el audio. Puedes escribir el texto manualmente.');
    } finally {
      _deleteFile(audioPath);
    }
  }

  // ── NER analysis ──────────────────────────────────────────────────────────

  Future<void> _analyzeText(String text) async {
    setState(() => _isProcessing = true);
    try {
      // Normalización de vocabulario coloquial vía LLM antes del BiLSTM.
      // Nunca bloquea: sin conexión, timeout o error del LLM, sigue con el
      // texto original tal cual (ver LlmNormalizationService).
      final normalization = await sl<LlmNormalizationService>().normalize(text);

      final extractor = sl<NerExtractor>();
      final fields = await Future(() => extractor.infer(normalization.text));
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AudioConfirmationPage(
            pacienteId: widget.pacienteId,
            pacienteNombre: widget.pacienteNombre,
            originalText: normalization.text,
            clinicalFields: fields,
            normalizadoPorLlm: normalization.normalizado,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _deleteFile(String path) {
    try {
      File(path).deleteSync();
    } catch (_) {}
  }

  bool get _micEnabled =>
      _modelReady &&
      _recordState != _RecordState.transcribing &&
      !_isProcessing;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).statusBarBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Transcripción de Audio del Paciente',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSecondaryHeader(context),
          _buildSyncBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  if (_isDownloading || _downloadError)
                    _buildModelCard(),
                  if (_isDownloading || _downloadError)
                    SizedBox(height: 12),
                  _buildTranscriptionCard(),
                  SizedBox(height: 12),
                  _buildAudioControls(),
                  SizedBox(height: 12),
                  _buildMicCard(),
                  SizedBox(height: 12),
                  _buildGuideCard(),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Model download card ───────────────────────────────────────────────────

  Widget _buildModelCard() {
    if (_downloadError) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_off_rounded,
                    color: Color(0xFFDC2626), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No se pudo descargar el modelo.',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              'Conéctate a internet para descargarlo la primera vez.\nDespués funcionará 100% sin conexión.',
              style: TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _downloadModel,
                icon: Icon(Icons.refresh_rounded, size: 16),
                label: Text('Reintentar descarga',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFFDC2626),
                  side: BorderSide(color: Color(0xFFDC2626)),
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Downloading
    final pct = (_downloadProgress * 100).toStringAsFixed(0);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.download_rounded,
                  color: AppColors.of(context).info, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Descargando modelo de transcripción ($pct%)...',
                  style: TextStyle(
                    color: AppColors.of(context).info,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Solo esta vez — después funciona sin internet.',
            style: TextStyle(
                color: AppColors.of(context).info, fontSize: 11),
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _downloadProgress,
              minHeight: 6,
              backgroundColor: Color(0xFFBFDBFE),
              color: AppColors.of(context).info,
            ),
          ),
        ],
      ),
    );
  }

  // ── Secondary header ──────────────────────────────────────────────────────

  Widget _buildSecondaryHeader(BuildContext context) {
    return Container(
      color: AppColors.of(context).surface,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back,
                color: AppColors.of(context).textPrimary, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'EpiDiagnostix-Mayab',
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          Icon(Icons.cloud_outlined,
              color: AppColors.of(context).textSecondary, size: 22),
        ],
      ),
    );
  }

  // ── Sync bar ──────────────────────────────────────────────────────────────

  Widget _buildSyncBar() {
    return Container(
      color: Color(0xFFEFF6FF),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.sync_rounded, color: AppColors.of(context).info, size: 15),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sincronización en curso - Modo Offline activo',
              style: TextStyle(color: AppColors.of(context).info, fontSize: 11),
            ),
          ),
          Text(
            'v2.4.0',
            style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Transcription card ────────────────────────────────────────────────────

  Widget _buildTranscriptionCard() {
    final fieldEnabled =
        _recordState == _RecordState.idle && !_isProcessing;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transcripción en Tiempo Real',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _transcriptionController,
            enabled: fieldEnabled,
            minLines: 3,
            maxLines: 6,
            style: TextStyle(
                fontSize: 13, color: AppColors.of(context).textPrimary, height: 1.5),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.of(context).inputBackground,
              hintText:
                  'Habla o escribe la descripción del paciente…\n'
                  'Ej: "Mujer de 34 años, 62 kg, temperatura 38.5, presión 120/80"',
              hintStyle: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).textMuted,
                height: 1.5,
              ),
              contentPadding: EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.of(context).border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.of(context).border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: AppColors.of(context).primary, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: 12),
          _buildStatusRow(),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ||
                      _recordState != _RecordState.idle
                  ? null
                  : () {
                      final text =
                          _transcriptionController.text.trim();
                      if (text.isEmpty) {
                        _showSnack(
                            'Escribe o dicta algo antes de analizar.');
                        return;
                      }
                      _analyzeText(text);
                    },
              icon: Icon(Icons.biotech_rounded, size: 18),
              label: Text(
                'Analizar texto con IA',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.of(context).primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.of(context).textMuted,
                disabledForegroundColor: Colors.white70,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    if (_isProcessing) {
      return Row(children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.of(context).primary),
        ),
        SizedBox(width: 10),
        Text('Analizando con IA…',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.w500)),
      ]);
    }
    if (_recordState == _RecordState.transcribing) {
      return Row(children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: Color(0xFF7C3AED)),
        ),
        SizedBox(width: 10),
        Text('Transcribiendo con Whisper…',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w500)),
      ]);
    }
    if (_recordState == _RecordState.recording) {
      return Row(children: [
        Icon(Icons.graphic_eq_rounded,
            color: Color(0xFFDC2626), size: 18),
        SizedBox(width: 8),
        Text('Grabando audio…',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w500)),
      ]);
    }
    if (_isDownloading) {
      return Text(
        'Descargando modelo — el micrófono estará disponible al terminar.',
        style: TextStyle(
            fontSize: 11, color: AppColors.of(context).textMuted, height: 1.4),
      );
    }
    return Text(
      'Presiona el micrófono para grabar, o escribe el texto y presiona Analizar.',
      style: TextStyle(
          fontSize: 11, color: AppColors.of(context).textMuted, height: 1.4),
    );
  }

  // ── Audio controls row ────────────────────────────────────────────────────

  Widget _buildAudioControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Calidad de audio',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.of(context).textMuted)),
              SizedBox(width: 8),
              _buildAudioBars(),
            ],
          ),
          GestureDetector(
            onTap: () {},
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.tune_rounded,
                    color: AppColors.of(context).primary, size: 15),
                SizedBox(width: 4),
                Text(
                  'Añadir nota\nmanual',
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBars() {
    final heights = [5.0, 9.0, 14.0, 9.0, 5.0];
    final isRec = _recordState == _RecordState.recording;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights.map((h) {
        return Container(
          width: 4,
          height: h,
          margin: EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: isRec
                ? Color(0xFFDC2626)
                : AppColors.of(context).success,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  // ── Mic card ──────────────────────────────────────────────────────────────

  Widget _buildMicCard() {
    final role = context.read<AuthProvider>().currentRole;
    if (role == UserRole.usuario) return _buildMicCardLocked();

    final isRec = _recordState == _RecordState.recording;
    final isTranscribing = _recordState == _RecordState.transcribing;

    Color btnColor;
    IconData btnIcon;
    String titleText;
    String subtitleText;

    if (isTranscribing || _isProcessing) {
      btnColor = AppColors.of(context).textMuted;
      btnIcon = Icons.mic_rounded;
      titleText = isTranscribing ? 'Transcribiendo…' : 'Procesando…';
      subtitleText = isTranscribing
          ? 'Whisper está analizando el audio.\nEsto puede tardar unos segundos.'
          : 'El modelo NER está extrayendo los datos clínicos.';
    } else if (isRec) {
      btnColor = Color(0xFFDC2626);
      btnIcon = Icons.stop_rounded;
      titleText = 'Grabando...\nPresiona para analizar';
      subtitleText =
          'El micrófono está capturando tu voz.\nPresiona stop cuando termines.';
    } else {
      btnColor = _micEnabled ? AppColors.of(context).primary : AppColors.of(context).textMuted;
      btnIcon = Icons.mic_rounded;
      titleText = _isDownloading
          ? 'Descargando modelo…'
          : _downloadError
              ? 'Modelo no disponible'
              : 'Presiona y empieza a\nhablar con tu paciente';
      subtitleText = _isDownloading
          ? 'Espera a que termine la descarga\npara usar el micrófono.'
          : _downloadError
              ? 'Descarga el modelo para usar el micrófono,\no escribe el texto manualmente.'
              : 'El audio se procesará localmente con Whisper\nsin enviar datos a internet.';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _micEnabled ? _toggleRecording : null,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: btnColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: btnColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: isTranscribing
                  ? Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Icon(btnIcon, color: Colors.white, size: 30),
            ),
          ),
          SizedBox(height: 18),
          Text(
            titleText,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isRec
                  ? Color(0xFFDC2626)
                  : AppColors.of(context).textPrimary,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            subtitleText,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.of(context).textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Mic card locked (rol usuario) ────────────────────────────────────────

  Widget _buildMicCardLocked() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Tooltip(
            message: 'Disponible en plan Intermedio',
            child: GestureDetector(
              onTap: () =>
                  _showSnack('Disponible en plan Intermedio'),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.of(context).textMuted,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.of(context).textMuted.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Micrófono no disponible\nen tu plan actual',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Actualiza al plan Intermedio para grabar\ny transcribir audio con IA.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.of(context).textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Guide card ────────────────────────────────────────────────────────────

  Widget _buildGuideCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [Color(0xFF0D3D2A), Color(0xFF1B6E52)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 110,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guia de Vigilancia\nEpidemiológica',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Recuerda preguntar sobre viajes recientes a zonas endémicas y contacto con otros casos sintomáticos.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
