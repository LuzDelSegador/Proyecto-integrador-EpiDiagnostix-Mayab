import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'audio_confirmation_page.dart';
import 'audio_transcription_page.dart';

/// Punto de entrada tras identificar/crear al paciente (ver
/// PatientRegistrationPage): ofrece cómo capturar la consulta para ESE
/// paciente ya conocido (pacienteId es el id local en SQLite).
class NewPatientSelectionPage extends StatelessWidget {
  final String pacienteId;
  final String pacienteNombre;

  const NewPatientSelectionPage({
    super.key,
    required this.pacienteId,
    required this.pacienteNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Barra superior oscura (consistente con la página de login)
      appBar: AppBar(
        backgroundColor: AppColors.statusBarBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Selección de Entrada de Datos',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSecondaryHeader(context),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMethodHeader(),
                  const SizedBox(height: 24),
                  _buildWriteCard(context),
                  const SizedBox(height: 16),
                  _buildAudioCard(context),
                  const SizedBox(height: 20),
                  _buildRecommendationBox(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Secondary header: X | Nuevo Paciente | cloud ─────────────────────────

  Widget _buildSecondaryHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              pacienteNombre,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(
            Icons.cloud_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ── Method header ─────────────────────────────────────────────────────────

  Widget _buildMethodHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Entrada',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Seleccione cómo desea capturar los datos epidemiológicos de esta consulta.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  // ── Option Card 1: Escribir ───────────────────────────────────────────────

  Widget _buildWriteCard(BuildContext context) {
    return _OptionCard(
      iconData: Icons.keyboard_rounded,
      iconBackgroundColor: AppColors.primary,
      title: 'Escribir datos del paciente',
      description:
          'Formulario manual estructurado para una precisión clínica detallada.',
      linkLabel: 'Empezar ahora',
      linkTrailing: const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AudioConfirmationPage(
            pacienteId: pacienteId,
            pacienteNombre: pacienteNombre,
            clinicalFields: const {},
            originalText: '',
          ),
        ),
      ),
    );
  }

  // ── Option Card 2: Audio ──────────────────────────────────────────────────

  Widget _buildAudioCard(BuildContext context) {
    return _OptionCard(
      iconData: Icons.mic_rounded,
      iconBackgroundColor: const Color(0xFF0EA5E9),
      title: 'Transcribir con audio',
      description:
          'Captura rápida mediante voz. Ideal para triaje en entornos de alta presión.',
      linkLabel: 'Iniciar grabación',
      linkTrailing: const Icon(Icons.graphic_eq, size: 18, color: AppColors.primary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AudioTranscriptionPage(
            pacienteId: pacienteId,
            pacienteNombre: pacienteNombre,
          ),
        ),
      ),
    );
  }

  // ── Recommendation box ────────────────────────────────────────────────────

  Widget _buildRecommendationBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 17),
              const SizedBox(width: 8),
              Text(
                'RECOMENDACIÓN',
                style: TextStyle(
                  color: AppColors.info.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'La transcripción por audio se recomienda para entrevistas iniciales. Los datos se sincronizarán automáticamente cuando recupere la conexión.',
            style: TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.success, size: 15),
              SizedBox(width: 5),
              Text(
                'Modo Offline: Activo',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Text(
            'Versión v2.4.0-offline',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Option Card Widget ─────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final IconData iconData;
  final Color iconBackgroundColor;
  final String title;
  final String description;
  final String linkLabel;
  final Widget linkTrailing;
  final VoidCallback onTap;

  const _OptionCard({
    required this.iconData,
    required this.iconBackgroundColor,
    required this.title,
    required this.description,
    required this.linkLabel,
    required this.linkTrailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon container
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          // Divider
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 14),
          // Link row
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  linkLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                linkTrailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
