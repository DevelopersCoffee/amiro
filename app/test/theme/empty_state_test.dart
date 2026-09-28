import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/theme/amiro_theme.dart';
import 'package:amiro_app/theme/empty_state.dart';

void main() {
  testWidgets('shows the title and hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAmiroTheme(loadFonts: false),
        home: const Scaffold(
          body: EmptyState(
            title: 'No one discovered yet',
            hint: 'Scan or tap to begin.',
          ),
        ),
      ),
    );

    expect(find.text('No one discovered yet'), findsOneWidget);
    expect(find.text('Scan or tap to begin.'), findsOneWidget);
  });

  testWidgets(
    'the action button is absent without one, and fires its callback with one',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAmiroTheme(loadFonts: false),
          home: Scaffold(
            body: EmptyState(
              title: 'Create your identity first',
              hint: 'Amiro needs a name before you can share it.',
              actionLabel: 'Create identity',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create identity'));
      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'no action button when actionLabel is given but onAction is not',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAmiroTheme(loadFonts: false),
          home: const Scaffold(
            body: EmptyState(title: 'Empty', hint: 'Nothing here.'),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    },
  );
}
