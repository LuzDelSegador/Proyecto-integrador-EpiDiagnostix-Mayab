import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/paciente.dart';
import '../../data/repositories/patient_local_repository.dart';
import 'new_patient_selection_page.dart';

/// Selector de paciente ya registrado (Caso A, opción "Paciente existente"):
/// busca/lista los pacientes que ya están en SQLite local y, al elegir uno,
/// salta directo a Método de Entrada — sin repetir captura de identidad.
class PatientPickerPage extends StatefulWidget {
  PatientPickerPage({super.key});

  @override
  State<PatientPickerPage> createState() => _PatientPickerPageState();
}

class _PatientPickerPageState extends State<PatientPickerPage> {
  final _searchController = TextEditingController();
  List<PacienteConResumen> _pacientes = [];
  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPacientes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 300), _loadPacientes);
  }

  Future<void> _loadPacientes() async {
    final filtro = _searchController.text.trim();
    final lista = await sl<PatientLocalRepository>()
        .getPacientes(filtro.isEmpty ? null : filtro);
    if (mounted) {
      setState(() {
        _pacientes = lista;
        _isLoading = false;
      });
    }
  }

  void _seleccionar(Paciente p) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewPatientSelectionPage(
          pacienteId: p.id,
          pacienteNombre: p.nombreCompleto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        title: Text(
          'Seleccionar Paciente',
          style: TextStyle(
            color: AppColors.of(context).textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.of(context).surface,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.of(context).inputBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: false,
          style: TextStyle(fontSize: 13, color: AppColors.of(context).textPrimary),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre',
            hintStyle: TextStyle(color: AppColors.of(context).textMuted, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.of(context).textMuted, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_pacientes.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _pacientes.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
      itemBuilder: (_, i) => _buildPacienteCard(_pacientes[i]),
    );
  }

  Widget _buildEmptyState() {
    final buscando = _searchController.text.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded,
                size: 56, color: AppColors.of(context).textMuted.withValues(alpha: 0.5)),
            SizedBox(height: 16),
            Text(
              buscando
                  ? 'Ningún paciente coincide con esa búsqueda.'
                  : 'No hay pacientes registrados aún.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.of(context).textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Paciente card ─────────────────────────────────────────────────────────

  Widget _buildPacienteCard(PacienteConResumen r) {
    final p = r.paciente;

    return GestureDetector(
      onTap: () => _seleccionar(p),
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.of(context).primary.withValues(alpha: 0.1),
                child: Text(
                  _initials(p.nombreCompleto),
                  style: TextStyle(
                    color: AppColors.of(context).primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombreCompleto,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    if (p.comunidad != null && p.comunidad!.isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        p.comunidad!,
                        style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary),
                      ),
                    ],
                    SizedBox(height: 6),
                    Text(
                      '${p.totalVisitas} visita${p.totalVisitas == 1 ? '' : 's'} en total · '
                      'última vez: ${_formatDate(p.ultimaVisita)}',
                      style: TextStyle(fontSize: 12, color: AppColors.of(context).textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.of(context).textMuted, size: 20),
            ],
          ),
        ),
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
