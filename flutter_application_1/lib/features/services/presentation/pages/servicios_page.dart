import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../anomalies/presentation/pages/anomalies_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cases/presentation/pages/casos_page.dart';
import '../../../map/presentation/pages/mapa_page.dart';

class ServiciosPage extends StatefulWidget {
  ServiciosPage({super.key});

  @override
  State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  final int _currentNavIndex = 4;

  // ── Service toggle states ─────────────────────────────────────────────────
  bool _gpsSync = true;
  bool _aiTriage = true;
  bool _dbCache = true;
  bool _alertEngine = false;
  bool _syncing = false;

  // ── Mock metrics ──────────────────────────────────────────────────────────
  final double _cacheUsed = 1.2;
  final double _cacheTotal = 4.0;
  final int _offlineRecords = 842;
  final int _syncQueue = 12;
  final String _systemLatency = '42ms';

  static const _trafficData = [
    0.35, 0.50, 0.42, 0.65, 0.55, 0.70,
    0.60, 0.80, 0.72, 0.88, 0.75, 1.00,
  ];

  // ── Controllers (backend integration points) ──────────────────────────────

  void _onToggleService(String serviceId, bool value) {
    // TODO: Connect with backend endpoint here
    // PUT /api/services/{serviceId}/toggle  { enabled: value }
    setState(() {
      switch (serviceId) {
        case 'gps':    _gpsSync = value;
        case 'ai':     _aiTriage = value;
        case 'db':     _dbCache = value;
        case 'alert':  _alertEngine = value;
      }
    });
  }

  Future<void> _onForceSync() async {
    // TODO: Connect with backend endpoint here
    // POST /api/services/sync/force
    setState(() => _syncing = true);
    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Sincronización completada',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: AppColors.of(context).success,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onClearCache() {
    // TODO: Connect with backend endpoint here
    // DELETE /api/cache/local
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Limpiar caché local',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          '¿Eliminar los registros en caché? Los datos no sincronizados se perderán.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: AppColors.of(context).textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Caché limpiada correctamente'),
                  backgroundColor: AppColors.of(context).primary,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Limpiar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemServicesSection(),
            SizedBox(height: 20),
            _buildTrafficCard(),
            SizedBox(height: 16),
            _buildLocalCacheCard(),
            SizedBox(height: 16),
            _buildInformationCard(),
            SizedBox(height: 16),
            _buildTopologyCard(),
            SizedBox(height: 8),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar with status banner ─────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight + 34),
      child: Column(
        children: [
          // Status banner
          Container(
            color: Color(0xFF0D3D2A),
            padding: EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Icon(Icons.cloud_done_outlined,
                    color: Colors.white70, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Nube Conectada: Nodo Distrito 7',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  'Latencia del Sistema: $_systemLatency',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Main AppBar
          AppBar(
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.of(context).primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.cloud_outlined,
                    color: AppColors.of(context).textSecondary, size: 22),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── System Services section ───────────────────────────────────────────────

  Widget _buildSystemServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios del Sistema',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Administra los microservicios principales y la persistencia local de datos.',
          style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted, height: 1.4),
        ),
        SizedBox(height: 14),
        // Force sync button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _syncing ? null : _onForceSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.of(context).primary.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: _syncing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Icon(Icons.sync_rounded, size: 18),
            label: Text(
              _syncing ? 'Sincronizando...' : 'Forzar Sincronización',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(height: 14),
        _buildServiceCard(
          id: 'gps',
          icon: Icons.gps_fixed_rounded,
          iconColor: AppColors.of(context).primary,
          title: 'Sincronización GPS',
          subtitle: 'Rastreo en Vivo',
          detail: 'Actividad: 99.9%',
          enabled: _gpsSync,
          activeLabel: 'Activo',
        ),
        SizedBox(height: 10),
        _buildServiceCard(
          id: 'ai',
          icon: Icons.psychology_rounded,
          iconColor: Color(0xFF7C3AED),
          title: 'Triaje con IA',
          subtitle: 'Detección de Patrones',
          detail: 'Modelo: v4.2.1-f',
          enabled: _aiTriage,
          activeLabel: 'Activo',
        ),
        SizedBox(height: 10),
        _buildServiceCard(
          id: 'db',
          icon: Icons.storage_rounded,
          iconColor: Color(0xFF0284C7),
          title: 'Caché de Base de Datos',
          subtitle: 'Persistencia Local',
          detail: 'Sinc.: hace 4 min',
          enabled: _dbCache,
          activeLabel: 'Saludable',
          inactiveLabel: 'Sin conexión',
        ),
        SizedBox(height: 10),
        _buildServiceCard(
          id: 'alert',
          icon: Icons.notification_important_rounded,
          iconColor: Color(0xFFDC2626),
          title: 'Motor de Alertas',
          subtitle: 'Monitor de Umbrales',
          detail: 'Reglas: 12 activas',
          enabled: _alertEngine,
          activeLabel: 'Activo',
          inactiveLabel: 'Suspendido',
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String detail,
    required bool enabled,
    required String activeLabel,
    String inactiveLabel = 'Inactivo',
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 12, 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.of(context).primary,
                onChanged: (v) => _onToggleService(id, v),
              ),
            ],
          ),
          SizedBox(height: 8),
          Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                detail,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.of(context).textMuted,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: enabled ? AppColors.of(context).success : AppColors.of(context).textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text(
                    enabled ? activeLabel : inactiveLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: enabled ? AppColors.of(context).success : AppColors.of(context).textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Traffic Throughput ────────────────────────────────────────────────────

  Widget _buildTrafficCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tráfico de Red',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: CustomPaint(
              painter: _TrafficPainter(data: _trafficData, primaryColor: AppColors.of(context).primary),
              size: Size(double.infinity, 90),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '08:00 AM',
                style: TextStyle(fontSize: 10, color: AppColors.of(context).textMuted),
              ),
              Text(
                '09:00 AM (Ahora)',
                style: TextStyle(fontSize: 10, color: AppColors.of(context).textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Local Cache ───────────────────────────────────────────────────────────

  Widget _buildLocalCacheCard() {
    final progress = _cacheUsed / _cacheTotal;

    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sd_storage_rounded,
                  color: AppColors.of(context).primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Caché Local',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Almacenamiento Usado',
                style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted),
              ),
              Text(
                '${_cacheUsed.toStringAsFixed(1)} GB / ${_cacheTotal.toStringAsFixed(1)} GB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.of(context).primary),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCacheStat(
                  label: 'Registros Sin Conexión',
                  value: _offlineRecords.toString(),
                  valueColor: Color(0xFF0284C7),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildCacheStat(
                  label: 'Cola de Sincronización',
                  value: _syncQueue.toString(),
                  valueColor: Color(0xFFD97706),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _onClearCache,
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFFDC2626),
                side: BorderSide(color: Color(0xFFDC2626), width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(Icons.delete_outline_rounded, size: 16),
              label: Text(
                'Limpiar Caché Local',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheStat({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.of(context).textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: valueColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Information ───────────────────────────────────────────────────────────

  Widget _buildInformationCard() {
    return Container(
      padding: EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow('Versión del Sistema', '4.12.0-stable'),
          Divider(height: 20, thickness: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Código de Distrito', 'D-07-CENTRAL'),
          Divider(height: 20, thickness: 1, color: Color(0xFFF3F4F6)),
          _buildInfoRow('Identidad del Nodo', 'FW-0892'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.of(context).textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ],
    );
  }

  // ── System Topology ───────────────────────────────────────────────────────

  Widget _buildTopologyCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 130,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _TopologyPainter()),
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Topología del Sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────────────────────

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
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => MapaPage()),
          );
        } else if (i == 4) {
          // ya estamos aquí
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
}

// ── Traffic chart painter ──────────────────────────────────────────────────────

class _TrafficPainter extends CustomPainter {
  final List<double> data;
  final Color primaryColor;
  _TrafficPainter({required this.data, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final count = data.length;
    final totalGap = size.width * 0.3;
    final barWidth = (size.width - totalGap) / count;
    final gap = totalGap / count;

    for (int i = 0; i < count; i++) {
      final barHeight = data[i] * size.height * 0.88;
      final x = i * (barWidth + gap);
      final y = size.height - barHeight;

      final isLast = i == count - 1;
      final color = isLast
          ? primaryColor
          : Color.lerp(
              Color(0xFF93C5B8),
              primaryColor,
              data[i],
            )!;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(3),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_TrafficPainter old) => old.data != data || old.primaryColor != primaryColor;
}

// ── System topology painter ────────────────────────────────────────────────────

class _TopologyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [Color(0xFF062A20), Color(0xFF0D4A36), Color(0xFF0A3D2E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = Color(0xFF1B6E52).withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = Color(0xFF26A87A).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Color(0xFF4ADE80).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Horizontal grid lines
    for (int i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Diagonal lines (circuit feel)
    final nodes = [
      Offset(size.width * 0.1, size.height * 0.2),
      Offset(size.width * 0.28, size.height * 0.6),
      Offset(size.width * 0.45, size.height * 0.3),
      Offset(size.width * 0.62, size.height * 0.7),
      Offset(size.width * 0.78, size.height * 0.25),
      Offset(size.width * 0.92, size.height * 0.55),
    ];

    for (int i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], glowPaint);
    }

    // Connect some non-adjacent nodes
    canvas.drawLine(nodes[0], nodes[2], linePaint);
    canvas.drawLine(nodes[1], nodes[4], linePaint);
    canvas.drawLine(nodes[3], nodes[5], linePaint);

    // Draw node circles
    for (int i = 0; i < nodes.length; i++) {
      final radius = i == 0 || i == 4 ? 5.0 : 3.5;
      canvas.drawCircle(nodes[i], radius, dotPaint);
      // Glow ring
      canvas.drawCircle(
        nodes[i],
        radius + 4,
        Paint()
          ..color = Color(0xFF4ADE80).withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );
    }

    // Pulse circles (decorative)
    final pulsePaint = Paint()
      ..color = Color(0xFF26A87A).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.35), 45, pulsePaint);
    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.7), 30, pulsePaint);

    // Corner accent
    final accentPaint = Paint()
      ..color = Color(0xFF26A87A).withValues(alpha: 0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final r = math.pi / 180;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(size.width, 0), width: 120, height: 120),
      math.pi / 2,
      math.pi / 2 * r * 90,
      false,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(_TopologyPainter _) => false;
}
