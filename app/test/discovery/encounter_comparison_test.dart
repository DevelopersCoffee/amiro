import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sharing/sharing.dart';

import 'package:amiro_app/discovery/encounter_comparison.dart';
import 'package:amiro_app/theme/amiro_theme.dart';

import 'support.dart';

Widget _wrap(AmiroSharingPayload? mine, AmiroSharingPayload theirs) =>
    MaterialApp(
      theme: buildAmiroTheme(loadFonts: false),
      home: Scaffold(
        body: SingleChildScrollView(
          child: EncounterComparison(mine: mine, theirs: theirs),
        ),
      ),
    );

void main() {
  testWidgets('shows standout items for both sides with their rarity', (
    tester,
  ) async {
    final mine = payloadFor(
      id: 'me',
      name: 'Uday',
      cosmetics: const [
        EquippedCosmeticInfo(
          id: 'long_flow',
          name: 'Long Flow',
          seriesId: 'series_1',
          rarity: 'UNCOMMON',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(mine, payloadFor()));

    expect(find.text('Riviera Optics'), findsOneWidget); // theirs
    expect(find.text('Rare'), findsOneWidget);
    expect(find.text('Long Flow'), findsOneWidget); // mine
    expect(find.text('Uncommon'), findsOneWidget);
  });

  testWidgets('a side with nothing above Common says so', (tester) async {
    final commonOnly = payloadFor(
      cosmetics: const [
        EquippedCosmeticInfo(
          id: 'clean_part',
          name: 'Clean Part',
          seriesId: null,
          rarity: 'COMMON',
        ),
      ],
    );

    await tester.pumpWidget(_wrap(commonOnly, commonOnly));

    expect(find.text('Nothing rare equipped'), findsNWidgets(2));
  });

  testWidgets('lines up series progress: you against them', (tester) async {
    final mine = payloadFor(
      id: 'me',
      completion: const [
        SeriesCompletion(seriesId: 'series_1', currentCount: 2, totalCount: 3),
      ],
    );

    await tester.pumpWidget(_wrap(mine, payloadFor()));

    expect(find.text('Series #1 · Founders'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('mine1')),
              matching: find.byType(Text),
            ),
          )
          .data,
      '2 / 3',
    );
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('theirs1')),
              matching: find.byType(Text),
            ),
          )
          .data,
      '1 / 3',
    );
  });

  testWidgets(
    'shows Complete for a finished series and a dash for one you have not started',
    (tester) async {
      final theirs = payloadFor(
        completion: const [
          SeriesCompletion(
            seriesId: 'series_1',
            currentCount: 3,
            totalCount: 3,
          ),
        ],
      );
      final mine = payloadFor(
        id: 'me',
        completion: const [
          SeriesCompletion(
            seriesId: 'series_1',
            currentCount: 0,
            totalCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(mine, theirs));

      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('–'), findsOneWidget);
    },
  );

  testWidgets(
    'leaves the YOU side empty rather than inventing it when you have no card',
    (tester) async {
      await tester.pumpWidget(_wrap(null, payloadFor()));

      expect(find.text('Nothing rare equipped'), findsOneWidget); // only YOU
      expect(find.text('Riviera Optics'), findsOneWidget);
    },
  );

  testWidgets(
    'hides collections nobody has started and ones this version does not know',
    (tester) async {
      final unknown = payloadFor(
        completion: const [
          SeriesCompletion(
            seriesId: 'series_99',
            currentCount: 1,
            totalCount: 2,
          ),
          SeriesCompletion(
            seriesId: 'series_1',
            currentCount: 0,
            totalCount: 3,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(null, unknown));

      expect(find.text('COLLECTIONS'), findsNothing);
    },
  );
}
