import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PatientRegistrationPage extends StatefulWidget {
  const PatientRegistrationPage({super.key});

  @override
  State<PatientRegistrationPage> createState() => _PatientRegistrationPageState();
}

class _PatientRegistrationPageState extends State<PatientRegistrationPage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _idController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  String? _gender;
  String _vaccination = 'No';
  final List<bool> _symptoms = [false, false, false, false];

  static const _symptomLabels = ['Fiebre', 'Tos', 'Dolor Muscular', 'Fatiga'];
  static const _genderOptions = ['Masculino', 'Femenino', 'Otro'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _idController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveRecord() {
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Registro Manual de Paciente',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 14),
                  _buildClinicalDataCard(),
                  const SizedBox(height: 14),
                  _buildLocationCard(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildSaveButton(),
        ],
      ),
    );
  }

  // ── Section: Información Personal ────────────────────────────────────────

  Widget _buildPersonalInfoCard() {
    return _SectionCard(
      children: [
        _buildSectionHeader(Icons.person_outline_rounded, 'Información Personal'),
        _buildFieldLabel('Nombre Completo'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _nameController,
          hint: 'Ej. Juan Pérez',
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Edad'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _ageController,
                    hint: 'Años',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Género'),
                  const SizedBox(height: 6),
                  _buildGenderDropdown(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildFieldLabel('Número de Identidad (ID)'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _idController,
          hint: 'Ej. 000-000000-0000',
        ),
      ],
    );
  }

  // ── Section: Datos Clínicos ───────────────────────────────────────────────

  Widget _buildClinicalDataCard() {
    return _SectionCard(
      children: [
        _buildSectionHeader(Icons.medical_information_outlined, 'Datos Clínicos'),
        _buildFieldLabel('Síntomas Presentes'),
        const SizedBox(height: 10),
        _buildSymptomsGrid(),
        const SizedBox(height: 16),
        _buildFieldLabel('Vacunación Anterior'),
        const SizedBox(height: 4),
        _buildVaccinationRadios(),
        const SizedBox(height: 14),
        _buildFieldLabel('Notas Clínicas'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          maxLines: 4,
          decoration: _inputDecoration('Observaciones adicionales...'),
        ),
      ],
    );
  }

  Widget _buildSymptomsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SymptomCheckbox(label: _symptomLabels[0], value: _symptoms[0], onChanged: (v) => setState(() => _symptoms[0] = v!))),
            const SizedBox(width: 10),
            Expanded(child: _SymptomCheckbox(label: _symptomLabels[1], value: _symptoms[1], onChanged: (v) => setState(() => _symptoms[1] = v!))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _SymptomCheckbox(label: _symptomLabels[2], value: _symptoms[2], onChanged: (v) => setState(() => _symptoms[2] = v!))),
            const SizedBox(width: 10),
            Expanded(child: _SymptomCheckbox(label: _symptomLabels[3], value: _symptoms[3], onChanged: (v) => setState(() => _symptoms[3] = v!))),
          ],
        ),
      ],
    );
  }

  Widget _buildVaccinationRadios() {
    return RadioGroup<String>(
      groupValue: _vaccination,
      onChanged: (v) { if (v != null) setState(() => _vaccination = v); },
      child: Row(
        children: ['Sí', 'No'].map((option) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: option,
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Text(option, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(width: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Section: Ubicación ───────────────────────────────────────────────────

  Widget _buildLocationCard() {
    return _SectionCard(
      children: [
        _buildSectionHeader(Icons.location_on_outlined, 'Ubicación'),
        _buildFieldLabel('Dirección / Distrito'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _locationController,
          hint: 'Ej. Distrito Central, Sector 4',
        ),
      ],
    );
  }

  // ── Save Button ──────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return Container(
      color: const Color(0xFFF0F4F8),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _saveRecord,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.save_alt_rounded, size: 20),
          label: const Text(
            'Guardar Registro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      hint: const Text(
        'Seleccionar',
        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
      decoration: _inputDecoration('').copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: null,
      ),
      items: _genderOptions.map((g) {
        return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)));
      }).toList(),
      onChanged: (v) => setState(() => _gender = v),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.inputBackground,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

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

class _SymptomCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _SymptomCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: value ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
