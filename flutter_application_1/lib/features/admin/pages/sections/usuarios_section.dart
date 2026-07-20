import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/admin_provider.dart';
import '../../data/admin_models.dart';

class UsuariosSection extends StatefulWidget {
  const UsuariosSection({super.key});

  @override
  State<UsuariosSection> createState() => _UsuariosSectionState();
}

class _UsuariosSectionState extends State<UsuariosSection> {
  String? _selectedTipo; // null = Todos

  static const _filters = [
    (label: 'Todos', tipo: null),
    (label: 'Free', tipo: 'usuario'),
    (label: 'Enfermera', tipo: 'enfermera'),
    (label: 'Doctor', tipo: 'medico'),
    (label: 'Admin', tipo: 'admin'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsuarios(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterRow(),
        const Divider(height: 1),
        Expanded(child: _buildBody(provider)),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Wrap(
        spacing: 8,
        children: _filters.map((f) {
          final selected = _selectedTipo == f.tipo;
          return FilterChip(
            label: Text(f.label),
            selected: selected,
            onSelected: (_) {
              setState(() => _selectedTipo = f.tipo);
              context.read<AdminProvider>().loadUsuarios(f.tipo);
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
            labelStyle: TextStyle(
              fontSize: 13,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(AdminProvider provider) {
    if (provider.loadingUsuarios) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.usuariosError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(provider.usuariosError!,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  context.read<AdminProvider>().loadUsuarios(_selectedTipo),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (provider.usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 48,
                color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('Sin usuarios para este filtro.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: provider.usuarios.length,
      itemBuilder: (context, i) =>
          _UsuarioCard(usuario: provider.usuarios[i]),
    );
  }
}

// ── Usuario Card ──────────────────────────────────────────────────────────────

class _UsuarioCard extends StatelessWidget {
  final UsuarioAdminModel usuario;

  const _UsuarioCard({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  _roleColor(usuario.tipo).withValues(alpha: 0.15),
              child: Text(
                usuario.nombreCompleto.isNotEmpty
                    ? usuario.nombreCompleto[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _roleColor(usuario.tipo),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usuario.correo,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _RolChip(tipo: usuario.tipo),
            const SizedBox(width: 24),
            Text(
              _formatDateShort(usuario.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String tipo) => switch (tipo) {
        'enfermera' => AppColors.success,
        'medico' => const Color(0xFF0D9488),
        'admin' => const Color(0xFFF97316),
        _ => AppColors.textSecondary,
      };

  String _formatDateShort(DateTime dt) {
    final d = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.day)}/${pad(d.month)}/${d.year}';
  }
}

class _RolChip extends StatelessWidget {
  final String tipo;
  const _RolChip({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tipo) {
      'enfermera' => ('Enfermera', AppColors.success),
      'medico' => ('Doctor', const Color(0xFF0D9488)),
      'admin' => ('Admin', const Color(0xFFF97316)),
      _ => ('Free', AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
