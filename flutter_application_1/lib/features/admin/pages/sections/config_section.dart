import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_config.dart';

class ConfigSection extends StatelessWidget {
  const ConfigSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración del sistema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Para modificar estos valores, edita app_config.dart y recompila el panel.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ConfigItem(
                    label: 'Backend MS1 (Auth / Pacientes)',
                    value: kBaseUrlAuth,
                    icon: Icons.dns_outlined,
                    onCopy: () => _copy(context, kBaseUrlAuth, 'URL copiada'),
                  ),
                  const Divider(height: 28),
                  _ConfigItem(
                    label: 'Backend MS2 (NER / Isolation Forest)',
                    value: kBaseUrlML,
                    icon: Icons.psychology_outlined,
                    onCopy: () => _copy(context, kBaseUrlML, 'URL copiada'),
                  ),
                  const Divider(height: 28),
                  _ConfigItem(
                    label: 'Clave Stripe (test)',
                    value: kStripePublishableKey,
                    icon: Icons.credit_card_outlined,
                    onCopy: () => _copy(
                        context, kStripePublishableKey, 'Clave copiada'),
                    monospace: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Los cambios de configuración requieren recompilar el panel '
                    '(flutter build web --target lib/main_admin.dart) y volver a '
                    'desplegar los archivos en el servidor.',
                    style: TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(label),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 240,
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onCopy;
  final bool monospace;

  const _ConfigItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.onCopy,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontFamily: monospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_outlined, size: 18),
          tooltip: 'Copiar',
          color: AppColors.textMuted,
        ),
      ],
    );
  }
}
