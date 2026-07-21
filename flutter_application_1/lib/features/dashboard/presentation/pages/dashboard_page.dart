import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../anomalies/presentation/pages/anomalies_page.dart';
import '../../../attentions/data/datasources/atencion_remote_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../cases/presentation/pages/casos_page.dart';
import '../../../map/presentation/pages/mapa_page.dart';
import '../../../patients/data/datasources/paciente_remote_datasource.dart';
import '../../../patients/data/repositories/patient_local_repository.dart';
import '../../../patients/presentation/widgets/add_case_choice_sheet.dart';
import '../../../services/presentation/pages/servicios_page.dart';
import '../../../sync/data/sync_service.dart';

class _PacienteReciente {
  final String nombre;
  final DateTime ultimaAtencion;
  final bool pendienteSync;

  const _PacienteReciente({
    required this.nombre,
    required this.ultimaAtencion,
    required this.pendienteSync,
  });
}

class DashboardPage extends StatefulWidget {
  DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentNavIndex = 0;
  bool _sincronizando = false;

  // ── Estadísticas reales (SQLite local, sin datos simulados) ────────────────
  SyncStats? _syncStats;
  int _nuevosCasos24h = 0;
  int _casosPeriodoPrevio = 0;
  bool _loadingStats = true;

  // ── Mis Pacientes ────────────────────────────────────────────────────────
  List<_PacienteReciente> _misPacientes = [];
  bool _loadingPacientes = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadMisPacientes();
  }

  Future<void> _loadMisPacientes() async {
    final personalId = context.read<AuthProvider>().currentUser.userId;
    List<_PacienteReciente> entries = [];

    try {
      final resultados = await Connectivity().checkConnectivity();
      final online = resultados.any((r) => r != ConnectivityResult.none);
      if (online && personalId.isNotEmpty) {
        entries = await _cargarPacientesRemoto(personalId);
      }
    } catch (_) {
      entries = [];
    }

    // Sin conexión, sin resultados remotos, o falló la llamada: se cae a lo
    // que ya está en SQLite (incluye pacientes sincronizados y pendientes).
    if (entries.isEmpty) {
      entries = await _cargarPacientesLocal();
    }

    entries.sort((a, b) => b.ultimaAtencion.compareTo(a.ultimaAtencion));
    if (!mounted) return;
    setState(() {
      _misPacientes = entries.take(5).toList();
      _loadingPacientes = false;
    });
  }

  /// GET /atenciones/personal/{id} solo trae paciente_id, no el nombre — se
  /// deduplica por paciente antes de resolver cada nombre con GET
  /// /pacientes/{id} en MS1, para no hacer una llamada por cada atención.
  Future<List<_PacienteReciente>> _cargarPacientesRemoto(String personalId) async {
    final atenciones = await sl<AtencionRemoteDataSource>().porPersonal(personalId);
    if (atenciones.isEmpty) return [];

    final ultimaPorPaciente = <String, DateTime>{};
    for (final a in atenciones) {
      final fecha = DateTime.tryParse(a.fechaAtencion) ?? DateTime.now();
      final actual = ultimaPorPaciente[a.pacienteId];
      if (actual == null || fecha.isAfter(actual)) {
        ultimaPorPaciente[a.pacienteId] = fecha;
      }
    }

    final entries = <_PacienteReciente>[];
    for (final entry in ultimaPorPaciente.entries) {
      try {
        final paciente = await sl<PacienteRemoteDataSource>().obtener(entry.key);
        entries.add(_PacienteReciente(
          nombre: paciente.nombreCompleto,
          ultimaAtencion: entry.value,
          pendienteSync: false,
        ));
      } catch (_) {
        // Un paciente individual no resoluble no debe tumbar toda la lista.
      }
    }
    return entries;
  }

  Future<List<_PacienteReciente>> _cargarPacientesLocal() async {
    final pacientes = await sl<PatientLocalRepository>().getPacientes(null);
    return pacientes
        .map((p) => _PacienteReciente(
              nombre: p.paciente.nombreCompleto,
              ultimaAtencion: p.paciente.ultimaVisita,
              pendienteSync: !p.paciente.sincronizado,
            ))
        .toList();
  }

  String _formatFechaRelativa(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _loadStats() async {
    final repo = sl<PatientLocalRepository>();
    final ahora = DateTime.now();
    final hace24h = ahora.subtract(Duration(hours: 24));
    final hace48h = ahora.subtract(Duration(hours: 48));

    final stats = await repo.getConsultasSyncStats();
    final nuevos = await repo.contarConsultasEntre(hace24h, ahora);
    final previo = await repo.contarConsultasEntre(hace48h, hace24h);
    if (!mounted) return;
    setState(() {
      _syncStats = stats;
      _nuevosCasos24h = nuevos;
      _casosPeriodoPrevio = previo;
      _loadingStats = false;
    });
  }

  Future<void> _sincronizarAhora() async {
    if (_sincronizando) return;
    setState(() => _sincronizando = true);
    final resumen = await sl<SyncService>().syncAll();
    if (!mounted) return;
    setState(() => _sincronizando = false);
    await _loadStats();
    if (!mounted) return;
    final mensaje = resumen.huboError
        ? 'No se pudo sincronizar (sin conexión o servidor dormido). Se reintentará.'
        : (resumen.pacientesSincronizados == 0 && resumen.atencionesSincronizadas == 0)
            ? 'Todo está sincronizado.'
            : 'Sincronizado: ${resumen.pacientesSincronizados} paciente(s), ${resumen.atencionesSincronizadas} consulta(s).';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            _buildOutbreaksCard(),
            SizedBox(height: 12),
            _buildSyncCard(),
            SizedBox(height: 12),
            _buildNewCasesCard(),
            SizedBox(height: 12),
            _buildMapCard(),
            SizedBox(height: 20),
            _buildRecentActivity(),
            SizedBox(height: 20),
            _buildMisPacientes(),
            SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddCaseChoiceSheet(context),
        backgroundColor: AppColors.of(context).primary,
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      leading: IconButton(
        icon: Icon(Icons.account_circle_outlined, color: AppColors.of(context).textPrimary, size: 26),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProfilePage()),
        ),
      ),
      title: Text(
        'EpiDiagnostix-Mayab',
        style: TextStyle(
          color: AppColors.of(context).primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Color(0xFF6EE7B7), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: AppColors.of(context).success, size: 7),
              SizedBox(width: 5),
              Text(
                'En línea',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: _sincronizando
              ? SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.of(context).textSecondary),
                )
              : Icon(Icons.cloud_outlined, color: AppColors.of(context).textSecondary, size: 22),
          onPressed: _sincronizando ? null : _sincronizarAhora,
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Panorama de Vigilancia',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
            height: 1.2,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Última actualización local: 09:42 AM',
          style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
        ),
      ],
    );
  }

  // ── Brotes Activos: sin agregación epidemiológica en el backend todavía ──────
  //
  // No existe (ni en MS1 ni en MS2) un endpoint que agregue diagnósticos por
  // enfermedad a nivel regional. Antes se mostraba un "12" fijo con chips de
  // Ébola/Cólera inventados — se reemplaza por un estado honesto en vez de
  // simular vigilancia poblacional que la app no puede respaldar hoy.

  Widget _buildOutbreaksCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.query_stats_rounded, color: AppColors.of(context).textMuted, size: 16),
              SizedBox(width: 6),
              Text(
                'BROTES ACTIVOS',
                style: TextStyle(
                  color: AppColors.of(context).textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'Sin datos suficientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'La agregación de brotes por enfermedad requiere un endpoint de vigilancia regional que el backend aún no expone.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.of(context).textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sync Progress Card ───────────────────────────────────────────────────────

  Widget _buildSyncCard() {
    final stats = _syncStats;
    final progreso = stats?.progreso ?? 0.0;
    final pct = (progreso * 100).round();
    final etiqueta = _loadingStats
        ? 'Calculando...'
        : '${stats?.sincronizadas ?? 0}/${stats?.total ?? 0} Casos Subidos';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso de Sincronización',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.sync, color: Colors.white.withValues(alpha: 0.85), size: 20),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _loadingStats ? '—' : '$pct%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _loadingStats ? 0.0 : progreso,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          SizedBox(height: 10),
          Text(
            etiqueta,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── New Cases Card ───────────────────────────────────────────────────────────

  Widget _buildNewCasesCard() {
    final diff = _nuevosCasos24h - _casosPeriodoPrevio;
    final subiendo = diff >= 0;
    final String comparacion;
    if (_loadingStats) {
      comparacion = 'Calculando...';
    } else if (_casosPeriodoPrevio == 0) {
      comparacion = _nuevosCasos24h == 0
          ? 'Sin casos en las últimas 24h'
          : '$_nuevosCasos24h nuevo(s) vs. 0 el período anterior';
    } else {
      final pct = ((diff / _casosPeriodoPrevio) * 100).round();
      comparacion = '${pct >= 0 ? '+' : ''}$pct% vs. período anterior';
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Casos Nuevos (24h)',
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                subiendo ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: AppColors.of(context).primary.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _loadingStats ? '—' : '+$_nuevosCasos24h',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
              height: 1,
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.of(context).successBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              comparacion,
              style: TextStyle(
                color: AppColors.of(context).success,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Card ─────────────────────────────────────────────────────────────────

  Widget _buildMapCard() {
    return Container(
      height: 175,
      decoration: BoxDecoration(
        color: Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Map visualization (painted)
          Positioned.fill(
            child: CustomPaint(painter: _MapPainter()),
          ),
          // Expand button
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.open_in_full,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          // District label
          Positioned(
            bottom: 12,
            left: 14,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Distrito 7 Centro Sur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mis Pacientes ────────────────────────────────────────────────────────────

  Widget _buildMisPacientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mis Pacientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CasosPage()),
              ),
              child: Text(
                'Ver Todos >',
                style: TextStyle(
                  color: AppColors.of(context).primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        if (_loadingPacientes)
          Container(
            padding: EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (_misPacientes.isEmpty)
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, color: AppColors.of(context).textMuted, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aún no has atendido pacientes. Los que registres aparecerán aquí.',
                    style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var i = 0; i < _misPacientes.length; i++) ...[
                  _buildPacienteRow(_misPacientes[i]),
                  if (i != _misPacientes.length - 1) _buildDivider(),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPacienteRow(_PacienteReciente p) {
    final inicial = p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.12),
            child: Text(
              inicial,
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
                  p.nombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Última atención: ${_formatFechaRelativa(p.ultimaAtencion)}',
                  style: TextStyle(fontSize: 11, color: AppColors.of(context).textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          if (p.pendienteSync)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_outlined, size: 13, color: AppColors.of(context).warning),
                SizedBox(width: 3),
                Text(
                  'Pendiente',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).warning,
                  ),
                ),
              ],
            )
          else
            Icon(Icons.check_circle_outline, size: 15, color: AppColors.of(context).success),
        ],
      ),
    );
  }

  // ── Recent Activity ──────────────────────────────────────────────────────────

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Ver Todo >',
                style: TextStyle(
                  color: AppColors.of(context).primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              _buildDivider(),
              _buildTableRow('CAS-992-01', 'Cólera\nSospechoso', 'Hace 2 min', _SyncStatus.synced),
              _buildDivider(),
              _buildTableRow('CAS-992-02', 'Dengue', 'Hace 15 min', _SyncStatus.pending),
              _buildDivider(),
              _buildTableRow('CAS-991-88', 'Meningitis', 'Hace 1 hora', _SyncStatus.synced),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('ID de Caso')),
          Expanded(flex: 3, child: _HeaderText('Enfermedad')),
          Expanded(flex: 3, child: _HeaderText('Última\nActualización')),
          Expanded(flex: 3, child: _HeaderText('Estado')),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6));

  Widget _buildTableRow(
    String caseId,
    String disease,
    String lastUpdated,
    _SyncStatus syncStatus,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              caseId,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              disease,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).textPrimary,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              lastUpdated,
              style: TextStyle(fontSize: 11, color: AppColors.of(context).textSecondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: _buildSyncBadge(syncStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBadge(_SyncStatus status) {
    final isSynced = status == _SyncStatus.synced;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSynced ? Icons.check_circle_outline : Icons.schedule_outlined,
          size: 14,
          color: isSynced ? AppColors.of(context).success : AppColors.of(context).warning,
        ),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            isSynced ? 'Sincronizado' : 'Pendiente',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isSynced ? AppColors.of(context).success : AppColors.of(context).warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Navigation ────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) {
        if (i == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AnomaliesPage()),
          );
        } else if (i == 2) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CasosPage()),
          );
        } else if (i == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MapaPage()),
          );
        } else if (i == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ServiciosPage()),
          );
        } else {
          setState(() => _currentNavIndex = i);
        }
      },
      selectedItemColor: AppColors.of(context).primary,
      unselectedItemColor: AppColors.of(context).textMuted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      elevation: 10,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning_amber_outlined),
          activeIcon: Icon(Icons.warning_amber_rounded),
          label: 'Anomalías',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          activeIcon: Icon(Icons.folder),
          label: 'Casos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map),
          label: 'Mapa',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services_outlined),
          activeIcon: Icon(Icons.medical_services),
          label: 'Servicios',
        ),
      ],
    );
  }
}

// ── Enums ────────────────────────────────────────────────────────────────────

enum _SyncStatus { synced, pending }

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _HeaderText extends StatelessWidget {
  final String text;
  _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: AppColors.of(context).textMuted,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

// ── Map Painter ───────────────────────────────────────────────────────────────

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.8;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Geographic region shapes
    final regionFill = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final regionStroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final regions = [
      _region(size, [0.08, 0.20, 0.30, 0.08, 0.55, 0.15, 0.58, 0.50, 0.28, 0.58, 0.06, 0.48]),
      _region(size, [0.58, 0.12, 0.92, 0.10, 0.96, 0.55, 0.68, 0.52, 0.56, 0.38]),
      _region(size, [0.22, 0.60, 0.56, 0.55, 0.64, 0.88, 0.30, 0.92, 0.10, 0.76]),
      _region(size, [0.68, 0.54, 0.94, 0.57, 0.90, 0.92, 0.60, 0.90]),
    ];

    for (final path in regions) {
      canvas.drawPath(path, regionFill);
      canvas.drawPath(path, regionStroke);
    }

    // Blue glow (hot zone)
    final center = Offset(size.width * 0.44, size.height * 0.44);
    final radius = size.width * 0.22;

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFF3B82F6).withValues(alpha: 0.75),
          Color(0xFF1D4ED8).withValues(alpha: 0.45),
          Color(0xFF1E40AF).withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, glowPaint);

    // Inner bright core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.35));

    canvas.drawCircle(center, radius * 0.35, corePaint);
  }

  Path _region(Size size, List<double> coords) {
    final path = Path();
    path.moveTo(size.width * coords[0], size.height * coords[1]);
    for (int i = 2; i < coords.length; i += 2) {
      path.lineTo(size.width * coords[i], size.height * coords[i + 1]);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
