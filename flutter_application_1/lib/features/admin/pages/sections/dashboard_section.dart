import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../data/admin_models.dart';

class DashboardSection extends StatefulWidget {
  final VoidCallback onGoToSolicitudes;

  const DashboardSection({super.key, required this.onGoToSolicitudes});

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
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.statsError != null) {
      return _ErrorView(
        message: provider.statsError!,
        onRetry: () => context.read<AdminProvider>().loadStats(),
      );
    }

    final stats = provider.stats;
    if (stats == null) {
      return const Center(
        child: Text('Sin datos', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stats.solicitudesPendientes > 0)
            _PendingBanner(
              count: stats.solicitudesPendientes,
              onTap: widget.onGoToSolicitudes,
            ),
          if (stats.solicitudesPendientes > 0) const SizedBox(height: 20),
          _buildStatsRow(stats),
          const SizedBox(height: 20),
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
          color: AppColors.info,
        ),
        _StatCard(
          label: 'Enfermeras',
          value: stats.porRol['enfermera'] ?? 0,
          icon: Icons.medical_services,
          color: AppColors.success,
        ),
        _StatCard(
          label: 'Doctores',
          value: stats.porRol['medico'] ?? 0,
          icon: Icons.local_hospital,
          color: const Color(0xFF0D9488),
        ),
        _StatCard(
          label: 'Solicitudes pendientes',
          value: stats.solicitudesPendientes,
          icon: Icons.assignment_late,
          color: AppColors.warning,
          showAlert: stats.solicitudesPendientes > 0,
        ),
      ],
    );
  }
}

class _PendingBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PendingBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hay $count ${count == 1 ? 'solicitud pendiente' : 'solicitudes pendientes'} de revisión.',
              style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF92400E),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Revisar ahora →'),
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

  const _StatCard({
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
          padding: const EdgeInsets.all(20),
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
                    const SizedBox(width: 8),
                    const Icon(Icons.circle, color: AppColors.error, size: 10),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
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
  const _ApprovedToday({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline,
            color: AppColors.success, size: 18),
        const SizedBox(width: 8),
        Text(
          'Solicitudes aprobadas hoy: $count',
          style: const TextStyle(
              fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
