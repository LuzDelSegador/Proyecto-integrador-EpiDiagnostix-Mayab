import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'audio_confirmation_page.dart';

class AudioTranscriptionPage extends StatefulWidget {
  const AudioTranscriptionPage({super.key});

  @override
  State<AudioTranscriptionPage> createState() => _AudioTranscriptionPageState();
}

class _AudioTranscriptionPageState extends State<AudioTranscriptionPage> {
  bool _isRecording = false;

  void _toggleRecording() {
    if (_isRecording) {
      // Detener grabación → navegar a confirmación
      setState(() => _isRecording = false);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AudioConfirmationPage()),
      );
    } else {
      // Iniciar grabación
      setState(() => _isRecording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: AppColors.statusBarBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  _buildTranscriptionCard(),
                  const SizedBox(height: 12),
                  _buildAudioControls(),
                  const SizedBox(height: 12),
                  _buildMicCard(),
                  const SizedBox(height: 12),
                  _buildGuideCard(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Secondary header ──────────────────────────────────────────────────────

  Widget _buildSecondaryHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'EpiSurveillance',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const Icon(Icons.cloud_outlined, color: AppColors.textSecondary, size: 22),
        ],
      ),
    );
  }

  // ── Sync bar ──────────────────────────────────────────────────────────────

  Widget _buildSyncBar() {
    return Container(
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.sync_rounded, color: AppColors.info, size: 15),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sincronización en curso - Modo Offline activo',
              style: TextStyle(color: AppColors.info, fontSize: 11),
            ),
          ),
          const Text(
            'v2.4.0',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Transcription card ────────────────────────────────────────────────────

  Widget _buildTranscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
        children: [
          const Text(
            'Transcripción en Tiempo Real',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 44),
          Center(
            child: _isRecording
                ? Column(
                    children: [
                      const Icon(
                        Icons.graphic_eq_rounded,
                        size: 60,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Escuchando al paciente...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.hearing_rounded,
                        size: 60,
                        color: AppColors.textMuted.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Inicia la grabación para comenzar la\ntranscripción del paciente...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 44),
        ],
      ),
    );
  }

  // ── Audio controls row ────────────────────────────────────────────────────

  Widget _buildAudioControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Calidad de audio',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              _buildAudioBars(),
            ],
          ),
          GestureDetector(
            onTap: () {},
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary, size: 15),
                SizedBox(width: 4),
                Text(
                  'Añadir nota\nmanual',
                  style: TextStyle(
                    color: AppColors.primary,
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
    const heights = [5.0, 9.0, 14.0, 9.0, 5.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights.map((h) {
        return Container(
          width: 4,
          height: h,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: _isRecording ? const Color(0xFFDC2626) : AppColors.success,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  // ── Mic card ──────────────────────────────────────────────────────────────

  Widget _buildMicCard() {
    final isRec = _isRecording;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
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
        children: [
          GestureDetector(
            onTap: _toggleRecording,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isRec ? const Color(0xFFDC2626) : AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (isRec ? const Color(0xFFDC2626) : AppColors.primary)
                        .withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isRec ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isRec
                ? 'Grabando...\nPresiona para detener'
                : 'Presiona y empieza a\nhablar con tu paciente',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isRec ? const Color(0xFFDC2626) : AppColors.textPrimary,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isRec
                ? 'El sistema está capturando y procesando\nel audio en tiempo real.'
                : 'El sistema filtrará el ruido ambiental y\ntranscribirá automáticamente los\nsíntomas detectados.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
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
        gradient: const LinearGradient(
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
                borderRadius: const BorderRadius.only(
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
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guia de Vigilancia\nEpidemiológica',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
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
