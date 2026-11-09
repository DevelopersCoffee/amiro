import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:discovery/discovery.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/discovery/encounter_comparison.dart';
import 'package:amiro_app/discovery/encounter_screen.dart';
import 'package:amiro_app/discovery/passport_entry_screen.dart';
import 'package:amiro_app/theme/amiro_theme.dart';
import 'package:amiro_app/theme/section_label.dart';

import '../discovery/support.dart';

/// Pins the inline section-caption `TextStyle` each discovery screen built
/// before sharing `sectionLabelStyle`.
TextStyle pinnedInlineSectionCaptionStyle(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;
  return textTheme.labelSmall!.copyWith(
    color: AmiroColors.textMuted,
    letterSpacing: 2.4,
  );
}

void main() {
  void expectCaption(WidgetTester tester, String label) {
    final element = tester.element(find.text(label));
    final expected = pinnedInlineSectionCaptionStyle(element);
    final text = tester.widget<Text>(find.text(label));
    expect(text.style, expected);
    expect(text.style, sectionLabelStyle(element));
  }

  group('encounter screen section captions', () {
    Future<void> openNew(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final app = TestApp();
      await tester.pumpWidget(app.host(EncounterScreen(encounter: encounterFor())));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('NEW AMIRO uses the shared section caption style', (
      tester,
    ) async {
      await openNew(tester);
      expectCaption(tester, 'NEW AMIRO');
    });

    testWidgets('MET BEFORE uses the shared section caption style', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final app = TestApp();
      await app.passport.save(
        EncounterRecord(
          localRecordId: 'local-1',
          remoteIdentityId: 'remote-1',
          displayName: 'Ada',
          firstEncountered: DateTime.utc(2026, 9, 20, 12),
          lastEncountered: DateTime.utc(2026, 9, 21, 12),
          encounterCount: 2,
          latestAvatarConfig: '{"id":"a"}',
          observedCosmetics: const [],
          observedCollections: const [],
        ),
      );
      await tester.pumpWidget(
        app.host(EncounterScreen(encounter: encounterFor())),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expectCaption(tester, 'MET BEFORE');
    });
  });

  group('encounter comparison section captions', () {
    Future<void> pumpComparison(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAmiroTheme(loadFonts: false),
          home: Scaffold(
            body: EncounterComparison(
              mine: payloadFor(id: 'me', name: 'Uday'),
              theirs: payloadFor(),
            ),
          ),
        ),
      );
    }

    testWidgets('YOU, THEM and COLLECTIONS use the section caption style', (
      tester,
    ) async {
      await pumpComparison(tester);
      for (final label in ['YOU', 'THEM', 'COLLECTIONS']) {
        expectCaption(tester, label);
      }
    });
  });

  group('passport entry section captions', () {
    Future<void> openEntry(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final app = TestApp();
      await app.passport.save(
        EncounterRecord(
          localRecordId: 'local-a',
          remoteIdentityId: 'a',
          displayName: 'Ada',
          firstEncountered: DateTime.utc(2026, 9, 20, 12),
          lastEncountered: DateTime.utc(2026, 9, 20, 12),
          encounterCount: 1,
          latestAvatarConfig: '{"id":"a","body":"body_superhero_male"}',
          observedCosmetics: const [rivieraOptics],
          observedCollections: const [
            SeriesCompletion(seriesId: 'series_1', currentCount: 2, totalCount: 3),
          ],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: app.overrides,
          child: MaterialApp(
            theme: buildAmiroTheme(loadFonts: false),
            home: const PassportEntryScreen(remoteIdentityId: 'a'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('STANDOUTS and COLLECTIONS use the section caption style', (
      tester,
    ) async {
      await openEntry(tester);
      for (final label in ['STANDOUTS', 'COLLECTIONS']) {
        expectCaption(tester, label);
      }
    });
  });
}
