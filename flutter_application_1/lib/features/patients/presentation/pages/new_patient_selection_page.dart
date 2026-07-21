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

  NewPatientSelectionPage({
    super.key,
    required this.pacienteId,
    required this.pacienteNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      // Barra superior oscura (consistente con la página de login)
      appBar: AppBar(
        backgroundColor: AppColors.of(context).statusBarBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Selección de Entrada de Datos',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildSecondaryHeader(context),
          Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMethodHeader(context),
                  SizedBox(height: 24),
                  _buildWriteCard(context),
                  SizedBox(height: 16),
                  _buildAudioCard(context),
                  SizedBox(height: 20),
                  _buildRecommendationBox(context),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  // ── Secondary header: X | Nuevo Paciente | cloud ─────────────────────────

  Widget _buildSecondaryHeader(BuildContext context) {
    return Container(
      color: AppColors.of(context).surface,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close, color: AppColors.of(context).textPrimary, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              pacienteNombre,
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.cloud_outlined,
            color: AppColors.of(context).textSecondary,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ── Method header ─────────────────────────────────────────────────────────

  Widget _buildMethodHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Entrada',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Seleccione cómo desea capturar los datos epidemiológicos de esta consulta.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.of(context).textSecondary,
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
      iconBackgroundColor: AppColors.of(context).primary,
      title: 'Escribir datos del paciente',
      description:
          'Formulario manual estructurado para una precisión clínica detallada.',
      linkLabel: 'Empezar ahora',
      linkTrailing: Icon(Icons.arrow_forward, size: 16, color: AppColors.of(context).primary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AudioConfirmationPage(
            pacienteId: pacienteId,
            pacienteNombre: pacienteNombre,
            clinicalFields: {},
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
      iconBackgroundColor: Color(0xFF0EA5E9),
      title: 'Transcribir con audio',
      description:
          'Captura rápida mediante voz. Ideal para triaje en entornos de alta presión.',
      linkLabel: 'Iniciar grabación',
      linkTrailing: Icon(Icons.graphic_eq, size: 18, color: AppColors.of(context).primary),
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

  Widget _buildRecommendationBox(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).infoBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.of(context).info, size: 17),
              SizedBox(width: 8),
              Text(
                'RECOMENDACIÓN',
                style: TextStyle(
                  color: AppColors.of(context).info.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
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

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: AppColors.of(context).surface,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.of(context).success, size: 15),
              SizedBox(width: 5),
              Text(
                'Modo Offline: Activo',
                style: TextStyle(
                  color: AppColors.of(context).success,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            'Versión v2.4.0-offline',
            style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 11),
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

  _OptionCard({
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
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: Offset(0, 3),
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
          SizedBox(height: 16),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.of(context).textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 18),
          // Divider
          Divider(height: 1, color: Color(0xFFF3F4F6)),
          SizedBox(height: 14),
          // Link row
          GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  linkLabel,
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6),
                linkTrailing,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
