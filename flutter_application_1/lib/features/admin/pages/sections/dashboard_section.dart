import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../data/admin_models.dart';

class DashboardSection extends StatefulWidget {
  final VoidCallback onGoToSolicitudes;

  DashboardSection({super.key, required this.onGoToSolicitudes});

  @override
  State<DashboardSection> createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.loadingStats) {
      return Center(child: CircularProgressIndicator());
    }

    if (provider.statsError != null) {
      return _ErrorView(
        message: provider.statsError!,
        onRetry: () => context.read<AdminProvider>().loadStats(),
      );
    }

    final stats = provider.stats;
    if (stats == null) {
      return Center(
        child: Text('Sin datos', style: TextStyle(color: AppColors.of(context).textMuted)),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.solicitudesPendientes > 0)
            _PendingBanner(
              count: stats.solicitudesPendientes,
              onTap: widget.onGoToSolicitudes,
            ),
          if (stats.solicitudesPendientes > 0) SizedBox(height: 20),
          _buildStatsRow(stats),
          SizedBox(height: 20),
          _ApprovedToday(count: stats.solicitudesAprobadasHoy),
        ],
      ),
    );
  }

  Widget _buildStatsRow(StatsModel stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _StatCard(
          label: 'Total usuarios',
          value: stats.totalUsuarios,
          icon: Icons.people,
          color: AppColors.of(context).info,
        ),
        _StatCard(
          label: 'Enfermeras',
          value: stats.porRol['enfermera'] ?? 0,
          icon: Icons.medical_services,
          color: AppColors.of(context).success,
        ),
        _StatCard(
          label: 'Doctores',
          value: stats.porRol['medico'] ?? 0,
          icon: Icons.local_hospital,
          color: Color(0xFF0D9488),
        ),
        _StatCard(
          label: 'Solicitudes pendientes',
          value: stats.solicitudesPendientes,
          icon: Icons.assignment_late,
          color: AppColors.of(context).warning,
          showAlert: stats.solicitudesPendientes > 0,
        ),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  _PendingBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hay $count ${count == 1 ? 'solicitud pendiente' : 'solicitudes pendientes'} de revisión.',
              style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(width: 12),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF92400E),
              textStyle: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: Text('Revisar ahora →'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool showAlert;

  _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.showAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (showAlert) ...[
                    SizedBox(width: 8),
                    Icon(Icons.circle, color: AppColors.of(context).error, size: 10),
                  ],
                ],
              ),
              SizedBox(height: 14),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    fontSize: 13, color: AppColors.of(context).textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApprovedToday extends StatelessWidget {
  final int count;
  _ApprovedToday({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline,
            color: AppColors.of(context).success, size: 18),
        SizedBox(width: 8),
        Text(
          'Solicitudes aprobadas hoy: $count',
          style: TextStyle(
              fontSize: 14, color: AppColors.of(context).textSecondary),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 48, color: AppColors.of(context).textMuted),
          SizedBox(height: 12),
          Text(message,
              style: TextStyle(color: AppColors.of(context).textSecondary)),
          SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 16),
            label: Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
