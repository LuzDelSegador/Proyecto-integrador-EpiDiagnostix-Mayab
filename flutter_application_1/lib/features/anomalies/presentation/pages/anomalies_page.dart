import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cases/presentation/pages/casos_page.dart';
import '../../../map/presentation/pages/mapa_page.dart';
import '../../../patients/presentation/pages/new_patient_selection_page.dart';
import '../../../services/presentation/pages/servicios_page.dart';
import 'package:provider/provider.dart';

class AnomaliesPage extends StatefulWidget {
  const AnomaliesPage({super.key});

  @override
  State<AnomaliesPage> createState() => _AnomaliesPageState();
}

class _AnomaliesPageState extends State<AnomaliesPage> {
  int _currentNavIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSyncBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 12),
                  _buildConfidenceCard(),
                  const SizedBox(height: 20),
                  _buildDetectionsHeader(),
                  const SizedBox(height: 12),
                  _buildDetectionCard(
                    icon: Icons.coronavirus_outlined,
                    iconBg: const Color(0xFFFFE4E4),
                    iconColor: const Color(0xFFDC2626),
                    disease: 'Cólera (Sospecha)',
                    badge: 'crítico',
                    badgeColor: const Color(0xFFDC2626),
                    location: 'Aldea San Marcos, Sector 4',
                    cases: '8 casos nuevos',
                    time: 'Hace 45 min',
                    confidence: 98,
                    actionLabel: 'Reportar a Central',
                    actionBg: const Color(0xFFDC2626),
                    actionFg: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildDetectionCard(
                    icon: Icons.wb_sunny_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    disease: 'Influenza Estacional',
                    badge: 'ADVERTENCIA',
                    badgeColor: const Color(0xFFD97706),
                    location: 'Centro Urbano - Zona 1',
                    cases: '24 casos acumulados',
                    time: 'Hace 3 horas',
                    confidence: 87,
                    actionLabel: 'Investigar',
                    actionBg: AppColors.primary,
                    actionFg: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildDetectionCard(
                    icon: Icons.biotech_outlined,
                    iconBg: const Color(0xFFEDE9FE),
                    iconColor: const Color(0xFF7C3AED),
                    disease: 'Agente Desconocido',
                    badge: 'RESERVACIÓN',
                    badgeColor: const Color(0xFF1E3A5F),
                    location: 'Periferia Norte',
                    cases: '3 síntomas atípicos',
                    time: 'Hace 6 horas',
                    confidence: 67,
                    actionLabel: 'Seguir Casos',
                    actionBg: Colors.transparent,
                    actionFg: AppColors.textSecondary,
                    actionBorder: const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 20),
                  _buildSpatialAnalysis(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewPatientSelectionPage()),
        ),
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.cloud_outlined,
              color: AppColors.textSecondary, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }

  // ── Sync banner ───────────────────────────────────────────────────────────

  Widget _buildSyncBanner() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, color: AppColors.success, size: 8),
          const SizedBox(width: 6),
          const Text(
            'Sincronizado: Hace 2 min',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Container(
              width: 1, height: 12, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 10),
          const Text(
            'DISTRITO 7 - ACTIVO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Page header ───────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anomalías de Enfermedades',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Detecciones inusuales identificadas por el motor de IA.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildAnomaliesCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildAlertCard()),
      ],
    );
  }

  Widget _buildAnomaliesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANOMALÍAS HOY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '12',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded,
                        color: AppColors.success, size: 12),
                    SizedBox(width: 2),
                    Text(
                      '+15%',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NIVEL ALERTA GLOBAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.62,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'MODERADO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD97706),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confidence card ───────────────────────────────────────────────────────

  Widget _buildConfidenceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6E52), Color(0xFF0D4A38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIANZA PROMEDIO IA',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '94.2%',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.verified_outlined,
                        color: Colors.white70, size: 20),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  // ── Detections header ─────────────────────────────────────────────────────

  Widget _buildDetectionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Detecciones Recientes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              const Icon(Icons.filter_list_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Filtrar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Detection card ────────────────────────────────────────────────────────

  Widget _buildDetectionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String disease,
    required String badge,
    required Color badgeColor,
    required String location,
    required String cases,
    required String time,
    required int confidence,
    required String actionLabel,
    required Color actionBg,
    required Color actionFg,
    Color? actionBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Cases + time
          Row(
            children: [
              const Icon(Icons.group_outlined,
                  color: AppColors.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                cases,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded,
                  color: AppColors.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Confidence + action row
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: [
                      const TextSpan(
                        text: 'IA Confianza: ',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      TextSpan(
                        text: '$confidence%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionBg,
                    foregroundColor: actionFg,
                    elevation: actionBg == Colors.transparent ? 0 : 1,
                    side: actionBorder != null
                        ? BorderSide(color: actionBorder, width: 1.2)
                        : BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: actionFg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.remove_red_eye_outlined,
                    color: AppColors.textMuted, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Spatial analysis section ──────────────────────────────────────────────

  Widget _buildSpatialAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análisis Espacial de Brotes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Visualización en tiempo real del Distrito 7. Las áreas en rojo muestran una densidad de infección mayor al promedio histórico.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 14),
            const SizedBox(width: 6),
            const Text(
              'Foco Detectado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Radio de 2km en expansión',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _HeatMapPainter(),
                ),
                const Positioned(
                  bottom: 10,
                  right: 10,
                  child: _LiveBadge(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (i) {
        if (i == 0) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (i == 2) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CasosPage()),
          );
        } else if (i == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MapaPage()),
          );
        } else if (i == 4) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiciosPage()),
          );
        } else {
          setState(() => _currentNavIndex = i);
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
}

// ── Live GPS badge ────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 6),
          SizedBox(width: 4),
          Text(
            'LIVE GPS FEED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Heat map painter ──────────────────────────────────────────────────────────

class _HeatMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF080C10),
    );

    void drawBlob(double cx, double cy, double r, List<Color> colors,
        List<double> stops) {
      final center = Offset(cx * size.width, cy * size.height);
      final paint = Paint()
        ..shader = RadialGradient(colors: colors, stops: stops)
            .createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, paint);
    }

    // Green blobs (cool — outer areas)
    drawBlob(0.15, 0.6, 55, [
      const Color(0xFF00CC44).withValues(alpha: 0.7),
      const Color(0xFF00AA33).withValues(alpha: 0.3),
      Colors.transparent,
    ], const [0.0, 0.5, 1.0]);

    drawBlob(0.82, 0.35, 40, [
      const Color(0xFF22BB55).withValues(alpha: 0.6),
      const Color(0xFF008833).withValues(alpha: 0.2),
      Colors.transparent,
    ], const [0.0, 0.55, 1.0]);

    drawBlob(0.72, 0.75, 35, [
      const Color(0xFF33CC44).withValues(alpha: 0.5),
      Colors.transparent,
    ], const [0.0, 1.0]);

    // Yellow blobs (warm)
    drawBlob(0.4, 0.5, 60, [
      const Color(0xFFFFDD00).withValues(alpha: 0.75),
      const Color(0xFFFFAA00).withValues(alpha: 0.35),
      Colors.transparent,
    ], const [0.0, 0.5, 1.0]);

    drawBlob(0.55, 0.65, 45, [
      const Color(0xFFFFBB00).withValues(alpha: 0.65),
      const Color(0xFFFF8800).withValues(alpha: 0.25),
      Colors.transparent,
    ], const [0.0, 0.5, 1.0]);

    // Orange blobs (hot)
    drawBlob(0.42, 0.42, 48, [
      const Color(0xFFFF7700).withValues(alpha: 0.85),
      const Color(0xFFFF4400).withValues(alpha: 0.4),
      Colors.transparent,
    ], const [0.0, 0.5, 1.0]);

    drawBlob(0.55, 0.38, 38, [
      const Color(0xFFFF5500).withValues(alpha: 0.8),
      const Color(0xFFFF2200).withValues(alpha: 0.3),
      Colors.transparent,
    ], const [0.0, 0.55, 1.0]);

    // Red core blobs (critical hot spots)
    drawBlob(0.44, 0.4, 30, [
      const Color(0xFFFF1100).withValues(alpha: 0.9),
      const Color(0xFFFF4400).withValues(alpha: 0.5),
      Colors.transparent,
    ], const [0.0, 0.5, 1.0]);

    drawBlob(0.52, 0.45, 22, [
      const Color(0xFFFF0000),
      const Color(0xFFFF3300).withValues(alpha: 0.5),
      Colors.transparent,
    ], const [0.0, 0.55, 1.0]);

    // Subtle grid overlay
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
