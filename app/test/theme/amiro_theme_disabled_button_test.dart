import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/theme/amiro_theme.dart';

void main() {
  testWidgets(
    "a disabled primary button is 40% opacity brass, not grey, per DESIGN.md",
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAmiroTheme(loadFonts: false),
          home: const Scaffold(
            body: FilledButton(onPressed: null, child: Text('Save')),
          ),
        ),
      );

      final style = FilledButtonTheme.of(
        tester.element(find.byType(FilledButton)),
      ).style!;
      final bg = style.backgroundColor!.resolve({WidgetState.disabled});
      expect(bg, AmiroColors.primary.withValues(alpha: 0.4));
      final elevation = style.elevation?.resolve({WidgetState.disabled});
      expect(elevation, anyOf(isNull, 0));
    },
  );

  test('spacing tokens match DESIGN.md\'s 4px base scale', () {
    expect(AmiroSpacing.xs, 4);
    expect(AmiroSpacing.sm, 8);
    expect(AmiroSpacing.md, 16);
    expect(AmiroSpacing.lg, 24);
    expect(AmiroSpacing.xl, 32);
    expect(AmiroSpacing.xl2, 48);
  });

  test('radius tokens match DESIGN.md\'s scale', () {
    expect(AmiroRadius.sm, 6);
    expect(AmiroRadius.md, 14);
    expect(AmiroRadius.lg, 16);
  });
}
