import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../pages/patient_picker_page.dart';
import '../pages/patient_registration_page.dart';

/// Bottom sheet mostrado al tocar el "+" global (sin contexto de paciente):
/// obliga a elegir entre capturar un paciente nuevo o reutilizar uno ya
/// registrado, antes de navegar a cualquier formulario.
Future<void> showAddCaseChoiceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.of(context).surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AddCaseChoiceSheet(),
  );
}

class _AddCaseChoiceSheet extends StatelessWidget {
  const _AddCaseChoiceSheet();

  @override
  Widget build(BuildContext context) {
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
              'Agregar Caso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '¿Sobre qué paciente deseas capturar la consulta?',
              style: TextStyle(fontSize: 13, color: AppColors.of(context).textSecondary),
            ),
            SizedBox(height: 20),
            _ChoiceTile(
              icon: Icons.person_add_alt_1_rounded,
              iconColor: AppColors.of(context).primary,
              title: 'Nuevo paciente',
              subtitle: 'Captura nombre, CURP, fecha de nacimiento y demás datos de identidad.',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PatientRegistrationPage()),
                );
              },
            ),
            SizedBox(height: 12),
            _ChoiceTile(
              icon: Icons.groups_rounded,
              iconColor: Color(0xFF0EA5E9),
              title: 'Paciente existente',
              subtitle: 'Busca a un paciente ya registrado y captura su nueva consulta.',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PatientPickerPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.of(context).background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.of(context).border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.of(context).textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.of(context).textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.of(context).textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
