import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/upgrade_required_widget.dart';
import '../../../anomalies/presentation/pages/anomalies_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cases/presentation/pages/casos_page.dart';
import '../../../patients/data/models/paciente.dart';
import '../../../patients/data/repositories/patient_local_repository.dart';
import '../../../plans/presentation/pages/planes_page.dart';
import '../../../services/presentation/pages/servicios_page.dart';

class MapaPage extends StatefulWidget {
  MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final int _currentNavIndex = 3;
  final MapController _mapController = MapController();

  String _selectedDisease = 'Influenza-A';
  String _selectedPeriod = 'Últimos 14 días';

  bool _cargando = true;
  List<ConsultaConUbicacion> _consultas = [];
  List<ResumenComunidad> _resumenComunidades = [];
  ConsultaConUbicacion? _seleccionada;

  // Centro por defecto: Tuxtla Gutiérrez, Chiapas — la zona real donde opera
  // el proyecto (antes apuntaba a Ciudad de Guatemala, dato simulado sin
  // relación con los datos capturados). Se recalcula al promedio de las
  // consultas reales con GPS en cuanto cargan, si hay alguna.
  static final _center = LatLng(16.7569, -93.1292);
  LatLng _centroActual = _center;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final repo = sl<PatientLocalRepository>();
    final resultados = await Future.wait([
      repo.getConsultasConUbicacion(),
      repo.getResumenPorComunidad(),
    ]);
    final consultas = resultados[0] as List<ConsultaConUbicacion>;
    final resumen = resultados[1] as List<ResumenComunidad>;
    if (!mounted) return;
    setState(() {
      _consultas = consultas;
      _resumenComunidades = resumen;
      _cargando = false;
    });
    if (consultas.isNotEmpty) {
      final lat = consultas.map((c) => c.latitud).reduce((a, b) => a + b) / consultas.length;
      final lng = consultas.map((c) => c.longitud).reduce((a, b) => a + b) / consultas.length;
      _centroActual = LatLng(lat, lng);
      _mapController.move(_centroActual, 12.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().currentRole;
    final bloqueado = !role.puedeVerMapa;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: _buildAppBar(),
      body: bloqueado
          ? UpgradeRequiredWidget(
              featureName: 'Mapa Epidemiológico',
              requiredPlan: 'Premium (Doctor)',
              description:
                  'Visualiza focos de infección, zonas de riesgo y análisis '
                  'espacial de brotes en tiempo real.',
              onVerPlanes: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PlanesPage()),
              ),
            )
          : Stack(
              children: [
                _buildMap(),
                _buildFilterRow(),
                _buildZoomControls(),
                if (_cargando) _buildLoadingBadge(),
                if (!_cargando && _consultas.isEmpty) _buildEmptyBanner(),
                if (_seleccionada != null) _buildInfoPanel(_seleccionada!),
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
        'EpiDiagnostix-Mayab',
        style: TextStyle(
          color: AppColors.of(context).primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Resumen por comunidad',
          icon: Icon(Icons.groups_outlined,
              color: AppColors.of(context).textSecondary, size: 22),
          onPressed: _showResumenComunidades,
        ),
        IconButton(
          icon: Icon(Icons.cloud_outlined,
              color: AppColors.of(context).textSecondary, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  // ── Map ───────────────────────────────────────────────────────────────────

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 13.0,
        maxZoom: 18,
        minZoom: 5,
        onTap: (_, __) => setState(() => _seleccionada = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.epidiagnostix.mayab.app',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: _consultas.map((c) {
            final esSeleccionada = _seleccionada?.id == c.id;
            final primary = AppColors.of(context).primary;
            return Marker(
              point: LatLng(c.latitud, c.longitud),
              width: 34,
              height: 34,
              child: GestureDetector(
                onTap: () => setState(() => _seleccionada = c),
                child: Container(
                  decoration: BoxDecoration(
                    color: esSeleccionada ? primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.medical_services_rounded,
                    size: 16,
                    color: esSeleccionada ? Colors.white : primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Loading / empty states ───────────────────────────────────────────────
  //
  // Nada de esto se mostraba antes: el mapa viejo siempre pintaba 5 "hotspots"
  // fijos sin importar si había datos reales o no. Aquí, sin consultas con
  // GPS capturado, se dice explícitamente en vez de simular actividad.

  Widget _buildLoadingBadge() {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.of(context).primary),
              ),
              SizedBox(width: 8),
              Text('Cargando consultas...', style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBanner() {
    return Positioned(
      top: 60,
      left: 12,
      right: 12,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.of(context).textMuted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aún no hay consultas con ubicación GPS registrada. Los marcadores aparecerán aquí en cuanto se capturen consultas con GPS activo.',
                style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Positioned(
      top: 12,
      left: 12,
      right: 72,
      child: Row(
        children: [
          Flexible(
            child: _buildChip(
              icon: Icons.coronavirus_outlined,
              label: 'ENFERMEDAD: $_selectedDisease',
              onTap: _showDiseaseSelector,
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: _buildChip(
              icon: Icons.date_range_rounded,
              label: _periodoCorto(_selectedPeriod),
              onTap: _showPeriodSelector,
            ),
          ),
        ],
      ),
    );
  }

  // Quita el prefijo redundante "Últimos " del label del chip (el selector
  // completo, con el texto entero, se sigue mostrando en _showPeriodSelector)
  // — evita truncar con "..." un texto corto donde perder la mitad de la
  // palabra lo haría ilegible.
  static String _periodoCorto(String periodo) =>
      periodo.startsWith('Últimos ') ? periodo.substring(8) : periodo;

  Widget _buildChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.of(context).primary),
            SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: AppColors.of(context).textMuted),
          ],
        ),
      ),
    );
  }

  // ── Zoom controls ─────────────────────────────────────────────────────────

  Widget _buildZoomControls() {
    return Positioned(
      right: 12,
      top: 12,
      child: Column(
        children: [
          _mapButton(Icons.add, () => _mapController.move(
            _mapController.camera.center, _mapController.camera.zoom + 1)),
          SizedBox(height: 6),
          _mapButton(Icons.remove, () => _mapController.move(
            _mapController.camera.center, _mapController.camera.zoom - 1)),
          SizedBox(height: 14),
          _mapButton(Icons.my_location_rounded, () => _mapController.move(_centroActual, 13.0)),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.of(context).textPrimary),
      ),
    );
  }

  // ── Info panel (consulta real seleccionada) ──────────────────────────────

  Widget _buildInfoPanel(ConsultaConUbicacion c) {
    final zona = (c.comunidad != null && c.comunidad!.isNotEmpty)
        ? c.comunidad!
        : (c.municipio ?? 'Sin zona registrada');

    return Positioned(
      bottom: 16,
      left: 12,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.nombrePaciente,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.of(context).textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(zona, style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _seleccionada = null),
                    child: Icon(Icons.close_rounded, size: 20, color: AppColors.of(context).textMuted),
                  ),
                ],
              ),
              Divider(height: 20, thickness: 1, color: Color(0xFFF3F4F6)),
              _infoRow(Icons.calendar_today_outlined, 'Fecha de consulta', _formatFecha(c.fechaCaptura)),
              if (c.categoriaSintoma != null && c.categoriaSintoma!.isNotEmpty) ...[
                SizedBox(height: 8),
                _infoRow(Icons.medical_information_outlined, 'Categoría de síntoma', c.categoriaSintoma!),
              ],
              SizedBox(height: 8),
              _infoRow(Icons.my_location_rounded, 'Coordenadas GPS',
                  '${c.latitud.toStringAsFixed(4)}, ${c.longitud.toStringAsFixed(4)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.of(context).textMuted),
        SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$label: ', style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted)),
                TextSpan(text: value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Resumen por comunidad ─────────────────────────────────────────────────

  void _showResumenComunidades() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Resumen por Comunidad',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Pacientes y consultas registradas en este dispositivo, agrupados por comunidad.',
                style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted),
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: _resumenComunidades.isEmpty
                  ? Center(
                      child: Text(
                        'Aún no hay pacientes registrados.',
                        style: TextStyle(fontSize: 13, color: AppColors.of(context).textMuted),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _resumenComunidades.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = _resumenComunidades[i];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.zona, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text(
                                '${r.totalPacientes} paciente(s) · ${r.totalConsultas} consulta(s) · '
                                'última visita: ${_formatFecha(r.ultimaVisita)}',
                                style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatFecha(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) {
        if (i == 0) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (i == 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AnomaliesPage()),
          );
        } else if (i == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => CasosPage()),
          );
        } else if (i == 3) {
          // ya estamos aquí
        } else if (i == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ServiciosPage()),
          );
        }
      },
      selectedItemColor: AppColors.of(context).primary,
      unselectedItemColor: AppColors.of(context).textMuted,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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

  // ── Selectors ─────────────────────────────────────────────────────────────

  void _showDiseaseSelector() {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final diseases = [
          'Influenza-A', 'Dengue', 'COVID-19', 'Cólera', 'Malaria', 'Todas',
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Seleccionar Enfermedad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...diseases.map((d) => ListTile(
                dense: true,
                title: Text(d, style: TextStyle(fontSize: 14)),
                trailing: d == _selectedDisease
                    ? Icon(Icons.check_rounded, color: AppColors.of(context).primary)
                    : null,
                onTap: () {
                  setState(() => _selectedDisease = d);
                  Navigator.pop(context);
                },
              )),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showPeriodSelector() {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final periods = [
          'Últimos 7 días', 'Últimos 14 días', 'Últimos 30 días', 'Últimos 3 meses',
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Seleccionar Período',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...periods.map((p) => ListTile(
                dense: true,
                title: Text(p, style: TextStyle(fontSize: 14)),
                trailing: p == _selectedPeriod
                    ? Icon(Icons.check_rounded, color: AppColors.of(context).primary)
                    : null,
                onTap: () {
                  setState(() => _selectedPeriod = p);
                  Navigator.pop(context);
                },
              )),
              SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
