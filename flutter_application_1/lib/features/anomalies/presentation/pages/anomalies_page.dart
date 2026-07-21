import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/upgrade_required_widget.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cases/presentation/pages/casos_page.dart';
import '../../../map/presentation/pages/mapa_page.dart';
import '../../../patients/presentation/widgets/add_case_choice_sheet.dart';
import '../../../plans/presentation/pages/planes_page.dart';
import '../../../services/presentation/pages/servicios_page.dart';
import '../../data/anomaly_service.dart';

class AnomaliesPage extends StatefulWidget {
  AnomaliesPage({super.key});

  @override
  State<AnomaliesPage> createState() => _AnomaliesPageState();
}

class _AnomaliesPageState extends State<AnomaliesPage> {
  int _currentNavIndex = 1;

  // ── Data state ────────────────────────────────────────────────────────────
  bool _loading = false;
  String? _error;
  List<AnomalyResult> _historial = [];
  DateTime? _ultimaSincronizacion;
  Timer? _refreshTimer;

  // ── Computed stats ────────────────────────────────────────────────────────
  int _anomaliasHoy = 0;
  int _anomaliasAyer = 0;
  double _confianzaPromedio = 0.0;
  String _nivelAlerta = 'BAJO';
  Color _nivelAlertaColor = Color(0xFF10B981);
  double _progresoAlerta = 0.2;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer =
        Timer.periodic(Duration(minutes: 5), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await sl<AnomalyService>().getHistorial();
      if (!mounted) return;
      _computeStats(results);
      setState(() {
        _historial = results;
        _ultimaSincronizacion = DateTime.now();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Sin conexión con el servidor de IA';
        _loading = false;
      });
    }
  }

  void _computeStats(List<AnomalyResult> results) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    int hoy = 0, ayer = 0;
    double totalConfianza = 0;
    int countAnomalia = 0;

    for (final r in results) {
      final d = DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      if (r.esAnomalia) {
        countAnomalia++;
        totalConfianza += r.confianza;
        if (d == today) {
          hoy++;
        } else if (d == yesterday) {
          ayer++;
        }
      }
    }

    String nivel;
    Color color;
    double progreso;
    if (hoy >= 6) {
      nivel = 'ALTO';
      color = AppColors.of(context).error;
      progreso = 0.9;
    } else if (hoy >= 3) {
      nivel = 'MODERADO';
      color = Color(0xFFD97706);
      progreso = 0.6;
    } else {
      nivel = 'BAJO';
      color = AppColors.of(context).success;
      progreso = 0.2;
    }

    _anomaliasHoy = hoy;
    _anomaliasAyer = ayer;
    _confianzaPromedio =
        countAnomalia == 0 ? 0.0 : totalConfianza / countAnomalia;
    _nivelAlerta = nivel;
    _nivelAlertaColor = color;
    _progresoAlerta = progreso;
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showDetailDialog(AnomalyResult r) {
    // tipo 'completa': muestra campos de extraccion no-null
    // tipo 'anomalia': muestra score + nivel_riesgo + es_anomalia
    final extraccion = r.outputJson?['extraccion'] as Map<String, dynamic>?;
    final Map<String, String> detailEntries;
    if (extraccion != null && extraccion.isNotEmpty) {
      detailEntries = {
        for (final e in extraccion.entries)
          if (e.value != null) e.key: '${e.value}',
      };
    } else {
      detailEntries = {
        'score': r.score.toStringAsFixed(4),
        'nivel_riesgo': r.nivelRiesgo,
        'es_anomalia': '${r.esAnomalia}',
      };
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Detalles de inferencia'),
        content: SingleChildScrollView(
          child: detailEntries.isEmpty
              ? Text('Sin datos adicionales disponibles.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: detailEntries.entries
                      .map(
                        (e) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 3),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: '${e.key}: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: e.value),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String disease, String location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reportar a Central'),
        content: Text('¿Confirmar reporte de "$disease" detectado en $location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reporte enviado a Central exitosamente'),
                  backgroundColor: AppColors.of(context).success,
                ),
              );
            },
            child: Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().currentRole;
    final bloqueado = role == UserRole.usuario;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSyncBanner(),
          Expanded(
            child: bloqueado
                ? UpgradeRequiredWidget(
                    featureName: 'Anomalías ML',
                    requiredPlan: 'Intermedio (Enfermera)',
                    description:
                        'El motor de IA detecta brotes y anomalías epidemiológicas en tiempo real. Disponible desde el plan Intermedio.',
                    onVerPlanes: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlanesPage()),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(),
                        SizedBox(height: 16),
                        _buildStatsRow(),
                        SizedBox(height: 12),
                        _buildConfidenceCard(),
                        SizedBox(height: 20),
                        _buildDetectionsHeader(),
                        SizedBox(height: 12),
                        _buildDetectionsBody(),
                        SizedBox(height: 20),
                        _buildSpatialAnalysis(),
                        SizedBox(height: 90),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: bloqueado
          ? null
          : FloatingActionButton(
              onPressed: () => showAddCaseChoiceSheet(context),
              backgroundColor: AppColors.of(context).primary,
              elevation: 4,
              child: Icon(Icons.add, color: Colors.white, size: 28),
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
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.cloud_outlined,
              color: AppColors.of(context).textSecondary, size: 22),
          onPressed: _loadData,
        ),
      ],
    );
  }

  // ── Sync banner ───────────────────────────────────────────────────────────

  Widget _buildSyncBanner() {
    final auth = context.read<AuthProvider>();
    final firstName = auth.currentUser.name.split(' ').first;
    final dotColor = _error != null ? AppColors.of(context).error : AppColors.of(context).success;
    final syncText = _ultimaSincronizacion == null
        ? 'Sin sincronizar'
        : 'Sincronizado: ${_formatRelative(_ultimaSincronizacion!)}';

    return Container(
      color: AppColors.of(context).surface,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.circle, color: dotColor, size: 8),
          SizedBox(width: 6),
          Text(
            syncText,
            style:
                TextStyle(fontSize: 11, color: AppColors.of(context).textSecondary),
          ),
          SizedBox(width: 10),
          Container(width: 1, height: 12, color: Color(0xFFE5E7EB)),
          SizedBox(width: 10),
          Text(
            '$firstName - ACTIVO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).primary,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Page header ───────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anomalías de Enfermedades',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Detecciones inusuales identificadas por el motor de IA.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.of(context).textSecondary,
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
        SizedBox(width: 12),
        Expanded(child: _buildAlertCard()),
      ],
    );
  }

  Widget _buildAnomaliesCard() {
    final diff = _anomaliasHoy - _anomaliasAyer;
    final trendText = diff >= 0 ? '+$diff' : '$diff';
    final trendColor = diff > 0 ? AppColors.of(context).error : AppColors.of(context).success;
    final trendIcon =
        diff > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ANOMALÍAS HOY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).textMuted,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_anomaliasHoy',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).textPrimary,
                  height: 1,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, color: trendColor, size: 12),
                    SizedBox(width: 2),
                    Text(
                      trendText,
                      style: TextStyle(
                        color: trendColor,
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NIVEL ALERTA GLOBAL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).textMuted,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progresoAlerta,
              minHeight: 8,
              backgroundColor: Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(_nivelAlertaColor),
            ),
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _nivelAlerta,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _nivelAlertaColor,
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
    final pct = _confianzaPromedio.toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
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
                SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$pct%',
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
            child: Icon(Icons.shield_outlined,
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
        Text(
          'Detecciones Recientes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        GestureDetector(
          onTap: _loadData,
          child: Row(
            children: [
              Icon(Icons.refresh_rounded, color: AppColors.of(context).primary, size: 16),
              SizedBox(width: 4),
              Text(
                'Actualizar',
                style: TextStyle(
                  color: AppColors.of(context).primary,
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

  // ── Detections body (4 states) ────────────────────────────────────────────

  Widget _buildDetectionsBody() {
    if (_loading && _historial.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _historial.isEmpty) {
      return _buildErrorCard();
    }

    final anomalias = _historial
        .where((r) => r.nivelRiesgo == 'anomalo' || r.nivelRiesgo == 'sospechoso')
        .toList();

    if (anomalias.isEmpty) {
      return _buildEmptyCard();
    }

    return Column(
      children: anomalias
          .map(
            (r) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildDetectionCardFromResult(r),
            ),
          )
          .toList(),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined,
              color: AppColors.of(context).error, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: AppColors.of(context).error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: _loadData,
            child: Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.of(context).success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.of(context).success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: AppColors.of(context).success, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sin anomalías detectadas',
                  style: TextStyle(
                    color: AppColors.of(context).success,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'El sistema está monitoreando activamente sin detectar patrones anómalos.',
                  style: TextStyle(
                    color: AppColors.of(context).textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCardFromResult(AnomalyResult r) {
    final isCritico = r.nivelRiesgo == 'anomalo';
    final confianza = r.confianza.round();

    final titulo = r.categoriaSintoma != null
        ? 'Categoría: ${r.categoriaSintoma}'
        : isCritico
            ? 'Patrón Clínico Crítico'
            : 'Patrón Clínico Sospechoso';

    final List<String> detalles = [];
    if (r.temperatura != null && r.temperatura! >= 38) {
      detalles.add('Fiebre ${r.temperatura}°C');
    }
    if (r.glucosa != null && r.glucosa! >= 200) {
      detalles.add('Glucosa elevada ${r.glucosa} mg/dL');
    }
    if (r.presionSistolica != null && r.presionSistolica! >= 180) {
      detalles.add('HTA severa ${r.presionSistolica} mmHg');
    }
    if (detalles.isEmpty) { detalles.add('Score: ${r.score.toStringAsFixed(4)}'); }
    final cases = detalles.join(' · ');

    final sexoStr =
        r.sexo == 'M' ? 'masculino' : r.sexo == 'F' ? 'femenino' : '';
    final ubicacion = (r.tipo == 'completa' && r.edad != null)
        ? 'Paciente${sexoStr.isEmpty ? '' : ' $sexoStr'} · ${r.edad} años'
        : 'Detección automática ML';

    return _buildDetectionCard(
      icon: isCritico
          ? Icons.coronavirus_outlined
          : Icons.warning_amber_outlined,
      iconBg: isCritico
          ? Color(0xFFFFE4E4)
          : Color(0xFFFEF3C7),
      iconColor: isCritico ? AppColors.of(context).error : Color(0xFFD97706),
      disease: titulo,
      badge: isCritico ? 'CRÍTICO' : 'ADVERTENCIA',
      badgeColor: isCritico ? AppColors.of(context).error : Color(0xFFD97706),
      location: ubicacion,
      cases: cases,
      time: _formatRelative(r.createdAt),
      confidence: confianza,
      actionLabel: isCritico ? 'Reportar a Central' : 'Ver detalles',
      actionBg: isCritico ? AppColors.of(context).error : AppColors.of(context).primary,
      actionFg: Colors.white,
      onAction: isCritico
          ? () => _showReportDialog(titulo, ubicacion)
          : () => _showDetailDialog(r),
      onViewDetail: () => _showDetailDialog(r),
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
    VoidCallback? onAction,
    VoidCallback? onViewDetail,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(14),
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
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disease,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
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
          SizedBox(height: 12),
          // Location
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  color: AppColors.of(context).textMuted, size: 14),
              SizedBox(width: 4),
              Text(
                location,
                style: TextStyle(
                    fontSize: 12, color: AppColors.of(context).textSecondary),
              ),
            ],
          ),
          SizedBox(height: 4),
          // Cases + time
          Row(
            children: [
              Icon(Icons.fingerprint_outlined,
                  color: AppColors.of(context).textMuted, size: 14),
              SizedBox(width: 4),
              Text(
                cases,
                style: TextStyle(
                    fontSize: 12, color: AppColors.of(context).textSecondary),
              ),
              SizedBox(width: 12),
              Icon(Icons.access_time_rounded,
                  color: AppColors.of(context).textMuted, size: 14),
              SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(
                    fontSize: 12, color: AppColors.of(context).textSecondary),
              ),
            ],
          ),
          SizedBox(height: 10),
          // Confidence
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12),
              children: [
                TextSpan(
                  text: 'IA Confianza: ',
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
                TextSpan(
                  text: '$confidence%',
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          // Action row
          Row(
            children: [
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionBg,
                    foregroundColor: actionFg,
                    elevation: actionBg == Colors.transparent ? 0 : 1,
                    side: actionBorder != null
                        ? BorderSide(color: actionBorder, width: 1.2)
                        : BorderSide.none,
                    padding: EdgeInsets.symmetric(horizontal: 14),
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
              SizedBox(width: 10),
              GestureDetector(
                onTap: onViewDetail,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove_red_eye_outlined,
                      color: AppColors.of(context).textMuted, size: 18),
                ),
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
        Text(
          'Análisis Espacial de Brotes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Visualización en tiempo real del Distrito 7. Las áreas en rojo muestran una densidad de infección mayor al promedio histórico.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.of(context).textSecondary,
            height: 1.5,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.my_location_rounded,
                color: AppColors.of(context).primary, size: 14),
            SizedBox(width: 6),
            Text(
              'Foco Detectado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Radio de 2km en expansión',
              style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
            ),
          ],
        ),
        SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(double.infinity, 180),
                  painter: _HeatMapPainter(),
                ),
                Positioned(
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

// ── Live GPS badge ────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.of(context).success,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: Colors.white, size: 6),
          SizedBox(width: 4),
          Text(
            'GPS EN VIVO',
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
      Paint()..color = Color(0xFF080C10),
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
      Color(0xFF00CC44).withValues(alpha: 0.7),
      Color(0xFF00AA33).withValues(alpha: 0.3),
      Colors.transparent,
    ], [0.0, 0.5, 1.0]);

    drawBlob(0.82, 0.35, 40, [
      Color(0xFF22BB55).withValues(alpha: 0.6),
      Color(0xFF008833).withValues(alpha: 0.2),
      Colors.transparent,
    ], [0.0, 0.55, 1.0]);

    drawBlob(0.72, 0.75, 35, [
      Color(0xFF33CC44).withValues(alpha: 0.5),
      Colors.transparent,
    ], [0.0, 1.0]);

    // Yellow blobs (warm)
    drawBlob(0.4, 0.5, 60, [
      Color(0xFFFFDD00).withValues(alpha: 0.75),
      Color(0xFFFFAA00).withValues(alpha: 0.35),
      Colors.transparent,
    ], [0.0, 0.5, 1.0]);

    drawBlob(0.55, 0.65, 45, [
      Color(0xFFFFBB00).withValues(alpha: 0.65),
      Color(0xFFFF8800).withValues(alpha: 0.25),
      Colors.transparent,
    ], [0.0, 0.5, 1.0]);

    // Orange blobs (hot)
    drawBlob(0.42, 0.42, 48, [
      Color(0xFFFF7700).withValues(alpha: 0.85),
      Color(0xFFFF4400).withValues(alpha: 0.4),
      Colors.transparent,
    ], [0.0, 0.5, 1.0]);

    drawBlob(0.55, 0.38, 38, [
      Color(0xFFFF5500).withValues(alpha: 0.8),
      Color(0xFFFF2200).withValues(alpha: 0.3),
      Colors.transparent,
    ], [0.0, 0.55, 1.0]);

    // Red core blobs (critical hot spots)
    drawBlob(0.44, 0.4, 30, [
      Color(0xFFFF1100).withValues(alpha: 0.9),
      Color(0xFFFF4400).withValues(alpha: 0.5),
      Colors.transparent,
    ], [0.0, 0.5, 1.0]);

    drawBlob(0.52, 0.45, 22, [
      Color(0xFFFF0000),
      Color(0xFFFF3300).withValues(alpha: 0.5),
      Colors.transparent,
    ], [0.0, 0.55, 1.0]);

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
