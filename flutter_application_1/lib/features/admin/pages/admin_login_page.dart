import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'admin_shell_page.dart';

class AdminLoginPage extends StatefulWidget {
  AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _roleError;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _roleError = null);
    context.read<AuthProvider>().login(
          identifier: _correoController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authStatus =
        context.select<AuthProvider, AuthStatus>((p) => p.status);

    if (authStatus == AuthStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final auth = context.read<AuthProvider>();
        if (auth.currentUser.role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AdminShellPage()),
          );
        } else {
          await auth.logout();
          if (mounted) {
            setState(() =>
                _roleError = 'Esta área es exclusiva para administradores del sistema.');
          }
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: SizedBox(
            width: 400,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 28),
                      if (_roleError != null) _buildRoleError(),
                      if (authStatus == AuthStatus.error)
                        _buildAuthError(context),
                      _label('Correo electrónico'),
                      SizedBox(height: 6),
                      TextFormField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDeco(
                            hint: 'admin@epidiagnostix.mx',
                            icon: Icons.email_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Ingresa tu correo'
                            : null,
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                      SizedBox(height: 16),
                      _label('Contraseña'),
                      SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputDeco(
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
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),
                      SizedBox(height: 28),
                      _buildSubmitButton(authStatus),
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'EpiDiagnostix — Panel de Administración',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.of(context).textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.of(context).primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.admin_panel_settings,
              color: Colors.white, size: 26),
        ),
        SizedBox(height: 16),
        Text(
          'Acceso Administrativo',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Solo personal autorizado',
          style: TextStyle(fontSize: 13, color: AppColors.of(context).textSecondary),
        ),
      ],
    );
  }

  Widget _buildRoleError() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.block, color: AppColors.of(context).error, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(_roleError!,
                  style: TextStyle(
                      color: AppColors.of(context).error, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthError(BuildContext context) {
    final msg = context.select<AuthProvider, String?>(
        (p) => p.errorMessage);
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
              child: Text(msg ?? 'Credenciales incorrectas.',
                  style: TextStyle(
                      color: AppColors.of(context).error, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AuthStatus status) {
    final loading = status == AuthStatus.loading;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.of(context).primary,
          disabledBackgroundColor: AppColors.of(context).primary.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text('Ingresar al panel',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151)),
      );

  InputDecoration _inputDeco({required String hint, required IconData icon}) =>
      InputDecoration(
        filled: true,
        fillColor: AppColors.of(context).inputBackground,
        prefixIcon: Icon(icon, color: AppColors.of(context).textMuted, size: 20),
        hintText: hint,
        hintStyle:
            TextStyle(color: AppColors.of(context).textMuted, fontSize: 13),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.of(context).border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.of(context).border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.of(context).primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.of(context).error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: AppColors.of(context).error, width: 1.5)),
      );
}
