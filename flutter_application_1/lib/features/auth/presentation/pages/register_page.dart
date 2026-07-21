import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorText = null; });

    final provider = context.read<AuthProvider>();
    await provider.register(
      nombre: _nameController.text.trim(),
      correo: _emailController.text.trim().toLowerCase(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (provider.status == AuthStatus.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardPage()),
      );
    } else {
      setState(() => _errorText = provider.errorMessage ?? 'Error al crear la cuenta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.of(context).textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Crear Cuenta',
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSyncBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  _buildLogo(),
                  SizedBox(height: 20),
                  _buildTitle(),
                  SizedBox(height: 28),
                  _buildFormCard(),
                  SizedBox(height: 16),
                  _buildRegisterButton(),
                  if (_errorText != null) ...[
                    SizedBox(height: 12),
                    _buildErrorBanner(),
                  ],
                  SizedBox(height: 20),
                  _buildLoginLink(context),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sync banner ───────────────────────────────────────────────────────────

  Widget _buildSyncBanner() {
    return Container(
      color: Color(0xFF0F4C35),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Registro disponible sin conexión. Los datos se sincronizarán al detectar red.',
              style: TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/app_icon_mark.png',
      width: 96,
      height: 96,
    );
  }

  // ── Title + subtitle ──────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Crear Cuenta de Personal\nde Salud',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).primary,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          'Únase a la red nacional de vigilancia epidemiológica para fortalecer la salud pública comunitaria.',
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

  // ── Form card ─────────────────────────────────────────────────────────────

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
            _buildFieldLabel('Nombre Completo'),
            SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration(
                hint: 'Ej: Dra. María García',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese su nombre completo';
                if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildFieldLabel('Correo Electrónico'),
            SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hint: 'usuario@salud.gob.es',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingrese su correo';
                final emailReg = RegExp(r'^[\w.%+-]+@[\w.-]+\.[a-zA-Z]{2,}$');
                if (!emailReg.hasMatch(v.trim())) return 'Formato de correo no válido';
                return null;
              },
            ),
            SizedBox(height: 16),
            _buildFieldLabel('Contraseña'),
            SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _inputDecoration(
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.of(context).textMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
            ),
            SizedBox(height: 16),
            _buildFieldLabel('Confirmar Contraseña'),
            SizedBox(height: 6),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: _inputDecoration(
                hint: '••••••••',
                icon: Icons.lock_reset_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.of(context).textMuted,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirme su contraseña';
                if (v != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            _buildTermsRow(),
          ],
        ),
      ),
    );
  }

  // ── Terms checkbox ────────────────────────────────────────────────────────

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
            activeColor: AppColors.of(context).primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).textSecondary,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'He leído y acepto los '),
                TextSpan(
                  text: 'Términos de Servicio',
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.of(context).primary,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                TextSpan(text: ' y la '),
                TextSpan(
                  text: 'Política de Privacidad',
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.of(context).primary,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {},
                ),
                TextSpan(
                  text:
                      ' sobre el manejo de datos clínicos sensibles y protección de identidad del paciente.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Register button ───────────────────────────────────────────────────────

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (_acceptTerms && !_isLoading) ? _handleRegister : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.of(context).primary,
          disabledBackgroundColor: AppColors.of(context).primary.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: Text(
          _isLoading ? 'Creando cuenta...' : 'Registrarse',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorText!,
              style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Login link ────────────────────────────────────────────────────────────

  Widget _buildLoginLink(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: AppColors.of(context).textMuted),
          children: [
            TextSpan(text: 'Ya tengo una cuenta.  '),
            TextSpan(
              text: 'Iniciar Sesión',
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ' →',
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
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
}
