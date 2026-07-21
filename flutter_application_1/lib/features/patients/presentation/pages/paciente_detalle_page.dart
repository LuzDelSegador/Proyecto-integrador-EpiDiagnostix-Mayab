import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/paciente.dart';
import '../../data/repositories/patient_local_repository.dart';
import 'audio_confirmation_page.dart';
import 'new_patient_selection_page.dart';

class PacienteDetallePage extends StatefulWidget {
  final PacienteConResumen paciente;
  PacienteDetallePage({super.key, required this.paciente});

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
      backgroundColor: AppColors.of(context).background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(p, r),
          if (_consultas == null)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_consultas!.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList.separated(
                itemCount: _consultas!.length,
                separatorBuilder: (_, __) => SizedBox(height: 10),
                itemBuilder: (_, i) => _buildConsultaCard(_consultas![i]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NewPatientSelectionPage(
              pacienteId: p.id,
              pacienteNombre: p.nombreCompleto,
            ),
          ),
        ),
        backgroundColor: AppColors.of(context).primary,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Agregar Caso',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Sliver app bar con header expandible ──────────────────────────────────

  Widget _buildSliverAppBar(Paciente p, PacienteConResumen r) {
    return SliverAppBar(
      backgroundColor: AppColors.of(context).primary,
      foregroundColor: Colors.white,
      expandedHeight: 195,
      pinned: true,
      actions: [
        IconButton(
          icon: Icon(Icons.badge_outlined, color: Colors.white),
          tooltip: 'Ver perfil completo',
          onPressed: () => _showPerfilCompleto(context, p),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 48, 20, 16),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nombreCompleto,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (p.comunidad != null && p.comunidad!.isNotEmpty)
                            Text(
                              p.comunidad!,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
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

  // ── Ver perfil completo (bottom sheet) ────────────────────────────────────

  void _showPerfilCompleto(BuildContext context, Paciente p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PerfilCompletoSheet(paciente: p),
    );
  }

  // ── Tarjeta de consulta ───────────────────────────────────────────────────

  Widget _buildConsultaCard(ConsultaResumen c) {
    final fiebre = c.temperaturaC != null && c.temperaturaC! >= 38.0;
    final p = widget.paciente.paciente;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AudioConfirmationPage(
            pacienteId: p.id,
            pacienteNombre: p.nombreCompleto,
            clinicalFields: c.camposExtraidos,
            originalText: c.textoOriginal,
            readOnly: true,
            fechaGuardada: c.fechaCaptura,
            sincronizado: c.sincronizado,
            latitudGuardada: c.latitud,
            longitudGuardada: c.longitud,
          ),
        ),
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
            // Fecha + categoría
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.of(context).textMuted),
                SizedBox(width: 6),
                Text(
                  _formatDate(c.fechaCaptura),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                Spacer(),
                if (c.categoriaSintoma != null)
                  _CategoryBadge(label: c.categoriaSintoma!),
              ],
            ),

            // Signos vitales
            if (c.temperaturaC != null ||
                (c.presionSistolica != null && c.presionDiastolica != null) ||
                c.glucosaMgDl != null) ...[
              SizedBox(height: 12),
              Divider(height: 1, color: Color(0xFFF3F4F6)),
              SizedBox(height: 12),
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
              SizedBox(height: 10),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE4E4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
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
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'Sin consultas registradas',
        style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 14),
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
  _StatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
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
  _VitalChip({
    required this.icon,
    required this.label,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = alert ? Color(0xFFDC2626) : AppColors.of(context).textSecondary;
    final bg    = alert
        ? Color(0xFFFFE4E4)
        : Color(0xFFF3F4F6);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 5),
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
  _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.of(context).primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.of(context).primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.of(context).primary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Perfil completo (bottom sheet) ─────────────────────────────────────────────

class _PerfilCompletoSheet extends StatelessWidget {
  final Paciente paciente;
  const _PerfilCompletoSheet({required this.paciente});

  @override
  Widget build(BuildContext context) {
    final p = paciente;
    final edad = _calcularEdad(p.fechaNacimiento);
    final fechaNac = _formatFechaISO(p.fechaNacimiento);
    final sexoTexto = switch (p.sexo) {
      'M' => 'Masculino',
      'F' => 'Femenino',
      _ => p.sexo,
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.of(context).border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Perfil Completo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              p.nombreCompleto,
              style: TextStyle(fontSize: 13, color: AppColors.of(context).textSecondary),
            ),
            SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PerfilRow(label: 'CURP', value: p.curp),
                    Divider(height: 1, color: AppColors.of(context).border),
                    _PerfilRow(
                      label: 'Fecha de Nacimiento',
                      value: fechaNac == null ? null : '$fechaNac${edad != null ? ' ($edad años)' : ''}',
                    ),
                    Divider(height: 1, color: AppColors.of(context).border),
                    _PerfilRow(label: 'Sexo', value: sexoTexto),
                    Divider(height: 1, color: AppColors.of(context).border),
                    _PerfilRow(label: 'Municipio', value: p.municipio),
                    Divider(height: 1, color: AppColors.of(context).border),
                    _PerfilRow(label: 'Lengua Materna', value: p.lenguaMaterna),
                    Divider(height: 1, color: AppColors.of(context).border),
                    _PerfilRow(label: 'Contacto de Emergencia', value: p.contactoEmergencia),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int? _calcularEdad(String? fechaNacimientoIso) {
    final nacimiento = fechaNacimientoIso != null ? DateTime.tryParse(fechaNacimientoIso) : null;
    if (nacimiento == null) return null;
    final hoy = DateTime.now();
    var edad = hoy.year - nacimiento.year;
    if (hoy.month < nacimiento.month ||
        (hoy.month == nacimiento.month && hoy.day < nacimiento.day)) {
      edad--;
    }
    return edad;
  }

  static String? _formatFechaISO(String? iso) {
    final dt = iso != null ? DateTime.tryParse(iso) : null;
    if (dt == null) return null;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }
}

class _PerfilRow extends StatelessWidget {
  final String label;
  final String? value;
  const _PerfilRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final tieneValor = value != null && value!.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.of(context).textSecondary),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              tieneValor ? value! : 'No registrado',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: tieneValor ? FontWeight.w600 : FontWeight.normal,
                fontStyle: tieneValor ? FontStyle.normal : FontStyle.italic,
                color: tieneValor ? AppColors.of(context).textPrimary : AppColors.of(context).textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
