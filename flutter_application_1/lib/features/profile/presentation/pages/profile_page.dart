import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/token_storage.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../plans/presentation/pages/planes_page.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _correo;

  @override
  void initState() {
    super.initState();
    di.sl<TokenStorage>().getCorreo().then((v) {
      if (mounted) setState(() => _correo = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final initial =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: BackButton(color: AppColors.of(context).textPrimary),
        title: Text(
          'Mi perfil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.of(context).primary,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  user.name.isNotEmpty ? user.name : 'Usuario',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                if (_correo != null && _correo!.isNotEmpty)
                  Text(
                    _correo!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                SizedBox(height: 18),
                _PlanChip(role: user.role),
                SizedBox(height: 24),
                if (user.role != 'medico')
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => PlanesPage()),
                    ),
                    icon: Icon(Icons.stars_outlined, size: 18),
                    label: Text('Ver planes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.of(context).primary,
                      side: BorderSide(color: AppColors.of(context).primary),
                      padding: EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                    ),
                  ),
                Divider(height: 48),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.logout, color: AppColors.of(context).error),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: AppColors.of(context).error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cerrar sesión'),
        content: Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String role;
  _PlanChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'enfermera' => ('Plan Intermedio', AppColors.of(context).success),
      'medico'    => ('Plan Premium', Color(0xFF0D9488)),
      'admin'     => ('Administrador', Color(0xFFF97316)),
      _           => ('Plan Free', AppColors.of(context).textSecondary),
    };

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, size: 14, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
