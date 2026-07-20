import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import 'admin_login_page.dart';
import 'sections/dashboard_section.dart';
import 'sections/solicitudes_section.dart';
import 'sections/usuarios_section.dart';
import 'sections/config_section.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _selectedIndex = 0;

  static const _sectionTitles = [
    'Dashboard',
    'Solicitudes Premium',
    'Usuarios',
    'Configuración',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadAdminName();
      admin.loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.select<AdminProvider, int>(
      (p) => p.stats?.solicitudesPendientes ?? 0,
    );

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(pendingCount),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      DashboardSection(
                        onGoToSolicitudes: () =>
                            setState(() => _selectedIndex = 1),
                      ),
                      const SolicitudesSection(),
                      const UsuariosSection(),
                      const ConfigSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(int pendingCount) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Brand header
          Container(
            height: 64,
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const Text(
              'EpiDiagnostix\nAdmin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          // Navigation items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                children: [
                  _NavItem(
                    label: 'Dashboard',
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard,
                    index: 0,
                    selectedIndex: _selectedIndex,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  _NavItem(
                    label: 'Solicitudes',
                    icon: Icons.assignment_outlined,
                    selectedIcon: Icons.assignment,
                    index: 1,
                    selectedIndex: _selectedIndex,
                    onTap: () => setState(() => _selectedIndex = 1),
                    badgeCount: pendingCount,
                  ),
                  _NavItem(
                    label: 'Usuarios',
                    icon: Icons.people_outline,
                    selectedIcon: Icons.people,
                    index: 2,
                    selectedIndex: _selectedIndex,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  _NavItem(
                    label: 'Configuración',
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    index: 3,
                    selectedIndex: _selectedIndex,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            _sectionTitles[_selectedIndex],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Selector<AdminProvider, String>(
            selector: (_, p) => p.adminName,
            builder: (_, name, __) => Row(
              children: [
                const Icon(Icons.account_circle_outlined,
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          OutlinedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              textStyle: const TextStyle(fontSize: 13),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await context.read<AdminProvider>().logout();
    if (!mounted) return;
    // Also reset AuthProvider state so the login page starts fresh.
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginPage()),
      (_) => false,
    );
  }
}

// ── Navigation Item ─────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;

    Widget iconWidget = Icon(
      selected ? selectedIcon : icon,
      size: 20,
      color: selected ? AppColors.primary : AppColors.textSecondary,
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          '$badgeCount',
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        child: iconWidget,
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                color:
                    selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
