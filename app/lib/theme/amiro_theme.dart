import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens from DESIGN.md. Keep values in sync with its front matter.
abstract final class AmiroColors {
  static const ground = Color(0xFF111110);
  static const surface = Color(0xFF1D1C19);
  static const stage = Color(0xFF48483F);
  static const surfaceBorder = Color(0xFF322F26);
  static const text = Color(0xFFEDE8DE);
  static const textMuted = Color(0xFF8C8474);
  static const primary = Color(0xFFC49343);
  static const onPrimary = Color(0xFF1D1509);
  static const error = Color(0xFFB4543B);
}

/// Base-4px spacing scale (DESIGN.md).
abstract final class AmiroSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xl2 = 48.0;
}

/// Corner-radius scale (DESIGN.md). `full` is a pill/circle, not a fixed value.
abstract final class AmiroRadius {
  static const sm = 6.0;
  static const md = 14.0;
  static const lg = 16.0;
}

/// The authored offset shadow every elevated card uses (DESIGN.md's
/// "Elevation & Depth": real offset + blur only, never a zero-offset glow).
const amiroCardShadow = [
  BoxShadow(
    color: Color(0x59000000),
    offset: Offset(0, 12),
    blurRadius: 24,
    spreadRadius: -12,
  ),
];

/// Monospaced, tabular-figure style for prices and valuation (DESIGN.md).
class AmiroTypography extends ThemeExtension<AmiroTypography> {
  final TextStyle mono;

  const AmiroTypography({required this.mono});

  @override
  AmiroTypography copyWith({TextStyle? mono}) =>
      AmiroTypography(mono: mono ?? this.mono);

  @override
  AmiroTypography lerp(AmiroTypography? other, double t) => other == null
      ? this
      : AmiroTypography(mono: TextStyle.lerp(mono, other.mono, t)!);
}

/// The mono style from the ambient theme, or a plain tabular fallback.
TextStyle amiroMono(BuildContext context) =>
    Theme.of(context).extension<AmiroTypography>()?.mono ??
    const TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

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
      headlineSmall: GoogleFonts.instrumentSerif(
        textStyle: textTheme.headlineSmall,
      ),
      titleLarge: GoogleFonts.instrumentSerif(textStyle: textTheme.titleLarge),
    );
  }

  var mono = const TextStyle(
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  if (loadFonts) mono = GoogleFonts.jetBrainsMono(textStyle: mono);

  return ThemeData(
    extensions: [AmiroTypography(mono: mono)],
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AmiroColors.surface,
      indicatorColor: AmiroColors.surfaceBorder,
      // Selected vs unselected differ in weight, not colour — the active
      // tab's icon (filled vs outline, see app.dart) already carries the
      // colour-independent signal, so the label just confirms it.
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final base = textTheme.labelMedium ?? const TextStyle();
        return states.contains(WidgetState.selected)
            ? base.copyWith(
                color: AmiroColors.text,
                fontWeight: FontWeight.w600,
              )
            : base.copyWith(color: AmiroColors.textMuted);
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        // Disabled = 40% opacity, no shadow, not tappable (DESIGN.md's fix
        // for the "dead tap on unchanged save" gap) — not Material's default
        // grey-out, which would read as a broken button rather than "wait".
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AmiroColors.primary.withValues(alpha: 0.4);
          }
          return AmiroColors.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AmiroColors.onPrimary.withValues(alpha: 0.4);
          }
          return AmiroColors.onPrimary;
        }),
        elevation: const WidgetStatePropertyAll(0),
        minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AmiroRadius.md),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(iconColor: AmiroColors.textMuted),
  );
}
