import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/models/patient_record.dart';
import '../../data/repositories/patient_local_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../plans/presentation/pages/planes_page.dart';

class AudioConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> clinicalFields;
  final String originalText;

  const AudioConfirmationPage({
    super.key,
    required this.clinicalFields,
    required this.originalText,
  });

  @override
  State<AudioConfirmationPage> createState() => _AudioConfirmationPageState();
}

class _AudioConfirmationPageState extends State<AudioConfirmationPage> {
  bool _isEditing = false;

  // ── Perfil del paciente ────────────────────────────────────────────────────
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;
  late final TextEditingController _locationController;

  // ── Datos clínicos vitales ─────────────────────────────────────────────────
  late final TextEditingController _categoryController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;
  late final TextEditingController _glucoseController;
  late final TextEditingController _tempController;
  late final TextEditingController _heartRateController;
  late final TextEditingController _durationController;

  bool _detected(String key) => widget.clinicalFields.containsKey(key);

  @override
  void initState() {
    super.initState();
    final f = widget.clinicalFields;

    _nameController     = TextEditingController(text: '');
    _ageController      = TextEditingController(text: f['edad']?.toString() ?? '');
    _genderController   = TextEditingController(
      text: f['sexo'] == 'M'
          ? 'Masculino'
          : f['sexo'] == 'F'
              ? 'Femenino'
              : '',
    );
    _locationController = TextEditingController(text: '');

    _categoryController  = TextEditingController(text: f['categoria_sintoma']?.toString() ?? '');
    _weightController    = TextEditingController(text: f['peso_kg']?.toString() ?? '');
    _heightController    = TextEditingController(text: f['talla_cm']?.toString() ?? '');
    _systolicController  = TextEditingController(text: f['presion_sistolica']?.toString() ?? '');
    _diastolicController = TextEditingController(text: f['presion_diastolica']?.toString() ?? '');
    _glucoseController   = TextEditingController(text: f['glucosa_mg_dl']?.toString() ?? '');
    _tempController      = TextEditingController(text: f['temperatura_c']?.toString() ?? '');
    _heartRateController = TextEditingController(text: f['frecuencia_cardiaca_bpm']?.toString() ?? '');
    _durationController  = TextEditingController(text: f['duracion_sintomas_dias']?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    _tempController.dispose();
    _heartRateController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  // ── Paso 3: buscar/crear paciente y guardar consulta en SQLite ───────────

  static String _normSimple(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<void> _saveAndSync() async {
    final nombre    = _nameController.text.trim();
    final localidad = _locationController.text.trim();

    if (nombre.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingrese el nombre del paciente'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Verificar límite de 5 pacientes para rol usuario
    if (!mounted) return;
    final role = context.read<AuthProvider>().currentRole;
    if (role == UserRole.usuario) {
      final repo  = sl<PatientLocalRepository>();
      final todos = await repo.getPacientes(null);
      final normNuevo  = _normSimple(nombre);
      final existeYa   = todos.any(
        (r) => _normSimple(r.paciente.nombreCompleto) == normNuevo,
      );
      if (!existeYa && todos.length >= 5) {
        if (!mounted) return;
        _showLimitBottomSheet();
        return;
      }
    }

    final sexo = widget.clinicalFields['sexo'] as String?;
    bool saved = false;
    try {
      final repo     = sl<PatientLocalRepository>();
      final paciente = await repo.buscarOCrearPaciente(nombre, sexo, localidad);
      await repo.guardarConsulta(
        paciente.id,
        PatientRecord(
          textoOriginal:   widget.originalText,
          camposExtraidos: widget.clinicalFields,
          fechaCaptura:    DateTime.now(),
        ),
      );
      saved = true;
    } catch (_) {}

    if (!mounted) return;

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No se pudo guardar el registro. Intenta de nuevo.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Consulta guardada',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showLimitBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: Color(0xFFD97706),
            ),
            const SizedBox(height: 14),
            const Text(
              'Límite del plan Free alcanzado',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Has alcanzado el límite del plan Free (5 pacientes).\nActualiza tu plan para registros ilimitados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PlanesPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Ver planes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(),
                  const SizedBox(height: 16),
                  _buildPatientCard(),
                  const SizedBox(height: 14),
                  _buildClinicalCard(),
                  const SizedBox(height: 14),
                  _buildVitalsCard(),
                  const SizedBox(height: 14),
                  _buildLocationCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const Icon(Icons.monitor_heart_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'EpiSurveillance',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'HW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Page header ───────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmación de Datos (IA)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Transcripción completada con éxito',
                style: TextStyle(
                  color: AppColors.success,
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

  // ── Card: Perfil del Paciente ─────────────────────────────────────────────

  Widget _buildPatientCard() {
    return _Card(
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Perfil del Paciente',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleEdit,
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isEditing ? 'Listo' : 'Editar',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildField('Nombre Completo', _nameController, isDetected: false, alwaysEditable: true),
        const SizedBox(height: 12),
        _buildField('Edad', _ageController, isDetected: _detected('edad')),
        const SizedBox(height: 12),
        _buildField('Género', _genderController, isDetected: _detected('sexo')),
      ],
    );
  }

  // ── Card: Análisis Clínico (IA) ───────────────────────────────────────────

  Widget _buildClinicalCard() {
    final detectedCount = widget.clinicalFields.length;
    return _Card(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.biotech_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Análisis Clínico (IA)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$detectedCount / 11\ncampos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Categoría de Síntoma',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        _isEditing
            ? _buildField('Categoría', _categoryController, isDetected: _detected('categoria_sintoma'))
            : _detected('categoria_sintoma')
                ? _CategoryChip(label: _categoryController.text)
                : const _UndetectedRow(label: 'Categoría no detectada'),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.thermostat_rounded, color: AppColors.primary, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temperatura (°C)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  _isEditing
                      ? _buildInlineField(_tempController)
                      : _detected('temperatura_c')
                          ? Text(
                              '${_tempController.text} °C',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : const _UndetectedRow(label: 'No detectada'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duración síntomas (días)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  _isEditing
                      ? _buildInlineField(_durationController)
                      : _detected('duracion_sintomas_dias')
                          ? Text(
                              '${_durationController.text} días',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : const _UndetectedRow(label: 'No detectada'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_outlined, color: AppColors.textMuted, size: 17),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de Sincronización',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                SizedBox(height: 3),
                Text(
                  'Listo para envío local',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Card: Datos Clínicos Vitales ──────────────────────────────────────────

  Widget _buildVitalsCard() {
    return _Card(
      children: [
        const Row(
          children: [
            Icon(Icons.monitor_heart_outlined, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Datos Clínicos Vitales',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField('Peso (kg)', _weightController,
                  isDetected: _detected('peso_kg')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField('Talla (cm)', _heightController,
                  isDetected: _detected('talla_cm')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField('Presión Sistólica', _systolicController,
                  isDetected: _detected('presion_sistolica')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField('Presión Diastólica', _diastolicController,
                  isDetected: _detected('presion_diastolica')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField('Glucosa (mg/dL)', _glucoseController,
                  isDetected: _detected('glucosa_mg_dl')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField('Frec. Cardíaca (bpm)', _heartRateController,
                  isDetected: _detected('frecuencia_cardiaca_bpm')),
            ),
          ],
        ),
      ],
    );
  }

  // ── Card: Ubicación + mini mapa ───────────────────────────────────────────

  Widget _buildLocationCard() {
    return _Card(
      children: [
        const Row(
          children: [
            Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Ubicación',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildField('Localidad', _locationController, isDetected: false, alwaysEditable: true),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 110,
            width: double.infinity,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(double.infinity, 110),
                  painter: _MiniMapPainter(),
                ),
                const Positioned(
                  bottom: 6,
                  left: 8,
                  child: Text(
                    'COORD: -12.1092, -77.0067',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _saveAndSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.sync_rounded, size: 18),
            label: const Text(
              'Guardar y Sincronizar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _toggleEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              _isEditing ? Icons.check_circle_outline_rounded : Icons.edit_outlined,
              size: 18,
            ),
            label: Text(
              _isEditing ? 'Confirmar Cambios' : 'Editar Manualmente',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.mic_none_rounded, size: 18),
            label: const Text(
              'Grabar de Nuevo',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildField(String label, TextEditingController controller,
      {bool isDetected = true, bool alwaysEditable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        (alwaysEditable || _isEditing)
            ? TextFormField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              )
            : isDetected
                ? Text(
                    controller.text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  )
                : const _UndetectedRow(),
      ],
    );
  }

  // Variante compacta para campos dentro de filas (temperatura, duración).
  Widget _buildInlineField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ── Reusable card ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ── "No detectado" row ────────────────────────────────────────────────────────

class _UndetectedRow extends StatelessWidget {
  final String label;
  const _UndetectedRow({this.label = 'No detectado'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.help_outline, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined, color: AppColors.primary, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini map painter ──────────────────────────────────────────────────────────

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D1B2A),
    );

    final streetPaint = Paint()
      ..color = const Color(0xFF1B6E52).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final mainStreetPaint = Paint()
      ..color = const Color(0xFF1B6E52).withValues(alpha: 0.8)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final hLines = [0.18, 0.38, 0.55, 0.72, 0.88];
    for (final t in hLines) {
      canvas.drawLine(
        Offset(0, size.height * t),
        Offset(size.width, size.height * t),
        t == 0.38 || t == 0.72 ? mainStreetPaint : streetPaint,
      );
    }

    final vLines = [0.12, 0.28, 0.44, 0.6, 0.76, 0.9];
    for (final t in vLines) {
      canvas.drawLine(
        Offset(size.width * t, 0),
        Offset(size.width * t, size.height),
        t == 0.28 || t == 0.6 ? mainStreetPaint : streetPaint,
      );
    }

    final dotX = size.width * 0.5;
    final dotY = size.height * 0.45;

    canvas.drawCircle(
      Offset(dotX, dotY),
      14,
      Paint()..color = AppColors.primary.withValues(alpha: 0.18),
    );
    canvas.drawCircle(Offset(dotX, dotY), 5, Paint()..color = AppColors.primary);
    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
