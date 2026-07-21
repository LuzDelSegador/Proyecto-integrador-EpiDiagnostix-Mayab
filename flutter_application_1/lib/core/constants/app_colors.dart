import 'package:flutter/material.dart';

/// Paleta de colores de la app, expuesta como [ThemeExtension] para que
/// reaccione automáticamente al cambio de brillo del sistema (ThemeMode.system
/// en MaterialApp ya dispara el rebuild; esta clase solo provee los valores
/// claro/oscuro y el contraste WCAG AA correspondiente a cada uno).
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color primaryDark;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color inputBackground;
  final Color info;
  final Color infoBackground;
  final Color infoBorder;
  final Color error;
  final Color errorBackground;
  final Color errorBorder;
  final Color success;
  final Color successBackground;
  final Color warning;
  final Color warningBackground;
  final Color highPriority;
  final Color outbreakChipBackground;
  final Color outbreakChipText;
  final Color statusBarBackground;
  final Color shadow;

  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.inputBackground,
    required this.info,
    required this.infoBackground,
    required this.infoBorder,
    required this.error,
    required this.errorBackground,
    required this.errorBorder,
    required this.success,
    required this.successBackground,
    required this.warning,
    required this.warningBackground,
    required this.highPriority,
    required this.outbreakChipBackground,
    required this.outbreakChipText,
    required this.statusBarBackground,
    required this.shadow,
  });

  static const light = AppPalette(
    primary: Color(0xFF1B6E52),
    primaryDark: Color(0xFF0D4F3C),
    background: Color(0xFFF0F4F8),
    surface: Colors.white,
    surfaceElevated: Color(0xFFF7F9FC),
    textPrimary: Color(0xFF1A1A2E),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    border: Color(0xFFE5E7EB),
    inputBackground: Color(0xFFF9FAFB),
    info: Color(0xFF2563EB),
    infoBackground: Color(0xFFEFF6FF),
    infoBorder: Color(0xFFBFDBFE),
    error: Color(0xFFDC2626),
    errorBackground: Color(0xFFFEF2F2),
    errorBorder: Color(0xFFFCA5A5),
    success: Color(0xFF059669),
    successBackground: Color(0xFFD1FAE5),
    warning: Color(0xFFB45309),
    warningBackground: Color(0xFFFEF3C7),
    highPriority: Color(0xFFDC2626),
    outbreakChipBackground: Color(0xFFFEE2E2),
    outbreakChipText: Color(0xFF991B1B),
    statusBarBackground: Color(0xFF1A1A2E),
    shadow: Color(0x0F000000),
  );

  // Fondos gris-casi-negro (no negro puro), verde de marca más saturado para
  // que resalte, tarjetas un tono más claras que el fondo para dar
  // profundidad, y estados de alerta subidos de tono para no verse apagados.
  static const dark = AppPalette(
    primary: Color(0xFF34D399),
    primaryDark: Color(0xFF10B981),
    background: Color(0xFF14181D),
    surface: Color(0xFF1E242B),
    surfaceElevated: Color(0xFF272E36),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFFB0B8C4),
    textMuted: Color(0xFF808894),
    border: Color(0xFF333B44),
    inputBackground: Color(0xFF272E36),
    info: Color(0xFF60A5FA),
    infoBackground: Color(0xFF1A2A42),
    infoBorder: Color(0xFF2C4870),
    error: Color(0xFFF87171),
    errorBackground: Color(0xFF3A1F1F),
    errorBorder: Color(0xFF7F2E2E),
    success: Color(0xFF34D399),
    successBackground: Color(0xFF17332A),
    warning: Color(0xFFFBBF24),
    warningBackground: Color(0xFF3A2E12),
    highPriority: Color(0xFFF87171),
    outbreakChipBackground: Color(0xFF4A1F1F),
    outbreakChipText: Color(0xFFFCA5A5),
    statusBarBackground: Color(0xFF0B0E12),
    shadow: Color(0x40000000),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? inputBackground,
    Color? info,
    Color? infoBackground,
    Color? infoBorder,
    Color? error,
    Color? errorBackground,
    Color? errorBorder,
    Color? success,
    Color? successBackground,
    Color? warning,
    Color? warningBackground,
    Color? highPriority,
    Color? outbreakChipBackground,
    Color? outbreakChipText,
    Color? statusBarBackground,
    Color? shadow,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      inputBackground: inputBackground ?? this.inputBackground,
      info: info ?? this.info,
      infoBackground: infoBackground ?? this.infoBackground,
      infoBorder: infoBorder ?? this.infoBorder,
      error: error ?? this.error,
      errorBackground: errorBackground ?? this.errorBackground,
      errorBorder: errorBorder ?? this.errorBorder,
      success: success ?? this.success,
      successBackground: successBackground ?? this.successBackground,
      warning: warning ?? this.warning,
      warningBackground: warningBackground ?? this.warningBackground,
      highPriority: highPriority ?? this.highPriority,
      outbreakChipBackground: outbreakChipBackground ?? this.outbreakChipBackground,
      outbreakChipText: outbreakChipText ?? this.outbreakChipText,
      statusBarBackground: statusBarBackground ?? this.statusBarBackground,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: c(primary, other.primary),
      primaryDark: c(primaryDark, other.primaryDark),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceElevated: c(surfaceElevated, other.surfaceElevated),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      border: c(border, other.border),
      inputBackground: c(inputBackground, other.inputBackground),
      info: c(info, other.info),
      infoBackground: c(infoBackground, other.infoBackground),
      infoBorder: c(infoBorder, other.infoBorder),
      error: c(error, other.error),
      errorBackground: c(errorBackground, other.errorBackground),
      errorBorder: c(errorBorder, other.errorBorder),
      success: c(success, other.success),
      successBackground: c(successBackground, other.successBackground),
      warning: c(warning, other.warning),
      warningBackground: c(warningBackground, other.warningBackground),
      highPriority: c(highPriority, other.highPriority),
      outbreakChipBackground: c(outbreakChipBackground, other.outbreakChipBackground),
      outbreakChipText: c(outbreakChipText, other.outbreakChipText),
      statusBarBackground: c(statusBarBackground, other.statusBarBackground),
      shadow: c(shadow, other.shadow),
    );
  }
}

/// Fachada estática de acceso a la paleta activa. Se mantiene el nombre
/// `AppColors` para minimizar el cambio en cada pantalla: en vez de
/// `AppColors.primary` ahora se llama `AppColors.of(context).primary`, lo que
/// registra la dependencia de `context` sobre el Theme y hace que cada
/// pantalla se reconstruya sola cuando el sistema cambia de claro a oscuro.
class AppColors {
  const AppColors._();

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
  }
}
