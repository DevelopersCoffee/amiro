import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:discovery/discovery.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/discovery/date_format.dart';
import 'package:amiro_app/discovery/discovery_providers.dart';
import 'package:amiro_app/discovery/passport_screen.dart';
import 'package:amiro_app/theme/amiro_theme.dart';

import 'support.dart';

EncounterRecord _record(
  String id,
  String name, {
  DateTime? first,
  DateTime? last,
  int count = 1,
  List<EquippedCosmeticInfo> cosmetics = const [rivieraOptics],
  List<SeriesCompletion> completion = const [
    SeriesCompletion(seriesId: 'series_1', currentCount: 2, totalCount: 3),
  ],
}) {
  final firstSeen = first ?? DateTime.utc(2026, 9, 20, 12);
  return EncounterRecord(
    localRecordId: 'local-$id',
    remoteIdentityId: id,
    displayName: name,
    firstEncountered: firstSeen,
    lastEncountered: last ?? firstSeen,
    encounterCount: count,
    latestAvatarConfig: '{"id":"a","body":"body_superhero_male"}',
    observedCosmetics: cosmetics,
    observedCollections: completion,
  );
}

Future<TestApp> _open(
  WidgetTester tester,
  List<EncounterRecord> records,
) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final app = TestApp();
  for (final r in records) {
    await app.passport.save(r);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: app.overrides,
      child: MaterialApp(
        theme: buildAmiroTheme(loadFonts: false),
        home: const PassportScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('an empty passport invites the first discovery', (tester) async {
    await _open(tester, const []);

    expect(find.text('No one discovered yet'), findsOneWidget);
    expect(find.byKey(const Key('passportCount')), findsNothing);
  });

  testWidgets('counts identities, with the right singular and plural', (
    tester,
  ) async {
    await _open(tester, [_record('a', 'Ada')]);
    expect(find.text('01 identity'), findsOneWidget);

    await _open(tester, [_record('a', 'Ada'), _record('b', 'Bea')]);
    expect(find.text('02 identities'), findsOneWidget);
  });

  testWidgets('lists the most recently met first', (tester) async {
    await _open(tester, [
      _record(
        'old',
        'Older',
        first: DateTime.utc(2026, 8, 1, 12),
        last: DateTime.utc(2026, 9, 1, 12),
      ),
      _record(
        'new',
        'Newer',
        first: DateTime.utc(2026, 8, 2, 12),
        last: DateTime.utc(2026, 9, 25, 12),
      ),
    ]);

    expect(
      tester.getTopLeft(find.text('Newer')).dy,
      lessThan(tester.getTopLeft(find.text('Older')).dy),
    );
  });

  testWidgets(
    'each entry shows first-met date, standout item and series progress',
    (tester) async {
      final first = DateTime.utc(2026, 9, 20, 12);
      await _open(tester, [_record('a', 'Ada', first: first)]);

      expect(find.text('First met ${formatShortDate(first)}'), findsOneWidget);
      expect(find.text('Riviera Optics'), findsOneWidget);
      expect(find.text('Rare'), findsOneWidget);
      expect(find.text('Series #1 · Founders'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
    },
  );

  testWidgets('shows how often you have met only when more than once', (
    tester,
  ) async {
    await _open(tester, [
      _record('a', 'Ada', count: 1),
      _record('b', 'Bea', count: 4),
    ]);

    expect(find.text('4×'), findsOneWidget);
    expect(find.text('1×'), findsNothing);
  });

  testWidgets('leaves out common items and unstarted series', (tester) async {
    await _open(tester, [
      _record(
        'a',
        'Ada',
        cosmetics: const [
          EquippedCosmeticInfo(
            id: 'c',
            name: 'Clean Part',
            seriesId: null,
            rarity: 'COMMON',
          ),
        ],
        completion: const [
          SeriesCompletion(
            seriesId: 'series_1',
            currentCount: 0,
            totalCount: 3,
          ),
        ],
      ),
    ]);

    expect(find.text('Clean Part'), findsNothing);
    expect(find.textContaining('Series #1'), findsNothing);
  });

  testWidgets('tapping an entry opens it in full', (tester) async {
    await _open(tester, [_record('a', 'Ada')]);

    await tester.tap(find.byKey(const Key('passportEntry-a')));
    await tester.pumpAndSettle();

    expect(find.text('STANDOUTS'), findsOneWidget);
    expect(find.textContaining('Last seen'), findsOneWidget);
    expect(find.byKey(const Key('removeFromPassportButton')), findsOneWidget);
  });

  group('removing someone', () {
    Future<TestApp> openEntry(WidgetTester tester) async {
      final app = await _open(tester, [
        _record('a', 'Ada'),
        _record('b', 'Bea'),
      ]);
      await tester.tap(find.byKey(const Key('passportEntry-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('removeFromPassportButton')));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('asks first, and Keep changes nothing', (tester) async {
      final app = await openEntry(tester);

      expect(find.text('Remove Ada?'), findsOneWidget);
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      expect(await app.passport.getAll(), hasLength(2));
    });

    testWidgets('Remove deletes just that entry and returns to the passport', (
      tester,
    ) async {
      final app = await openEntry(tester);

      await tester.tap(find.byKey(const Key('confirmRemoveButton')));
      await tester.pumpAndSettle();

      final left = await app.passport.getAll();
      expect(left.map((r) => r.remoteIdentityId), ['b']);
      expect(find.text('01 identity'), findsOneWidget);
      expect(find.text('Ada'), findsNothing);
    });
  });

  testWidgets(
    'an unreadable ledger says so instead of showing an empty passport',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            encounterRecordsProvider.overrideWith(
              (ref) => throw const FormatException('corrupt'),
            ),
          ],
          child: MaterialApp(
            theme: buildAmiroTheme(loadFonts: false),
            home: const PassportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Your passport couldn't be opened"), findsOneWidget);
      expect(find.text('No one discovered yet'), findsNothing);
    },
  );

  testWidgets('an entry whose series is complete gets the collector\'s frame', (
    tester,
  ) async {
    await _open(tester, [
      _record(
        'done',
        'Done',
        completion: const [
          SeriesCompletion(
            seriesId: 'series_1',
            currentCount: 3,
            totalCount: 3,
          ),
        ],
      ),
      _record('part', 'Partial'),
    ]);

    Border borderOf(String id) {
      final card = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(Key('passportEntry-$id')),
              matching: find.byType(Container),
            )
            .first,
      );
      return (card.decoration as BoxDecoration).border! as Border;
    }

    expect(borderOf('done').top.color, AmiroColors.primary);
    expect(borderOf('part').top.color, AmiroColors.surfaceBorder);
  });
}
