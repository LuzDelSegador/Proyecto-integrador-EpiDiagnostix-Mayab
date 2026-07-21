import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../patients/data/mappers/sexo_mapper.dart';
import '../../../patients/data/repositories/patient_local_repository.dart';
import '../../../plans/presentation/pages/planes_page.dart';
import '../../../sync/data/sync_service.dart';
import 'new_patient_selection_page.dart';

/// Alta/identidad de paciente (MS1): captura CURP y los datos que exige
/// POST /pacientes. Es el paso obligatorio antes de capturar cualquier
/// consulta — la identidad ya no se resuelve por nombre.
class PatientRegistrationPage extends StatefulWidget {
  PatientRegistrationPage({super.key});

  @override
  State<PatientRegistrationPage> createState() => _PatientRegistrationPageState();
}

class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _curpController = TextEditingController();
  final _comunidadController = TextEditingController();
  final _municipioController = TextEditingController();
  final _lenguaController = TextEditingController();
  final _contactoController = TextEditingController();

  String? _sexo; // kSexoHombre | kSexoMujer
  DateTime? _fechaNacimiento;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _curpController.dispose();
    _comunidadController.dispose();
    _municipioController.dispose();
    _lenguaController.dispose();
    _contactoController.dispose();
    super.dispose();
  }

  Future<void> _pickFechaNacimiento() async {
    final ahora = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: DateTime(ahora.year - 30),
      firstDate: DateTime(1900),
      lastDate: ahora,
      helpText: 'Fecha de nacimiento',
    );
    if (elegida != null) setState(() => _fechaNacimiento = elegida);
  }

  String _formatFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _handleGuardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sexo == null) {
      setState(() => _errorText = 'Selecciona el sexo del paciente.');
      return;
    }
    if (_fechaNacimiento == null) {
      setState(() => _errorText = 'Selecciona la fecha de nacimiento.');
      return;
    }

    setState(() { _isLoading = true; _errorText = null; });

    final curp = _curpController.text.trim().toUpperCase();
    final repo = sl<PatientLocalRepository>();

    // Límite del plan Free (5 pacientes) — solo aplica si es un paciente
    // nuevo de verdad; reingresar el mismo CURP nunca cuenta como nuevo.
    if (!mounted) return;
    final role = context.read<AuthProvider>().currentRole;
    if (role == UserRole.usuario) {
      final existentes = await repo.getPacientes(null);
      final yaExiste = existentes.any((r) => r.paciente.curp == curp);
      if (!yaExiste && existentes.length >= 5) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showLimitBottomSheet();
        return;
      }
    }

    try {
      final paciente = await repo.crearOEncontrarPacientePorCurp(
        curp: curp,
        nombreCompleto: _nameController.text.trim(),
        fechaNacimiento: _formatFecha(_fechaNacimiento!),
        sexo: _sexo!,
        comunidad: _comunidadController.text.trim(),
        municipio: _municipioController.text.trim(),
        lenguaMaterna: _lenguaController.text.trim().isEmpty ? null : _lenguaController.text.trim(),
        contactoEmergencia: _contactoController.text.trim().isEmpty ? null : _contactoController.text.trim(),
      );

      // Fire-and-forget: si hay red, empuja el alta a MS1 en segundo plano.
      // Si falla (sin red, cold-start), el paciente ya quedó en SQLite y se
      // reintentará en el próximo trigger de sincronización.
      sl<SyncService>().syncAll().catchError((_) => SyncResumen());

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NewPatientSelectionPage(
            pacienteId: paciente.id,
            pacienteNombre: paciente.nombreCompleto,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'No se pudo guardar el paciente. Intenta de nuevo.';
      });
    }
  }

  void _showLimitBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Icon(Icons.lock_outline_rounded, size: 48, color: Color(0xFFD97706)),
            SizedBox(height: 14),
            Text(
              'Límite del plan Free alcanzado',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Has alcanzado el límite del plan Free (5 pacientes).\nActualiza tu plan para registros ilimitados.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PlanesPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.of(context).primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Ver planes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.of(context).primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Datos del Paciente',
          style: TextStyle(color: AppColors.of(context).primary, fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    _buildIdentidadCard(),
                    SizedBox(height: 14),
                    _buildUbicacionCard(),
                    if (_errorText != null) ...[
                      SizedBox(height: 12),
                      _buildErrorBanner(),
                    ],
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ── Section: Identidad ──────────────────────────────────────────────────

  Widget _buildIdentidadCard() {
    return _SectionCard(
      children: [
        _buildSectionHeader(Icons.badge_outlined, 'Identidad del Paciente'),
        _buildFieldLabel('Nombre Completo'),
        SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration('Ej. Juan Gómez'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre completo' : null,
        ),
        SizedBox(height: 14),
        _buildFieldLabel('CURP'),
        SizedBox(height: 6),
        TextFormField(
          controller: _curpController,
          textCapitalization: TextCapitalization.characters,
          maxLength: 18,
          decoration: _inputDecoration('18 caracteres').copyWith(counterText: ''),
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return 'Ingresa el CURP';
            if (val.length != 18) return 'El CURP debe tener 18 caracteres';
            return null;
          },
        ),
        SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Fecha de Nacimiento'),
                  SizedBox(height: 6),
                  _buildFechaField(),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Sexo'),
                  SizedBox(height: 6),
                  _buildSexoDropdown(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFechaField() {
    return InkWell(
      onTap: _pickFechaNacimiento,
      child: InputDecorator(
        decoration: _inputDecoration('Seleccionar'),
        child: Text(
          _fechaNacimiento != null ? _formatFecha(_fechaNacimiento!) : 'Seleccionar',
          style: TextStyle(
            fontSize: 13,
            color: _fechaNacimiento != null ? AppColors.of(context).textPrimary : AppColors.of(context).textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSexoDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _sexo,
      hint: Text('Seleccionar', style: TextStyle(color: AppColors.of(context).textMuted, fontSize: 13)),
      decoration: _inputDecoration('').copyWith(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: null,
      ),
      items: [
        DropdownMenuItem(value: kSexoHombre, child: Text('Hombre', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: kSexoMujer, child: Text('Mujer', style: TextStyle(fontSize: 13))),
      ],
      onChanged: (v) => setState(() => _sexo = v),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.of(context).textMuted),
    );
  }

  // ── Section: Ubicación y contacto ─────────────────────────────────────────

  Widget _buildUbicacionCard() {
    return _SectionCard(
      children: [
        _buildSectionHeader(Icons.location_on_outlined, 'Ubicación y Contacto'),
        _buildFieldLabel('Municipio'),
        SizedBox(height: 6),
        TextFormField(
          controller: _municipioController,
          decoration: _inputDecoration('Ej. Suchiapa'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el municipio' : null,
        ),
        SizedBox(height: 14),
        _buildFieldLabel('Comunidad'),
        SizedBox(height: 6),
        TextFormField(
          controller: _comunidadController,
          decoration: _inputDecoration('Ej. Suchiapa (opcional)'),
        ),
        SizedBox(height: 14),
        _buildFieldLabel('Lengua Materna'),
        SizedBox(height: 6),
        TextFormField(
          controller: _lenguaController,
          decoration: _inputDecoration('Ej. Tzotzil (opcional)'),
        ),
        SizedBox(height: 14),
        _buildFieldLabel('Contacto de Emergencia'),
        SizedBox(height: 6),
        TextFormField(
          controller: _contactoController,
          keyboardType: TextInputType.phone,
          decoration: _inputDecoration('Teléfono (opcional)'),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.of(context).errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.of(context).errorBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.of(context).error, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(_errorText!, style: TextStyle(color: AppColors.of(context).error, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Save Button ──────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Container(
      color: AppColors.of(context).background,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleGuardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.of(context).primary,
            disabledBackgroundColor: AppColors.of(context).primary.withValues(alpha: 0.45),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: _isLoading
              ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Icon(Icons.save_alt_rounded, size: 20),
          label: Text(
            _isLoading ? 'Guardando (puede tardar si el servidor está dormido)...' : 'Continuar',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.of(context).primary, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: AppColors.of(context).primary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.of(context).inputBackground,
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.of(context).textMuted, fontSize: 13),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.of(context).border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.of(context).border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.of(context).primary, width: 1.5),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
