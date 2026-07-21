import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ThemeData claro/oscuro compartidos por la app principal y el panel admin.
/// Ambos usan la misma [AppPalette] vía ThemeExtension — ver app_colors.dart.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(AppPalette.light, Brightness.light);
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B6E52),
        brightness: brightness,
        primary: palette.primary,
        error: palette.error,
        surface: palette.surface,
      ),
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Roboto',
      dividerColor: palette.border,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: palette.shadow,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: [palette],
    );
  }
}
