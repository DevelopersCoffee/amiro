import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens from DESIGN.md. Keep values in sync with its front matter.
abstract final class AmiroColors {
  static const ground = Color(0xFF161510);
  static const surface = Color(0xFF1F1D17);
  static const surfaceBorder = Color(0xFF322F26);
  static const text = Color(0xFFEDE8DE);
  static const textMuted = Color(0xFF8C8474);
  static const primary = Color(0xFFC08A3E);
  static const onPrimary = Color(0xFF1D1509);
  static const error = Color(0xFFB4543B);
}

/// [loadFonts] fetches Instrument Sans/Serif at runtime; tests pass false.
ThemeData buildAmiroTheme({bool loadFonts = true}) {
  const scheme = ColorScheme.dark(
    primary: AmiroColors.primary,
    onPrimary: AmiroColors.onPrimary,
    surface: AmiroColors.surface,
    onSurface: AmiroColors.text,
    onSurfaceVariant: AmiroColors.textMuted,
    outline: AmiroColors.surfaceBorder,
    error: AmiroColors.error,
  );

  var textTheme = ThemeData(brightness: Brightness.dark).textTheme.apply(
        bodyColor: AmiroColors.text,
        displayColor: AmiroColors.text,
      );
  if (loadFonts) {
    textTheme = GoogleFonts.instrumentSansTextTheme(textTheme).copyWith(
      headlineSmall: GoogleFonts.instrumentSerif(textStyle: textTheme.headlineSmall),
      titleLarge: GoogleFonts.instrumentSerif(textStyle: textTheme.titleLarge),
    );
  }

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AmiroColors.ground,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AmiroColors.ground,
      foregroundColor: AmiroColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 23),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AmiroColors.surface,
      indicatorColor: AmiroColors.surfaceBorder,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AmiroColors.primary,
        foregroundColor: AmiroColors.onPrimary,
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: const ListTileThemeData(iconColor: AmiroColors.textMuted),
  );
}
