import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/user_roles.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/plan_service.dart';
import 'cedula_solicitud_page.dart';

// ── Constantes visuales ───────────────────────────────────────────────────────

const _kColorIntermedioBadge = Color(0xFF059669);
const _kColorPremiumBg       = Color(0xFF1A1A2E);
const _kColorHipaa           = Color(0xFF7C3AED);

class PlanesPage extends StatefulWidget {
  const PlanesPage({super.key});

  @override
  State<PlanesPage> createState() => _PlanesPageState();
}

class _PlanesPageState extends State<PlanesPage> {
  bool _isProcessing = false;

  // Carga al abrir la página; null = sin solicitud, non-null = solicitud existente.
  late final Future<SolicitudResult?> _solicitudFuture;

  @override
  void initState() {
    super.initState();
    _solicitudFuture = di.sl<PlanService>().getMiSolicitud();
  }

  // ── Flujo Stripe ──────────────────────────────────────────────────────────

  void _showPaymentConfirmation(String planName, String precio, String correo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentConfirmationSheet(
        planName: planName,
        precio: precio,
        onConfirmar: () {
          Navigator.of(context).pop();
          _iniciarPago(planName, precio, correo);
        },
      ),
    );
  }

  Future<void> _iniciarPago(String planName, String precio, String correo) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // TODO: Reemplazar clientSecret hardcodeado por llamada a
      // POST /payments/create-intent en el backend, que devuelve
      // { "client_secret": "pi_XXXX_secret_YYYY", "amount": XXXX, "currency": "mxn" }.
      // Body: { "price_id": kPriceIdIntermedio | kPriceIdPremium, "correo": correo }
      const clientSecret = 'pi_3test_secret_test';

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'EpiDiagnostix Mayab',
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF1B6E52),
            ),
            shapes: PaymentSheetShape(borderRadius: 10),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        setState(() => _isProcessing = false);
        return;
      }
    } catch (_) {
      // clientSecret inválido o red → flujo demo
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);
    _showDemoSuccess(planName, correo);
  }

  void _showDemoSuccess(String planName, String correo) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DemoSuccessSheet(planName: planName, correo: correo),
    );
  }

  // ── Flujo cédula ──────────────────────────────────────────────────────────

  void _irACedulaSolicitud() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CedulaSolicitudPage()),
    );
  }

  void _showEstadoSolicitud(SolicitudResult solicitud) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EstadoSolicitudSheet(solicitud: solicitud),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final role   = context.read<AuthProvider>().currentRole;
    final correo = context.read<AuthProvider>().currentUser.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildStatsBanner(),
                const SizedBox(height: 20),

                // ── Cards de plan ──────────────────────────────────────────
                if (role == UserRole.usuario) ...[
                  _FreePlanCard(),
                  const SizedBox(height: 14),
                ],
                if (role != UserRole.medico) ...[
                  _IntermedioPlanCard(
                    isCurrentPlan: role == UserRole.enfermera,
                    onAdquirir: () => _showPaymentConfirmation(
                      'Intermedio', r'$49/mes', correo,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Premium: envuelto en FutureBuilder para el indicador de solicitud
                FutureBuilder<SolicitudResult?>(
                  future: _solicitudFuture,
                  builder: (_, snap) {
                    final pendiente = snap.connectionState == ConnectionState.done &&
                        !snap.hasError &&
                        snap.data?.estado == 'pendiente';
                    return _PremiumPlanCard(
                      isCurrentPlan: role == UserRole.medico,
                      solicitudPendiente: pendiente,
                      onAdquirir: () => _irACedulaSolicitud(),
                      onVerEstado: pendiente && snap.data != null
                          ? () => _showEstadoSolicitud(snap.data!)
                          : null,
                    );
                  },
                ),

                const SizedBox(height: 28),
                _buildHipaaBadge(),
                const SizedBox(height: 24),
                _buildFaq(),
                const SizedBox(height: 24),
                _buildStripeBadge(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  // ── Widgets de la pantalla ─────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      title: const Text(
        'Planes y Precios',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sincronizado con el Nodo Central de Salud',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'EN LÍNEA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B6E52), Color(0xFF0D4F3C)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('94%', 'Precisión IA'),
          _divider(),
          _statItem('Offline', 'First'),
          _divider(),
          _statItem('IA', 'Módulo activo'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 32, color: Colors.white24);

  Widget _buildHipaaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kColorHipaa.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kColorHipaa.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: _kColorHipaa, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIPAA Compliant',
                  style: TextStyle(
                    color: _kColorHipaa,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Text(
                  'Datos cifrados en tránsito y en reposo conforme a NOM-024-SSA3.',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaq() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preguntas frecuentes',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        _faqTile(
          '¿Los pagos son seguros?',
          'Sí. Los pagos son procesados por Stripe (PCI DSS Nivel 1). Nunca almacenamos datos de tu tarjeta en nuestros servidores.',
        ),
        _faqTile(
          '¿Puedo cancelar mi suscripción en cualquier momento?',
          'Sí. Tu plan seguirá activo hasta el final del período pagado y no se hará ningún cargo adicional.',
        ),
        _faqTile(
          '¿El plan Premium requiere cédula profesional?',
          'Sí. Para garantizar que el mapa epidemiológico lo usen profesionales certificados, solicitamos tu cédula durante la activación. El equipo la verificará en menos de 48 horas hábiles.',
        ),
      ],
    );
  }

  Widget _faqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textMuted,
        title: Text(
          question,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildStripeBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pagos procesados de forma segura por Stripe. Tus datos bancarios nunca se almacenan en nuestros servidores.',
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan Cards ────────────────────────────────────────────────────────────────

class _FreePlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _BasePlanCard(
      name: 'Free',
      priceLabel: r'$0',
      priceSuffix: '/mes',
      badgeLabel: 'ACTUAL',
      badgeColor: AppColors.textMuted,
      features: const [
        'Hasta 5 pacientes',
        'Registro de consultas manual',
        'Historial local',
      ],
      locked: const [
        'Transcripción por voz (IA)',
        'Detección de anomalías ML',
        'Mapa epidemiológico',
      ],
      cta: const _CtaDisabled(label: '✓ Tu plan actual'),
    );
  }
}

class _IntermedioPlanCard extends StatelessWidget {
  final bool isCurrentPlan;
  final VoidCallback onAdquirir;

  const _IntermedioPlanCard({
    required this.isCurrentPlan,
    required this.onAdquirir,
  });

  @override
  Widget build(BuildContext context) {
    return _BasePlanCard(
      highlighted: true,
      name: 'Intermedio',
      subtitle: 'Enfermera / Paramédico',
      priceLabel: r'$49',
      priceSuffix: '/mes',
      badgeLabel: 'RECOMENDADO',
      badgeColor: _kColorIntermedioBadge,
      features: const [
        'Pacientes ilimitados',
        'Transcripción por voz (Whisper + IA)',
        'Detección de anomalías ML',
        'Historial de consultas completo',
      ],
      locked: const ['Mapa epidemiológico interactivo'],
      cta: isCurrentPlan
          ? const _CtaDisabled(label: '✓ Tu plan actual')
          : _CtaEnabled(
              label: r'Adquirir por $49/mes',
              color: _kColorIntermedioBadge,
              onTap: onAdquirir,
            ),
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  final bool isCurrentPlan;
  final bool solicitudPendiente;
  final VoidCallback onAdquirir;
  final VoidCallback? onVerEstado;

  const _PremiumPlanCard({
    required this.isCurrentPlan,
    required this.solicitudPendiente,
    required this.onAdquirir,
    this.onVerEstado,
  });

  @override
  Widget build(BuildContext context) {
    Widget cta;
    Widget? footer;

    if (isCurrentPlan) {
      cta = const _CtaDisabled(label: '✓ Tu plan actual', dark: true);
    } else if (solicitudPendiente) {
      cta = SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton(
          onPressed: onVerEstado,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(
            'Ver estado de mi solicitud',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      );
      footer = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Text('⏳', style: TextStyle(fontSize: 14)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Solicitud en revisión · Menos de 48 horas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      cta = _CtaEnabled(
        label: r'Adquirir por $129/mes',
        color: Colors.white,
        textColor: _kColorPremiumBg,
        onTap: onAdquirir,
      );
    }

    return _BasePlanCard(
      darkTheme: true,
      name: 'Premium',
      subtitle: 'Médico Certificado',
      priceLabel: r'$129',
      priceSuffix: '/mes',
      badgeLabel: 'COMPLETO',
      badgeColor: const Color(0xFFa78bfa),
      features: const [
        'Todo lo del plan Intermedio',
        'Mapa epidemiológico interactivo',
        'Análisis espacial de brotes',
        'Soporte prioritario 24 h',
      ],
      locked: const [],
      cta: cta,
      footer: footer,
    );
  }
}

// ── Base card ─────────────────────────────────────────────────────────────────

class _BasePlanCard extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String priceLabel;
  final String priceSuffix;
  final String badgeLabel;
  final Color badgeColor;
  final List<String> features;
  final List<String> locked;
  final Widget cta;
  final Widget? footer;
  final bool highlighted;
  final bool darkTheme;

  const _BasePlanCard({
    required this.name,
    this.subtitle,
    required this.priceLabel,
    required this.priceSuffix,
    required this.badgeLabel,
    required this.badgeColor,
    required this.features,
    required this.locked,
    required this.cta,
    this.footer,
    this.highlighted = false,
    this.darkTheme = false,
  });

  Color get _bg          => darkTheme ? _kColorPremiumBg : Colors.white;
  Color get _nameColor   => darkTheme ? Colors.white : AppColors.textPrimary;
  Color get _subColor    => darkTheme ? Colors.white60 : AppColors.textMuted;
  Color get _priceColor  => darkTheme ? Colors.white : AppColors.textPrimary;
  Color get _featureColor => darkTheme ? Colors.white70 : AppColors.textPrimary;
  Color get _lockedColor  => darkTheme ? Colors.white30 : AppColors.textMuted;
  Color get _checkColor   => darkTheme ? const Color(0xFF6EE7B7) : AppColors.success;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: _kColorIntermedioBadge, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: darkTheme ? 0.18 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _nameColor)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style:
                                TextStyle(fontSize: 12, color: _subColor)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(
                        alpha: darkTheme ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(priceLabel,
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: _priceColor)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(priceSuffix,
                      style: TextStyle(fontSize: 14, color: _subColor)),
                ),
                if (priceLabel != r'$0') ...[
                  const Spacer(),
                  Text('MXN',
                      style: TextStyle(
                          fontSize: 11,
                          color: _subColor,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Features + locked
            ...features.map((f) => _FeatureLine(
                  text: f,
                  color: _featureColor,
                  iconColor: _checkColor,
                  icon: Icons.check_circle_rounded,
                )),
            ...locked.map((f) => _FeatureLine(
                  text: f,
                  color: _lockedColor,
                  iconColor: _lockedColor,
                  icon: Icons.lock_outline_rounded,
                )),

            const SizedBox(height: 18),
            cta,

            // Footer opcional (ej. indicador de solicitud pendiente)
            if (footer != null) ...[
              const SizedBox(height: 10),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String text;
  final Color color;
  final Color iconColor;
  final IconData icon;
  const _FeatureLine(
      {required this.text,
      required this.color,
      required this.iconColor,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 13, color: color))),
        ],
      ),
    );
  }
}

// ── CTA Buttons ───────────────────────────────────────────────────────────────

class _CtaDisabled extends StatelessWidget {
  final String label;
  final bool dark;
  const _CtaDisabled({required this.label, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: dark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFF3F4F6),
          disabledForegroundColor:
              dark ? Colors.white38 : AppColors.textMuted,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CtaEnabled extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;
  const _CtaEnabled(
      {required this.label,
      required this.color,
      this.textColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor ?? Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── BottomSheet: Confirmación de pago ─────────────────────────────────────────

class _PaymentConfirmationSheet extends StatelessWidget {
  final String planName;
  final String precio;
  final VoidCallback onConfirmar;

  const _PaymentConfirmationSheet({
    required this.planName,
    required this.precio,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Confirmar plan $planName',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '$precio MXN — renovación mensual automática',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          const Text(
            'MÉTODOS DE PAGO',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _PaymentMethodChip(emoji: '💳', label: 'Tarjeta'),
              const SizedBox(width: 8),
              _PaymentMethodChip(emoji: '🏪', label: 'OXXO'),
              const SizedBox(width: 8),
              _PaymentMethodChip(emoji: '🏦', label: 'SPEI'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.infoBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.info, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pago seguro con cifrado SSL. Procesado por Stripe.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.info, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onConfirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Continuar al pago',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _PaymentMethodChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── BottomSheet: Demo de éxito (Stripe) ──────────────────────────────────────

class _DemoSuccessSheet extends StatelessWidget {
  final String planName;
  final String correo;
  const _DemoSuccessSheet({required this.planName, required this.correo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 18),
          const Text('✓ Pago procesado en modo demo',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Tu plan $planName se activará cuando el sistema esté en producción.',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
              children: [
                const TextSpan(text: 'Te contactaremos a '),
                TextSpan(
                  text: correo,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                ),
                const TextSpan(text: ' para confirmar la activación.'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Entendido',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── BottomSheet: Estado de solicitud ─────────────────────────────────────────

class _EstadoSolicitudSheet extends StatelessWidget {
  final SolicitudResult solicitud;
  const _EstadoSolicitudSheet({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: Color(0xFFD97706), size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Solicitud en revisión',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tu cédula profesional está siendo verificada.\nTe notificaremos en menos de 48 horas hábiles.',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (solicitud.solicitudId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ID: ${solicitud.solicitudId}',
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Entendido',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
