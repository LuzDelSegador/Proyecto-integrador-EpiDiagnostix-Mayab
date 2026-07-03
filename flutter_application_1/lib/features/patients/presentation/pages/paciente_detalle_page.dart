import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/paciente.dart';
import '../../data/repositories/patient_local_repository.dart';

class PacienteDetallePage extends StatefulWidget {
  final PacienteConResumen paciente;
  const PacienteDetallePage({super.key, required this.paciente});

  @override
  State<PacienteDetallePage> createState() => _PacienteDetallePageState();
}

class _PacienteDetallePageState extends State<PacienteDetallePage> {
  List<ConsultaResumen>? _consultas;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lista = await sl<PatientLocalRepository>()
        .getConsultasDePaciente(widget.paciente.paciente.id);
    if (mounted) setState(() => _consultas = lista);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paciente.paciente;
    final r = widget.paciente;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(p, r),
          if (_consultas == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_consultas!.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList.separated(
                itemCount: _consultas!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _buildConsultaCard(_consultas![i]),
              ),
            ),
        ],
      ),
    );
  }

  // ── Sliver app bar con header expandible ──────────────────────────────────

  Widget _buildSliverAppBar(Paciente p, PacienteConResumen r) {
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      expandedHeight: 195,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        _initials(p.nombreCompleto),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombreCompleto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (p.comunidad != null && p.comunidad!.isNotEmpty)
                            Text(
                              p.comunidad!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatChip(label: '${p.totalVisitas} total'),
                    _StatChip(label: '${r.visitasEstaSemana} esta semana'),
                    _StatChip(label: '${r.visitasEsteMes} este mes'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tarjeta de consulta ───────────────────────────────────────────────────

  Widget _buildConsultaCard(ConsultaResumen c) {
    final fiebre = c.temperaturaC != null && c.temperaturaC! >= 38.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha + categoría
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  _formatDate(c.fechaCaptura),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (c.categoriaSintoma != null)
                  _CategoryBadge(label: c.categoriaSintoma!),
              ],
            ),

            // Signos vitales
            if (c.temperaturaC != null ||
                (c.presionSistolica != null && c.presionDiastolica != null) ||
                c.glucosaMgDl != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (c.temperaturaC != null)
                    _VitalChip(
                      icon: Icons.thermostat_rounded,
                      label: '${c.temperaturaC!.toStringAsFixed(1)} °C',
                      alert: fiebre,
                    ),
                  if (c.presionSistolica != null && c.presionDiastolica != null)
                    _VitalChip(
                      icon: Icons.favorite_border_rounded,
                      label:
                          '${c.presionSistolica}/${c.presionDiastolica} mmHg',
                    ),
                  if (c.glucosaMgDl != null)
                    _VitalChip(
                      icon: Icons.water_drop_outlined,
                      label:
                          '${c.glucosaMgDl!.toStringAsFixed(0)} mg/dL',
                    ),
                ],
              ),
            ],

            // Alerta de fiebre
            if (fiebre) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_rounded,
                        color: Color(0xFFDC2626), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Temperatura elevada (≥38°C)',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'Sin consultas registradas',
        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
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

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  const _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool alert;
  const _VitalChip({
    required this.icon,
    required this.label,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = alert ? const Color(0xFFDC2626) : AppColors.textSecondary;
    final bg    = alert
        ? const Color(0xFFFFE4E4)
        : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
