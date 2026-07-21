import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../data/admin_models.dart';

class SolicitudesSection extends StatefulWidget {
  SolicitudesSection({super.key});

  @override
  State<SolicitudesSection> createState() => _SolicitudesSectionState();
}

class _SolicitudesSectionState extends State<SolicitudesSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: 'Pendientes', estado: 'pendiente'),
    (label: 'Aprobadas', estado: 'aprobada'),
    (label: 'Rechazadas', estado: 'rechazada'),
  ];

  String _currentEstado = 'pendiente';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadSolicitudes('pendiente');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: AppColors.of(context).surface,
          padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.of(context).primary,
            unselectedLabelColor: AppColors.of(context).textSecondary,
            indicatorColor: AppColors.of(context).primary,
            indicatorWeight: 2.5,
            labelStyle: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: _tabs
                .map((t) => Tab(text: t.label))
                .toList(),
            onTap: (index) {
              final estado = _tabs[index].estado;
              setState(() => _currentEstado = estado);
              context.read<AdminProvider>().loadSolicitudes(estado);
            },
          ),
        ),
        Divider(height: 1),
        Expanded(
          child: _buildBody(provider),
        ),
      ],
    );
  }

  Widget _buildBody(AdminProvider provider) {
    if (provider.loadingSolicitudes) {
      return Center(child: CircularProgressIndicator());
    }

    if (provider.solicitudesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.of(context).textMuted),
            SizedBox(height: 12),
            Text(provider.solicitudesError!,
                style: TextStyle(color: AppColors.of(context).textSecondary)),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<AdminProvider>()
                  .loadSolicitudes(_currentEstado),
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined,
                size: 48,
                color: AppColors.of(context).textMuted.withValues(alpha: 0.5)),
            SizedBox(height: 12),
            Text(
              'Sin solicitudes ${_currentEstado == 'pendiente' ? 'pendientes' : _currentEstado == 'aprobada' ? 'aprobadas' : 'rechazadas'}.',
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(24),
      itemCount: provider.solicitudes.length,
      itemBuilder: (context, index) {
        final s = provider.solicitudes[index];
        return _SolicitudCard(
          solicitud: s,
          showActions: _currentEstado == 'pendiente',
          onAprobar: () => _confirmarAprobar(s),
          onRechazar: () => _confirmarRechazar(s),
        );
      },
    );
  }

  Future<void> _confirmarAprobar(SolicitudAdminModel s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aprobar solicitud'),
        content: Text(
          '¿Confirmas que verificaste la cédula ${s.numeroCedula} de '
          '${s.nombreEnCedula} en el registro de la SEP?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sí, aprobar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context
          .read<AdminProvider>()
          .aprobarSolicitud(s.solicitudId, _currentEstado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Solicitud aprobada. El usuario ahora tiene acceso Premium.'),
            backgroundColor: AppColors.of(context).success,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar la solicitud.'),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    }
  }

  Future<void> _confirmarRechazar(SolicitudAdminModel s) async {
    final motivoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final motivo = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Rechazar solicitud'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitante: ${s.personal.nombreCompleto}',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.of(context).textSecondary),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: motivoController,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Motivo del rechazo',
                    hintText: 'Mínimo 10 caracteres',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 10)
                          ? 'Ingresa al menos 10 caracteres'
                          : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.of(context).error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, motivoController.text.trim());
              }
            },
            child: Text('Rechazar'),
          ),
        ],
      ),
    );

    motivoController.dispose();
    if (motivo == null || !mounted) return;

    try {
      await context
          .read<AdminProvider>()
          .rechazarSolicitud(s.solicitudId, motivo, _currentEstado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitud rechazada.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al rechazar la solicitud.'),
            backgroundColor: AppColors.of(context).error,
          ),
        );
      }
    }
  }
}

// ── Solicitud Card ────────────────────────────────────────────────────────────

class _SolicitudCard extends StatelessWidget {
  final SolicitudAdminModel solicitud;
  final bool showActions;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  _SolicitudCard({
    required this.solicitud,
    required this.showActions,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.personal.nombreCompleto,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.of(context).textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        solicitud.personal.correo,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.of(context).textSecondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                _RolChip(tipo: solicitud.personal.tipo),
              ],
            ),
            SizedBox(height: 14),
            Divider(height: 1),
            SizedBox(height: 14),
            _InfoRow(label: 'Número de cédula', value: solicitud.numeroCedula),
            SizedBox(height: 6),
            _InfoRow(
                label: 'Nombre en cédula', value: solicitud.nombreEnCedula),
            if (solicitud.especialidad != null) ...[
              SizedBox(height: 6),
              _InfoRow(
                  label: 'Especialidad', value: solicitud.especialidad!),
            ],
            SizedBox(height: 6),
            _InfoRow(
              label: 'Fecha de solicitud',
              value: _formatDate(solicitud.createdAt),
            ),
            if (solicitud.motivoRechazo != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.of(context).errorBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.of(context).errorBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.of(context).error, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Motivo del rechazo: ${solicitud.motivoRechazo}',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.of(context).error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (showActions) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRechazar,
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.of(context).error,
                      side: BorderSide(color: AppColors.of(context).error),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: onAprobar,
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.of(context).success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.day)}/${pad(d.month)}/${d.year} ${pad(d.hour)}:${pad(d.minute)}';
  }
}

class _RolChip extends StatelessWidget {
  final String tipo;
  _RolChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tipo) {
      'enfermera' => ('Enfermera', AppColors.of(context).success),
      'medico' => ('Doctor', Color(0xFF0D9488)),
      'admin' => ('Admin', Color(0xFFF97316)),
      _ => ('Free', AppColors.of(context).textSecondary),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).textMuted,
                fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 13, color: AppColors.of(context).textPrimary),
          ),
        ),
      ],
    );
  }
}
