import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/theme/amiro_theme.dart';
import 'package:amiro_app/theme/section_label.dart';

void main() {
  testWidgets(
    'renders the given text unchanged (no forced uppercasing of content)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAmiroTheme(loadFonts: false),
          home: const Scaffold(body: SectionLabel('COLLECTIONS')),
        ),
      );

      expect(find.text('COLLECTIONS'), findsOneWidget);
    },
  );

  testWidgets(
    'uses the muted colour and wide tracking DESIGN.md specifies for labels',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAmiroTheme(loadFonts: false),
          home: const Scaffold(body: SectionLabel('STANDOUTS')),
        ),
      );

      final text = tester.widget<Text>(find.text('STANDOUTS'));
      expect(text.style!.color, AmiroColors.textMuted);
      expect(text.style!.letterSpacing, greaterThan(1));
    },
  );
}
