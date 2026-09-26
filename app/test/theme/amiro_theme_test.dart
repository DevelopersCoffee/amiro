import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/theme/amiro_theme.dart';

void main() {
  final theme = buildAmiroTheme(loadFonts: false);

  test('is a dark theme on the DESIGN.md ground color', () {
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF161510));
  });

  test('uses the brass accent as the primary color with dark text on it', () {
    expect(theme.colorScheme.primary, const Color(0xFFC08A3E));
    expect(theme.colorScheme.onPrimary, const Color(0xFF1D1509));
  });

  test('uses DESIGN.md surface and text colors', () {
    expect(theme.colorScheme.surface, const Color(0xFF1F1D17));
    expect(theme.colorScheme.onSurface, const Color(0xFFEDE8DE));
    expect(theme.colorScheme.error, const Color(0xFFB4543B));
  });

  test('filled buttons use the md radius and 44px minimum height', () {
    final style = theme.filledButtonTheme.style!;
    final shape = style.shape!.resolve({}) as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(14));
    expect(style.minimumSize!.resolve({})!.height, 44);
  });

  test('exposes a tabular-figure mono style for prices', () {
    final mono = theme.extension<AmiroTypography>()!.mono;
    expect(mono.fontFeatures, contains(const FontFeature.tabularFigures()));
  });
}
