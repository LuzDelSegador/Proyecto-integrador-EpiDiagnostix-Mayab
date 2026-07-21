import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../cases/presentation/pages/casos_page.dart';
import '../../data/plan_service.dart';

class CedulaSolicitudPage extends StatefulWidget {
  CedulaSolicitudPage({super.key});

  @override
  State<CedulaSolicitudPage> createState() => _CedulaSolicitudPageState();
}

class _CedulaSolicitudPageState extends State<CedulaSolicitudPage> {
  final _formKey = GlobalKey<FormState>();
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  final _especialidadController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _cedulaController.dispose();
    _nombreController.dispose();
    _especialidadController.dispose();
    super.dispose();
  }

  Future<void> _handleEnviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await di.sl<PlanService>().solicitarPremium(
        numeroCedula: _cedulaController.text.trim(),
        nombreEnCedula: _nombreController.text.trim(),
        especialidad: _especialidadController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccess(result);
    } on SolicitudDuplicadaException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showDuplicada();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión. Verifica tu red e intenta nuevamente.'),
          backgroundColor: AppColors.of(context).error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccess(SolicitudResult result) {
    final nav = Navigator.of(context);
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SuccessSheet(
        onEntendido: () {
          nav.pop(); // cierra el sheet
          nav.pushReplacement(
            MaterialPageRoute(builder: (_) => CasosPage()),
          );
        },
      ),
    );
  }

  void _showDuplicada() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DuplicadaSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.of(context).textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verificación de Cédula',
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            SizedBox(height: 28),
            _buildFormCard(),
            SizedBox(height: 20),
            _buildSubmitButton(),
            SizedBox(height: 16),
            _buildLegalNote(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.of(context).primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.verified_user_rounded,
            color: AppColors.of(context).primary,
            size: 34,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Verificación Profesional',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Ingresa los datos de tu cédula profesional. El equipo de EpiDiagnostix la verificará en menos de 48 horas hábiles.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.of(context).textSecondary,
            height: 1.55,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Número de Cédula Profesional'),
            SizedBox(height: 6),
            TextFormField(
              controller: _cedulaController,
              keyboardType: TextInputType.number,
              decoration: _inputDeco(
                hint: 'Ej: 12345678',
                icon: Icons.badge_outlined,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese el número de cédula';
                if (v.trim().length < 6) return 'La cédula debe tener al menos 6 dígitos';
                return null;
              },
            ),
            SizedBox(height: 16),
            _label('Nombre Completo (tal como aparece en la cédula)'),
            SizedBox(height: 6),
            TextFormField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDeco(
                hint: 'Ej: María García López',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese el nombre de la cédula';
                if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            SizedBox(height: 16),
            _label('Especialidad médica (opcional)'),
            SizedBox(height: 6),
            TextFormField(
              controller: _especialidadController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco(
                hint: 'Ej: Medicina Interna, Epidemiología',
                icon: Icons.local_hospital_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.of(context).inputBackground,
      prefixIcon: Icon(icon, color: AppColors.of(context).textMuted, size: 20),
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.of(context).textMuted, fontSize: 13),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: BorderSide(color: AppColors.of(context).primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.of(context).error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.of(context).error, width: 1.5),
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleEnviar,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.of(context).primary,
          disabledBackgroundColor: AppColors.of(context).primary.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Icon(Icons.send_rounded, size: 20),
        label: Text(
          _isLoading ? 'Enviando solicitud...' : 'Enviar solicitud',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLegalNote() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).infoBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.of(context).infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.of(context).info, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Al enviar, aceptas que verificaremos tu cédula profesional a través del registro oficial de la SEP. Tu cuenta permanecerá en el plan actual hasta que la verificación sea aprobada.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.of(context).info,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BottomSheet: Éxito ────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final VoidCallback onEntendido;
  _SuccessSheet({required this.onEntendido});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.of(context).success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.of(context).success,
              size: 38,
            ),
          ),
          SizedBox(height: 18),
          Text(
            '¡Solicitud enviada!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Verificaremos tu cédula en menos de 48 horas hábiles. Te notificaremos cuando tu cuenta Premium esté activa.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.of(context).textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onEntendido,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.of(context).primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Entendido',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BottomSheet: Solicitud duplicada ─────────────────────────────────────────

class _DuplicadaSheet extends StatelessWidget {
  _DuplicadaSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFFD97706),
              size: 34,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Solicitud en proceso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Ya tienes una solicitud en proceso. Te contactaremos pronto para confirmar la activación de tu cuenta Premium.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.of(context).textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Entendido',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
