import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AudioConfirmationPage extends StatefulWidget {
  const AudioConfirmationPage({super.key});

  @override
  State<AudioConfirmationPage> createState() => _AudioConfirmationPageState();
}

class _AudioConfirmationPageState extends State<AudioConfirmationPage> {
  bool _isEditing = false;

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Juan Pérez');
    _ageController = TextEditingController(text: '45 años');
    _genderController = TextEditingController(text: 'Masculino');
    _locationController = TextEditingController(text: 'San Borja, Lima');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveAndSync() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Registro guardado con éxito',
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
        _buildField('Nombre Completo', _nameController),
        const SizedBox(height: 12),
        _buildField('Edad', _ageController),
        const SizedBox(height: 12),
        _buildField('Género', _genderController),
      ],
    );
  }

  // ── Card: Análisis Clínico (IA) ───────────────────────────────────────────

  Widget _buildClinicalCard() {
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
              child: const Text(
                'Confianza:\n96%',
                style: TextStyle(
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
          'Síntomas Detectados',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _SymptomTag(
              icon: Icons.thermostat_rounded,
              color: Color(0xFFDC2626),
              name: 'Fiebre',
              intensity: 'ALTA',
            ),
            _SymptomTag(
              icon: Icons.air_rounded,
              color: Color(0xFF2563EB),
              name: 'Tos Seca',
              intensity: 'PERSISTENTE',
            ),
            _SymptomTag(
              icon: Icons.fitness_center_rounded,
              color: Color(0xFFD97706),
              name: 'Dolor Muscular',
              intensity: 'MODERADO',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.vaccines_outlined, color: AppColors.primary, size: 17),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vacunación Previa',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                SizedBox(height: 3),
                Text(
                  'Esquema Completo (Verificado)',
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
        _buildField('Distrito Detectado', _locationController),
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

  Widget _buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        _isEditing
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
            : Text(
                controller.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
      ],
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

// ── Symptom tag chip ──────────────────────────────────────────────────────────

class _SymptomTag extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final String intensity;

  const _SymptomTag({
    required this.icon,
    required this.color,
    required this.name,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                intensity,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
            ],
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
    // Background
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

    // Horizontal streets
    final hLines = [0.18, 0.38, 0.55, 0.72, 0.88];
    for (final t in hLines) {
      canvas.drawLine(
        Offset(0, size.height * t),
        Offset(size.width, size.height * t),
        t == 0.38 || t == 0.72 ? mainStreetPaint : streetPaint,
      );
    }

    // Vertical streets
    final vLines = [0.12, 0.28, 0.44, 0.6, 0.76, 0.9];
    for (final t in vLines) {
      canvas.drawLine(
        Offset(size.width * t, 0),
        Offset(size.width * t, size.height),
        t == 0.28 || t == 0.6 ? mainStreetPaint : streetPaint,
      );
    }

    // Location dot
    final dotX = size.width * 0.5;
    final dotY = size.height * 0.45;

    canvas.drawCircle(
      Offset(dotX, dotY),
      14,
      Paint()..color = AppColors.primary.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()..color = AppColors.primary,
    );
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
