import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/widgets/upgrade_required_widget.dart';
import '../../../anomalies/presentation/pages/anomalies_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cases/presentation/pages/casos_page.dart';
import '../../../plans/presentation/pages/planes_page.dart';
import '../../../services/presentation/pages/servicios_page.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final int _currentNavIndex = 3;
  final MapController _mapController = MapController();

  String _selectedDisease = 'Influenza-A';
  String _selectedPeriod = 'Últimos 14 días';
  _DistrictInfo? _selectedDistrict = const _DistrictInfo(
    name: 'Distrito 7-A',
    risk: _RiskLevel.high,
    newCases: 42,
    caseDelta: '+12',
    testRate: 8.4,
    recommendations: [
      'Desplegar unidad móvil de pruebas en Sector B.',
      'Priorizar distribución de refuerzos de vacuna.',
    ],
  );

  static final _center = LatLng(14.6349, -90.5069);

  static final _hotspots = <_Hotspot>[
    _Hotspot(point: LatLng(14.6349, -90.5069), radius: 800, level: _RiskLevel.high),
    _Hotspot(point: LatLng(14.6500, -90.4900), radius: 500, level: _RiskLevel.medium),
    _Hotspot(point: LatLng(14.6200, -90.5300), radius: 400, level: _RiskLevel.medium),
    _Hotspot(point: LatLng(14.6450, -90.5250), radius: 300, level: _RiskLevel.low),
    _Hotspot(point: LatLng(14.6150, -90.4950), radius: 250, level: _RiskLevel.low),
  ];

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().currentRole;
    final bloqueado = !role.puedeVerMapa;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: bloqueado
          ? UpgradeRequiredWidget(
              featureName: 'Mapa Epidemiológico',
              requiredPlan: 'Premium (Doctor)',
              description:
                  'Visualiza focos de infección, zonas de riesgo y análisis '
                  'espacial de brotes en tiempo real.',
              onVerPlanes: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlanesPage()),
              ),
            )
          : Stack(
              children: [
                _buildMap(),
                _buildFilterRow(),
                _buildZoomControls(),
                if (_selectedDistrict != null)
                  _buildInfoPanel(_selectedDistrict!),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      leading: IconButton(
        icon: const Icon(Icons.account_circle_outlined,
            color: AppColors.textPrimary, size: 26),
        onPressed: () {
          context.read<AuthProvider>().resetStatus();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
      ),
      title: const Text(
        'EpiSurveillance',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.cloud_outlined,
              color: AppColors.textSecondary, size: 22),
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
        onTap: (_, tapPos) => setState(() => _selectedDistrict = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.episurveillance.app',
          maxZoom: 19,
        ),
        CircleLayer(
          circles: _hotspots.map((h) {
            final color = switch (h.level) {
              _RiskLevel.high   => const Color(0xFFDC2626),
              _RiskLevel.medium => const Color(0xFFD97706),
              _RiskLevel.low    => const Color(0xFF059669),
            };
            return CircleMarker(
              point: h.point,
              radius: h.radius,
              useRadiusInMeter: true,
              color: color.withValues(alpha: 0.20),
              borderColor: color.withValues(alpha: 0.55),
              borderStrokeWidth: 1.5,
            );
          }).toList(),
        ),
        MarkerLayer(
          markers: _hotspots.map((h) {
            final (icon, color) = switch (h.level) {
              _RiskLevel.high   => (Icons.warning_rounded, const Color(0xFFDC2626)),
              _RiskLevel.medium => (Icons.warning_amber_rounded, const Color(0xFFD97706)),
              _RiskLevel.low    => (Icons.info_outline_rounded, const Color(0xFF059669)),
            };
            return Marker(
              point: h.point,
              width: 32,
              height: 32,
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedDistrict = _DistrictInfo(
                    name: 'Distrito ${h.level == _RiskLevel.high ? "7-A" : h.level == _RiskLevel.medium ? "3-B" : "5-C"}',
                    risk: h.level,
                    newCases: h.level == _RiskLevel.high ? 42 : h.level == _RiskLevel.medium ? 21 : 7,
                    caseDelta: h.level == _RiskLevel.high ? '+12' : h.level == _RiskLevel.medium ? '+5' : '+1',
                    testRate: h.level == _RiskLevel.high ? 8.4 : h.level == _RiskLevel.medium ? 4.2 : 1.8,
                    recommendations: h.level == _RiskLevel.high
                        ? const ['Desplegar unidad móvil de pruebas en Sector B.', 'Priorizar distribución de refuerzos de vacuna.']
                        : h.level == _RiskLevel.medium
                            ? const ['Aumentar vigilancia activa en el sector.', 'Reforzar medidas de higiene en centros comunitarios.']
                            : const ['Continuar seguimiento de contactos.', 'Mantener protocolos de prevención estándar.'],
                  );
                }),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
          _buildChip(
            icon: Icons.coronavirus_outlined,
            label: 'ENFERMEDAD: $_selectedDisease',
            onTap: _showDiseaseSelector,
          ),
          const SizedBox(width: 8),
          _buildChip(
            icon: Icons.date_range_rounded,
            label: _selectedPeriod,
            onTap: _showPeriodSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: AppColors.textMuted),
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
          const SizedBox(height: 6),
          _mapButton(Icons.remove, () => _mapController.move(
            _mapController.camera.center, _mapController.camera.zoom - 1)),
          const SizedBox(height: 14),
          _mapButton(Icons.my_location_rounded, () => _mapController.move(_center, 13.0)),
          const SizedBox(height: 6),
          _mapButton(Icons.layers_outlined, () {}),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }

  // ── Info panel ────────────────────────────────────────────────────────────

  Widget _buildInfoPanel(_DistrictInfo district) {
    final (riskLabel, riskColor) = switch (district.risk) {
      _RiskLevel.high   => ('ALTO RIESGO', const Color(0xFFDC2626)),
      _RiskLevel.medium => ('RIESGO MODERADO', const Color(0xFFD97706)),
      _RiskLevel.low    => ('RIESGO BAJO', const Color(0xFF059669)),
    };

    return Positioned(
      bottom: 16,
      left: 12,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          district.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Estado de Zona Seleccionada',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: riskColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      riskLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            // Stats
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      'Casos Nuevos',
                      district.newCases.toString(),
                      delta: '${district.caseDelta}%',
                      deltaPositive: false,
                    ),
                  ),
                  Container(width: 1, height: 40, color: const Color(0xFFF3F4F6)),
                  Expanded(
                    child: _buildStatColumn(
                      'Tasa de Pruebas',
                      '${district.testRate}',
                      suffix: '%',
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
            // Recommendations
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECOMENDACIONES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...district.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            // CTA button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.bar_chart_rounded, size: 16),
                  label: const Text(
                    'Análisis Completo de Zona',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value,
      {String? delta, bool deltaPositive = true, String? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 2),
                  child: Text(
                    suffix,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (delta != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      delta,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
            MaterialPageRoute(builder: (_) => const AnomaliesPage()),
          );
        } else if (i == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CasosPage()),
          );
        } else if (i == 3) {
          // ya estamos aquí
        } else if (i == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiciosPage()),
          );
        }
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      backgroundColor: Colors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        const diseases = [
          'Influenza-A', 'Dengue', 'COVID-19', 'Cólera', 'Malaria', 'Todas',
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Seleccionar Enfermedad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...diseases.map((d) => ListTile(
                dense: true,
                title: Text(d, style: const TextStyle(fontSize: 14)),
                trailing: d == _selectedDisease
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedDisease = d);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showPeriodSelector() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        const periods = [
          'Últimos 7 días', 'Últimos 14 días', 'Últimos 30 días', 'Últimos 3 meses',
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Seleccionar Período',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ...periods.map((p) => ListTile(
                dense: true,
                title: Text(p, style: const TextStyle(fontSize: 14)),
                trailing: p == _selectedPeriod
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedPeriod = p);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Data models ────────────────────────────────────────────────────────────────

enum _RiskLevel { high, medium, low }

class _Hotspot {
  final LatLng point;
  final double radius;
  final _RiskLevel level;
  _Hotspot({required this.point, required this.radius, required this.level});
}

class _DistrictInfo {
  final String name;
  final _RiskLevel risk;
  final int newCases;
  final String caseDelta;
  final double testRate;
  final List<String> recommendations;
  const _DistrictInfo({
    required this.name,
    required this.risk,
    required this.newCases,
    required this.caseDelta,
    required this.testRate,
    required this.recommendations,
  });
}
