import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../anomalies/presentation/pages/anomalies_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../map/presentation/pages/mapa_page.dart';
import '../../../patients/data/models/paciente.dart';
import '../../../patients/data/repositories/patient_local_repository.dart';
import '../../../patients/presentation/pages/paciente_detalle_page.dart';
import '../../../patients/presentation/widgets/add_case_choice_sheet.dart';
import '../../../plans/presentation/pages/planes_page.dart';
import '../../../services/presentation/pages/servicios_page.dart';

class CasosPage extends StatefulWidget {
  CasosPage({super.key});

  @override
  State<CasosPage> createState() => _CasosPageState();
}

class _CasosPageState extends State<CasosPage> {
  int _currentNavIndex = 1; // Casos siempre es índice 1 en todas las variantes de tabs
  final _searchController = TextEditingController();

  List<PacienteConResumen> _pacientes = [];
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPacientes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 300), _loadPacientes);
  }

  Future<void> _loadPacientes() async {
    final filtro = _searchController.text.trim();
    final lista = await sl<PatientLocalRepository>()
        .getPacientes(filtro.isEmpty ? null : filtro);
    if (mounted) {
      setState(() {
        _pacientes = lista;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSyncBanner(),
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      leading: IconButton(
        icon: Icon(Icons.account_circle_outlined,
            color: AppColors.of(context).textPrimary, size: 26),
        onPressed: () {
          context.read<AuthProvider>().resetStatus();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        },
      ),
      title: Text(
        'Listado de Pacientes',
        style: TextStyle(
          color: AppColors.of(context).textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.sync_rounded, color: AppColors.of(context).primary, size: 24),
          onPressed: _loadPacientes,
        ),
      ],
    );
  }

  // ── Sync banner ───────────────────────────────────────────────────────────

  Widget _buildSyncBanner() {
    return Container(
      color: Color(0xFF1B6E52),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Icon(Icons.cloud_done_outlined, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Visualizando datos locales — Sincronizado hace 2 min',
              style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.of(context).surface,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre',
                  hintStyle: TextStyle(color: AppColors.of(context).textMuted, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.of(context).textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_pacientes.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadPacientes,
      color: AppColors.of(context).primary,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _pacientes.length,
        separatorBuilder: (_, __) => SizedBox(height: 10),
        itemBuilder: (_, i) => _buildPacienteCard(_pacientes[i]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 56, color: AppColors.of(context).textMuted.withValues(alpha: 0.5)),
            SizedBox(height: 16),
            Text(
              'No hay pacientes registrados aún.\nUsa el micrófono para registrar la primera consulta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.of(context).textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Paciente card ─────────────────────────────────────────────────────────

  Widget _buildPacienteCard(PacienteConResumen r) {
    final p      = r.paciente;
    final semana = r.visitasEstaSemana;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PacienteDetallePage(paciente: r)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.1),
                    child: Text(
                      _initials(p.nombreCompleto),
                      style: TextStyle(
                        color: AppColors.of(context).primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombreCompleto,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                        if (p.comunidad != null && p.comunidad!.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            p.comunidad!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.of(context).textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: AppColors.of(context).textMuted, size: 20),
                ],
              ),
              SizedBox(height: 10),
              Text(
                '${p.totalVisitas} visita${p.totalVisitas == 1 ? '' : 's'} en total · '
                'última vez: ${_formatDate(p.ultimaVisita)}',
                style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted),
              ),
              if (semana >= 3 || semana > 1) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (semana >= 3)
                      _Badge(
                        label: '⚠ Revisión frecuente',
                        bg: Color(0xFFFFE4E4),
                        fg: Color(0xFFDC2626),
                      ),
                    if (semana > 1)
                      _Badge(
                        label: '$semana visitas esta semana',
                        bg: Color(0xFFFEF3C7),
                        fg: Color(0xFFD97706),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  /// Construye la lista de tabs según el rol del usuario.
  /// Tab índice 1 ("Casos") siempre tiene navigate == null → página actual.
  List<_TabItem> _buildTabs(UserRole role) {
    final nav = Navigator.of(context);

    final dashboard = _TabItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Inicio',
      navigate: () => nav.popUntil((r) => r.isFirst),
    );
    final casos = _TabItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
      label: 'Casos',
      navigate: null, // página actual
    );
    final nuevo = _TabItem(
      icon: Icons.person_add_outlined,
      activeIcon: Icons.person_add,
      label: 'Nuevo',
      // No navega a otra página (solo abre un sheet encima), así que al
      // cerrarlo hay que devolver el resaltado del tab a "Casos".
      navigate: () async {
        await showAddCaseChoiceSheet(context);
        if (mounted) setState(() => _currentNavIndex = 1);
      },
    );
    final anomalias = _TabItem(
      icon: Icons.warning_amber_outlined,
      activeIcon: Icons.warning_amber_rounded,
      label: 'Anomalías',
      navigate: () => nav.pushReplacement(
        MaterialPageRoute(builder: (_) => AnomaliesPage()),
      ),
    );
    final mapa = _TabItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
      label: 'Mapa',
      navigate: () => nav.push(
        MaterialPageRoute(builder: (_) => MapaPage()),
      ),
    );
    final servicios = _TabItem(
      icon: Icons.medical_services_outlined,
      activeIcon: Icons.medical_services,
      label: 'Servicios',
      navigate: () => nav.push(
        MaterialPageRoute(builder: (_) => ServiciosPage()),
      ),
    );
    final planes = _TabItem(
      icon: Icons.star_outline_rounded,
      activeIcon: Icons.star_rounded,
      label: 'Planes',
      navigate: () => nav.push(
        MaterialPageRoute(builder: (_) => PlanesPage()),
      ),
    );

    return switch (role) {
      UserRole.usuario   => [dashboard, casos, nuevo, servicios, planes],
      UserRole.enfermera => [dashboard, casos, nuevo, anomalias, servicios, planes],
      UserRole.medico    => [dashboard, casos, nuevo, anomalias, mapa, servicios],
    };
  }

  Widget _buildBottomNav() {
    final role = context.read<AuthProvider>().currentRole;
    final tabs = _buildTabs(role);

    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) {
        setState(() => _currentNavIndex = i); // resalta el tab tocado
        tabs[i].navigate?.call();             // navega si no es la página actual
      },
      selectedItemColor: AppColors.of(context).primary,
      unselectedItemColor: AppColors.of(context).textMuted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      elevation: 10,
      items: tabs
          .map((t) => BottomNavigationBarItem(
                icon: Icon(t.icon),
                activeIcon: Icon(t.activeIcon),
                label: t.label,
              ))
          .toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }
}

// ── TabItem ───────────────────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback? navigate;

  _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.navigate,
  });
}

// ── Badge ─────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
