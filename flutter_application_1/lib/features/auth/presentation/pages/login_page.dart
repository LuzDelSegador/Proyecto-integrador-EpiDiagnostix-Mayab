import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'register_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberSession = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.select<AuthProvider, AuthStatus>(
      (p) => p.status,
    );

    if (authStatus == AuthStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardPage()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).statusBarBackground,
        elevation: 0,
        title: Text(
          'Inicio de Sesión - Personal de Salud',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            _buildLogo(),
            SizedBox(height: 28),
            _buildFormCard(authStatus),
            SizedBox(height: 16),
            _buildInfoBox(),
            SizedBox(height: 28),
            _buildFooter(),
            SizedBox(height: 20),
            _buildRegisterLink(context),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Logo ────────────────────────────────────────────────────────────────────

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/app_icon_mark.png',
          width: 96,
          height: 96,
        ),
        SizedBox(height: 14),
        Text(
          'EpiDiagnostix-Mayab',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Portal de Vigilancia Epidemiológica',
          style: TextStyle(fontSize: 13, color: AppColors.of(context).textSecondary),
        ),
      ],
    );
  }

  // ── Form Card ───────────────────────────────────────────────────────────────

  Widget _buildFormCard(AuthStatus authStatus) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inicio de Sesión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ingrese sus credenciales autorizadas',
              style: TextStyle(fontSize: 13, color: AppColors.of(context).textSecondary),
            ),
            SizedBox(height: 24),
            _buildErrorBanner(authStatus),
            _buildFieldLabel('Identificación de Personal / Correo'),
            SizedBox(height: 6),
            TextFormField(
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                hint: 'Ej. HW-99234 o nombre@salud.gob',
                icon: Icons.badge_outlined,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingrese su identificación o correo'
                  : null,
            ),
            SizedBox(height: 16),
            _buildFieldLabel('Contraseña'),
            SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _inputDecoration(
                hint: '••••••••',
                icon: Icons.lock_outline,
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
                  (v == null || v.isEmpty) ? 'Ingrese su contraseña' : null,
            ),
            SizedBox(height: 16),
            _buildRememberRow(),
            SizedBox(height: 24),
            _buildSubmitButton(authStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildRememberRow() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _rememberSession,
            onChanged: (v) => setState(() => _rememberSession = v ?? false),
            activeColor: AppColors.of(context).primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Recordar sesión',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            '¿Olvidó su contraseña?',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.of(context).primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(AuthStatus authStatus) {
    if (authStatus != AuthStatus.error) return SizedBox.shrink();

    final errorMessage = context.select<AuthProvider, String?>(
      (p) => p.errorMessage,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.of(context).errorBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.of(context).errorBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.of(context).error, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                errorMessage ?? 'Error al iniciar sesión.',
                style: TextStyle(color: AppColors.of(context).error, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AuthStatus authStatus) {
    final isLoading = authStatus == AuthStatus.loading;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.of(context).primary,
          disabledBackgroundColor: AppColors.of(context).primary.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Acceder al Sistema',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  // ── Info Box ────────────────────────────────────────────────────────────────

  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).infoBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.of(context).infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.of(context).info, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este sistema está optimizado para uso offline. Puede iniciar sesión sin conexión si ya ha validado su dispositivo previamente.',
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterLink('Ayuda Técnica'),
        _FooterDot(),
        _FooterLink('Privacidad de Datos'),
        Text(
          '  v2.4.0',
          style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RegisterPage()),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: AppColors.of(context).textMuted),
          children: [
            TextSpan(text: '¿No tienes cuenta?  '),
            TextSpan(
              text: 'Registrarse',
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

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
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

// ── Footer Widgets ─────────────────────────────────────────────────────────────

class _FooterLink extends StatelessWidget {
  final String label;
  _FooterLink(this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: TextStyle(color: AppColors.of(context).textSecondary, fontSize: 12),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  _FooterDot();

  @override
  Widget build(BuildContext context) {
    return Text(
      '  •  ',
      style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 12),
    );
  }
}
