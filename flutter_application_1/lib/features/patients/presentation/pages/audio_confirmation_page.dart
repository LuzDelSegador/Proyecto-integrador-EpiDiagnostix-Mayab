import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/token_storage.dart';
import '../../data/models/patient_record.dart';
import '../../data/repositories/patient_local_repository.dart';
import '../../../attentions/data/models/medicamento.dart';
import '../../../sync/data/sync_service.dart';

enum _GpsStatus { loading, ready, unavailable }

class AudioConfirmationPage extends StatefulWidget {
  final String pacienteId;
  final String pacienteNombre;
  final Map<String, dynamic> clinicalFields;
  final String originalText;

  const AudioConfirmationPage({
    super.key,
    required this.pacienteId,
    required this.pacienteNombre,
    required this.clinicalFields,
    required this.originalText,
  });

  @override
  State<AudioConfirmationPage> createState() => _AudioConfirmationPageState();
}

class _AudioConfirmationPageState extends State<AudioConfirmationPage> {
  bool _isEditing = false;

  // ── GPS ────────────────────────────────────────────────────────────────────
  double? _latitud;
  double? _longitud;
  _GpsStatus _gpsStatus = _GpsStatus.loading;

  // ── Perfil del paciente (identidad ya existe, solo lectura/edad-género) ────
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;

  // ── Ubicación/comunidad de ESTA consulta (requerido por MS2) ──────────────
  late final TextEditingController _comunidadController;
  late final TextEditingController _municipioController;

  // ── Datos clínicos vitales ─────────────────────────────────────────────────
  late final TextEditingController _categoryController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;
  late final TextEditingController _glucoseController;
  late final TextEditingController _tempController;
  late final TextEditingController _heartRateController;
  late final TextEditingController _durationController;
  late final TextEditingController _saturacionController;

  // ── Datos manuales nuevos (no los extrae el BiLSTM) ────────────────────────
  late final TextEditingController _motivoController;
  late final TextEditingController _diagnosticoController;
  final List<Medicamento> _medicamentos = [];

  bool _detected(String key) => widget.clinicalFields.containsKey(key);

  @override
  void initState() {
    super.initState();
    final f = widget.clinicalFields;

    _ageController      = TextEditingController(text: f['edad']?.toString() ?? '');
    _genderController   = TextEditingController(
      text: f['sexo'] == 'M'
          ? 'Masculino'
          : f['sexo'] == 'F'
              ? 'Femenino'
              : '',
    );
    _comunidadController = TextEditingController(text: '');
    _municipioController = TextEditingController(text: '');

    _categoryController   = TextEditingController(text: f['categoria_sintoma']?.toString() ?? '');
    _weightController     = TextEditingController(text: f['peso_kg']?.toString() ?? '');
    _heightController     = TextEditingController(text: f['talla_cm']?.toString() ?? '');
    _systolicController   = TextEditingController(text: f['presion_sistolica']?.toString() ?? '');
    _diastolicController  = TextEditingController(text: f['presion_diastolica']?.toString() ?? '');
    _glucoseController    = TextEditingController(text: f['glucosa_mg_dl']?.toString() ?? '');
    _tempController       = TextEditingController(text: f['temperatura_c']?.toString() ?? '');
    _heartRateController  = TextEditingController(text: f['frecuencia_cardiaca_bpm']?.toString() ?? '');
    _durationController   = TextEditingController(text: f['duracion_sintomas_dias']?.toString() ?? '');
    _saturacionController = TextEditingController(text: '');

    _motivoController      = TextEditingController();
    _diagnosticoController = TextEditingController();

    _cargarComunidadPaciente();
    _captureGps();
  }

  // Prellena comunidad/municipio con los datos de identidad del paciente
  // (capturados en el alta CURP), editable por si esta consulta ocurre en
  // otro lugar (ej. brigada itinerante).
  Future<void> _cargarComunidadPaciente() async {
    final paciente = await sl<PatientLocalRepository>().obtenerPorId(widget.pacienteId);
    if (!mounted || paciente == null) return;
    setState(() {
      _comunidadController.text = paciente.comunidad ?? '';
      _municipioController.text = paciente.municipio ?? '';
    });
  }

  // ── GPS: captura en background ─────────────────────────────────────────────

  Future<void> _captureGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _gpsStatus = _GpsStatus.unavailable);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      setState(() {
        _latitud   = pos.latitude;
        _longitud  = pos.longitude;
        _gpsStatus = _GpsStatus.ready;
      });
      if (_comunidadController.text.isEmpty) {
        _tryReverseGeocode(pos.latitude, pos.longitude);
      }
    } catch (_) {
      if (mounted) setState(() => _gpsStatus = _GpsStatus.unavailable);
    }
  }

  Future<void> _tryReverseGeocode(double lat, double lng) async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) return;

      final response = await Dio().get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': lat,
          'lon': lng,
          'zoom': 10,
          'accept-language': 'es',
        },
        options: Options(
          headers: {'User-Agent': 'EpiDiagnostix/2.0'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      if (!mounted) return;
      final address = response.data?['address'] as Map<String, dynamic>?;
      if (address == null) return;

      final city = address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['municipality'] as String?;
      final state = address['state'] as String?;

      final parts = <String>[
        if (city != null && city.isNotEmpty) city,
        if (state != null && state.isNotEmpty) state,
      ];
      final locality = parts.join(', ');
      if (locality.isNotEmpty && _comunidadController.text.isEmpty) {
        setState(() => _comunidadController.text = locality);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ageController.dispose();
    _genderController.dispose();
    _comunidadController.dispose();
    _municipioController.dispose();
    _categoryController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    _tempController.dispose();
    _heartRateController.dispose();
    _durationController.dispose();
    _saturacionController.dispose();
    _motivoController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }

  // ── GPS row widget ────────────────────────────────────────────────────────

  Widget _buildGpsRow() {
    return switch (_gpsStatus) {
      _GpsStatus.loading => const Row(
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Obteniendo ubicación GPS...',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      _GpsStatus.ready => Row(
          children: [
            const Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'GPS: ${_latitud!.toStringAsFixed(4)}, ${_longitud!.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      _GpsStatus.unavailable => const Row(
          children: [
            Icon(Icons.location_off, size: 12, color: AppColors.textMuted),
            SizedBox(width: 4),
            Text(
              'GPS no disponible',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
    };
  }

  // ── Guardar consulta (paciente ya identificado por CURP) en SQLite ───────

  /// Combina lo detectado por el BiLSTM con las ediciones/campos manuales del
  /// usuario en un solo mapa — esto es lo que queda en campos_extraidos y lo
  /// que SyncService traduce al payload de POST /atenciones.
  Map<String, dynamic> _buildFinalCampos(String personalId) {
    final campos = Map<String, dynamic>.from(widget.clinicalFields);

    void setTexto(String key, String value) {
      if (value.trim().isEmpty) {
        campos.remove(key);
      } else {
        campos[key] = value.trim();
      }
    }

    void setNum(String key, String value, {bool esEntero = false}) {
      final v = value.trim();
      if (v.isEmpty) {
        campos.remove(key);
        return;
      }
      campos[key] = esEntero ? (int.tryParse(v) ?? v) : (double.tryParse(v) ?? v);
    }

    setNum('edad', _ageController.text, esEntero: true);
    final generoTexto = _genderController.text.trim();
    if (generoTexto.isEmpty) {
      campos.remove('sexo');
    } else if (generoTexto == 'Masculino') {
      campos['sexo'] = 'M';
    } else if (generoTexto == 'Femenino') {
      campos['sexo'] = 'F';
    } else {
      campos['sexo'] = generoTexto;
    }
    setTexto('categoria_sintoma', _categoryController.text);
    setNum('peso_kg', _weightController.text);
    setNum('talla_cm', _heightController.text);
    setNum('presion_sistolica', _systolicController.text, esEntero: true);
    setNum('presion_diastolica', _diastolicController.text, esEntero: true);
    setNum('glucosa_mg_dl', _glucoseController.text, esEntero: true);
    setNum('temperatura_c', _tempController.text);
    setNum('frecuencia_cardiaca_bpm', _heartRateController.text, esEntero: true);
    setNum('duracion_sintomas_dias', _durationController.text, esEntero: true);
    setNum('saturacion_oxigeno', _saturacionController.text, esEntero: true);

    campos['comunidad']       = _comunidadController.text.trim();
    campos['municipio']       = _municipioController.text.trim();
    campos['motivo_consulta'] = _motivoController.text.trim();
    setTexto('diagnostico_descripcion', _diagnosticoController.text);
    if (_medicamentos.isNotEmpty) {
      campos['medicamentos'] = _medicamentos.map((m) => m.toJson()).toList();
    } else {
      campos.remove('medicamentos');
    }
    campos['personal_id'] = personalId;

    return campos;
  }

  Future<void> _saveAndSync() async {
    final municipio = _municipioController.text.trim();
    final motivo    = _motivoController.text.trim();

    if (municipio.isEmpty) {
      _showErrorSnack('Ingresa el municipio de la consulta');
      return;
    }
    if (motivo.isEmpty) {
      _showErrorSnack('Ingresa el motivo de la consulta');
      return;
    }

    final personalId = await sl<TokenStorage>().getPersonalId();
    if (personalId == null || personalId.isEmpty) {
      _showErrorSnack('Sesión inválida. Vuelve a iniciar sesión.');
      return;
    }

    bool saved = false;
    try {
      final repo = sl<PatientLocalRepository>();
      await repo.guardarConsulta(
        widget.pacienteId,
        PatientRecord(
          textoOriginal:   widget.originalText,
          camposExtraidos: _buildFinalCampos(personalId),
          fechaCaptura:    DateTime.now(),
          latitud:         _latitud,
          longitud:        _longitud,
        ),
      );
      saved = true;
    } catch (_) {}

    if (!mounted) return;

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No se pudo guardar el registro. Intenta de nuevo.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    _syncToMl();
    // Fire-and-forget: empuja lo pendiente (esta consulta y cualquier otra
    // cosa en el outbox) a MS1/MS2. Si falla, ya quedó en SQLite y se
    // reintenta en el próximo trigger.
    sl<SyncService>().syncAll().catchError((_) => const SyncResumen());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Consulta guardada',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // Fire-and-forget: manda el texto al MS de ML para reprocesarlo con NER + Isolation Forest.
  // Si no hay red o el MS está apagado, falla silenciosamente (el registro ya quedó en SQLite).
  void _syncToMl() {
    Connectivity().checkConnectivity().then((results) async {
      if (results.any((r) => r != ConnectivityResult.none)) {
        try {
          await sl<Dio>().post(
            '$kBaseUrlML/consulta-completa',
            data: {'texto': widget.originalText},
          );
        } catch (_) {}
      }
    }).catchError((_) {});
  }

  void _showErrorSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 16),
                  _buildPatientCard(),
                  const SizedBox(height: 14),
                  _buildClinicalCard(),
                  const SizedBox(height: 14),
                  _buildVitalsCard(),
                  const SizedBox(height: 14),
                  _buildConsultaCard(),
                  const SizedBox(height: 14),
                  _buildLocationCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.monitor_heart_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'EpiSurveillance',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'HW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Page header ───────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmación de Datos (IA)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Transcripción completada con éxito',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Card: Perfil del Paciente ─────────────────────────────────────────────

  Widget _buildPatientCard() {
    return _Card(
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Perfil del Paciente',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleEdit,
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isEditing ? 'Listo' : 'Editar',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Nombre Completo',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          widget.pacienteNombre,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        _buildField('Edad', _ageController, isDetected: _detected('edad')),
        const SizedBox(height: 12),
        _buildField('Género', _genderController, isDetected: _detected('sexo')),
      ],
    );
  }

  // ── Card: Análisis Clínico (IA) ───────────────────────────────────────────

  Widget _buildClinicalCard() {
    final detectedCount = widget.clinicalFields.length;
    return _Card(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.biotech_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Análisis Clínico (IA)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$detectedCount / 11\ncampos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Categoría de Síntoma',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        _isEditing
            ? _buildField('Categoría', _categoryController, isDetected: _detected('categoria_sintoma'))
            : _detected('categoria_sintoma')
                ? _CategoryChip(label: _categoryController.text)
                : const _UndetectedRow(label: 'Categoría no detectada'),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.thermostat_rounded, color: AppColors.primary, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temperatura (°C)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  _isEditing
                      ? _buildInlineField(_tempController)
                      : _detected('temperatura_c')
                          ? Text(
                              '${_tempController.text} °C',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : const _UndetectedRow(label: 'No detectada'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duración síntomas (días)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  _isEditing
                      ? _buildInlineField(_durationController)
                      : _detected('duracion_sintomas_dias')
                          ? Text(
                              '${_durationController.text} días',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : const _UndetectedRow(label: 'No detectada'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_outlined, color: AppColors.textMuted, size: 17),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Sincronización',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                SizedBox(height: 3),
                Text(
                  'Listo para envío local',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Card: Datos Clínicos Vitales ──────────────────────────────────────────

  Widget _buildVitalsCard() {
    return _Card(
      children: [
        const Row(
          children: [
            Icon(Icons.monitor_heart_outlined, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Datos Clínicos Vitales',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField('Peso (kg)', _weightController,
                  isDetected: _detected('peso_kg')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField('Talla (cm)', _heightController,
                  isDetected: _detected('talla_cm')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField('Presión Sistólica', _systolicController,
                  isDetected: _detected('presion_sistolica')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField('Presión Diastólica', _diastolicController,
                  isDetected: _detected('presion_diastolica')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField('Glucosa (mg/dL)', _glucoseController,
                  isDetected: _detected('glucosa_mg_dl')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField('Frec. Cardíaca (bpm)', _heartRateController,
                  isDetected: _detected('frecuencia_cardiaca_bpm')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildField('Saturación de Oxígeno (%)', _saturacionController,
            isDetected: false, alwaysEditable: true),
      ],
    );
  }

  // ── Card: Datos de la Consulta (manual, no lo extrae el BiLSTM) ──────────

  Widget _buildConsultaCard() {
    return _Card(
      children: [
        const Row(
          children: [
            Icon(Icons.assignment_outlined, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Datos de la Consulta',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildField('Motivo de Consulta', _motivoController, isDetected: false, alwaysEditable: true),
        const SizedBox(height: 12),
        _buildField('Diagnóstico', _diagnosticoController, isDetected: false, alwaysEditable: true),
        const SizedBox(height: 16),
        _buildMedicamentosSection(),
      ],
    );
  }

  Widget _buildMedicamentosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Medicamentos',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showAgregarMedicamentoDialog,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Agregar', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        if (_medicamentos.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: _UndetectedRow(label: 'Sin medicamentos agregados'),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: _medicamentos.asMap().entries.map((entry) {
                final m = entry.value;
                final partes = [
                  if (m.dosis != null && m.dosis!.isNotEmpty) m.dosis!,
                  if (m.frecuencia != null && m.frecuencia!.isNotEmpty) m.frecuencia!,
                  if (m.duracion != null && m.duracion!.isNotEmpty) m.duracion!,
                ].join(' · ');
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            if (partes.isNotEmpty)
                              Text(partes, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _medicamentos.removeAt(entry.key)),
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Future<void> _showAgregarMedicamentoDialog() async {
    final nombreCtrl = TextEditingController();
    final dosisCtrl = TextEditingController();
    final frecuenciaCtrl = TextEditingController();
    final duracionCtrl = TextEditingController();

    final agregado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar medicamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: dosisCtrl, decoration: const InputDecoration(labelText: 'Dosis')),
            TextField(controller: frecuenciaCtrl, decoration: const InputDecoration(labelText: 'Frecuencia')),
            TextField(controller: duracionCtrl, decoration: const InputDecoration(labelText: 'Duración')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(nombreCtrl.text.trim().isNotEmpty),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (agregado == true && mounted) {
      setState(() {
        _medicamentos.add(Medicamento(
          nombre: nombreCtrl.text.trim(),
          dosis: dosisCtrl.text.trim().isEmpty ? null : dosisCtrl.text.trim(),
          frecuencia: frecuenciaCtrl.text.trim().isEmpty ? null : frecuenciaCtrl.text.trim(),
          duracion: duracionCtrl.text.trim().isEmpty ? null : duracionCtrl.text.trim(),
        ));
      });
    }
  }

  // ── Card: Ubicación + mini mapa ───────────────────────────────────────────

  Widget _buildLocationCard() {
    return _Card(
      children: [
        const Row(
          children: [
            Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Ubicación de la Consulta',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildField('Municipio', _municipioController, isDetected: false, alwaysEditable: true),
        const SizedBox(height: 12),
        _buildField('Comunidad', _comunidadController, isDetected: false, alwaysEditable: true),
        const SizedBox(height: 6),
        _buildGpsRow(),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 110,
            width: double.infinity,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _MiniMapPainter(),
                ),
                Positioned(
                  bottom: 6,
                  left: 8,
                  child: Text(
                    _latitud != null
                        ? 'GPS: ${_latitud!.toStringAsFixed(4)}, ${_longitud!.toStringAsFixed(4)}'
                        : 'GPS: buscando...',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _saveAndSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text(
              'Guardar y Sincronizar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _toggleEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              _isEditing ? Icons.check_circle_outline_rounded : Icons.edit_outlined,
              size: 18,
            ),
            label: Text(
              _isEditing ? 'Confirmar Cambios' : 'Editar Manualmente',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.mic_none_rounded, size: 18),
            label: const Text(
              'Grabar de Nuevo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildField(String label, TextEditingController controller,
      {bool isDetected = true, bool alwaysEditable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        (alwaysEditable || _isEditing)
            ? TextFormField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              )
            : isDetected
                ? Text(
                    controller.text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  )
                : const _UndetectedRow(),
      ],
    );
  }

  // Variante compacta para campos dentro de filas (temperatura, duración).
  Widget _buildInlineField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ── Reusable card ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ── "No detectado" row ────────────────────────────────────────────────────────

class _UndetectedRow extends StatelessWidget {
  final String label;
  const _UndetectedRow({this.label = 'No detectado'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.help_outline, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini map painter ──────────────────────────────────────────────────────────

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D1B2A),
    );

    final streetPaint = Paint()
      ..color = const Color(0xFF1B6E52).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final mainStreetPaint = Paint()
      ..color = const Color(0xFF1B6E52).withValues(alpha: 0.8)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final hLines = [0.18, 0.38, 0.55, 0.72, 0.88];
    for (final t in hLines) {
      canvas.drawLine(
        Offset(0, size.height * t),
        Offset(size.width, size.height * t),
        t == 0.38 || t == 0.72 ? mainStreetPaint : streetPaint,
      );
    }

    final vLines = [0.12, 0.28, 0.44, 0.6, 0.76, 0.9];
    for (final t in vLines) {
      canvas.drawLine(
        Offset(size.width * t, 0),
        Offset(size.width * t, size.height),
        t == 0.28 || t == 0.6 ? mainStreetPaint : streetPaint,
      );
    }

    final dotX = size.width * 0.5;
    final dotY = size.height * 0.45;

    canvas.drawCircle(
      Offset(dotX, dotY),
      14,
      Paint()..color = AppColors.primary.withValues(alpha: 0.18),
    );
    canvas.drawCircle(Offset(dotX, dotY), 5, Paint()..color = AppColors.primary);
    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
