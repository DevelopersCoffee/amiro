import 'package:amiro_app/theme/amiro_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  test('production theme uses bundled font families', () {
    final theme = buildAmiroTheme(loadFonts: true);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Instrument Sans');
    expect(theme.textTheme.titleLarge?.fontFamily, 'Instrument Serif');
    expect(
      theme.extension<AmiroTypography>()?.mono.fontFamily,
      'JetBrains Mono',
    );
  });

  test('runtime font fetching is disabled at startup', () {
    GoogleFonts.config.allowRuntimeFetching = false;
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });
}
