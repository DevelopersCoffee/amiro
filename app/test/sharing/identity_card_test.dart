import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sharing/sharing.dart';

import 'package:amiro_app/sharing/identity_card.dart';
import 'package:amiro_app/theme/amiro_theme.dart';

AmiroSharingPayload _payload({
  String name = 'Uday',
  List<EquippedCosmeticInfo> cosmetics = const [
    EquippedCosmeticInfo(
      id: 'riviera_optics',
      name: 'Riviera Optics',
      seriesId: 'series_1',
      rarity: 'RARE',
    ),
    EquippedCosmeticInfo(
      id: 'clean_part',
      name: 'Clean Part',
      seriesId: null,
      rarity: 'COMMON',
    ),
  ],
  List<SeriesCompletion> completion = const [
    SeriesCompletion(seriesId: 'series_1', currentCount: 2, totalCount: 3),
  ],
}) {
  return AmiroSharingPayload(
    remoteIdentityId: 'id-1',
    displayName: name,
    activeAvatarConfig: '{"id":"a"}',
    equippedCosmetics: cosmetics,
    collectionCompletion: completion,
  );
}

Widget _card(
  AmiroSharingPayload payload, {
  String? qrData = 'amiro://encounter?d=abc',
}) {
  return MaterialApp(
    theme: buildAmiroTheme(loadFonts: false),
    home: Scaffold(
      body: SingleChildScrollView(
        child: IdentityCard(
          payload: payload,
          avatar: const SizedBox(key: Key('avatarStage'), height: 220),
          qrData: qrData,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the name, the avatar stage and a scannable QR code', (
    tester,
  ) async {
    await tester.pumpWidget(_card(_payload()));

    expect(find.text('Uday'), findsOneWidget);
    expect(find.byKey(const Key('avatarStage')), findsOneWidget);
    expect(find.byKey(const Key('shareQrCode')), findsOneWidget);
    expect(find.text('Tap or scan to discover'), findsOneWidget);
  });

  testWidgets('names the standout items with their rarity', (tester) async {
    await tester.pumpWidget(_card(_payload()));

    expect(find.text('Riviera Optics'), findsOneWidget);
    expect(find.text('Rare'), findsOneWidget);
  });

  testWidgets('does not list common items as standouts', (tester) async {
    await tester.pumpWidget(_card(_payload()));

    expect(find.text('Clean Part'), findsNothing);
  });

  testWidgets('shows no standout section when everything equipped is common', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(
        _payload(
          cosmetics: const [
            EquippedCosmeticInfo(
              id: 'clean_part',
              name: 'Clean Part',
              seriesId: null,
              rarity: 'COMMON',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Clean Part'), findsNothing);
    expect(find.text('Common'), findsNothing);
  });

  testWidgets('lists at most three standouts, rarest first', (tester) async {
    final cosmetics = [
      for (final (i, rarity) in [
        'UNCOMMON',
        'RARE',
        'EPIC',
        'LEGENDARY',
        'UNCOMMON',
      ].indexed)
        EquippedCosmeticInfo(
          id: 'c$i',
          name: 'Item $i',
          seriesId: null,
          rarity: rarity,
        ),
    ];

    await tester.pumpWidget(_card(_payload(cosmetics: cosmetics)));

    expect(find.text('Item 3'), findsOneWidget); // legendary
    expect(find.text('Item 2'), findsOneWidget); // epic
    expect(find.text('Item 1'), findsOneWidget); // rare
    expect(find.text('Item 0'), findsNothing);
    expect(find.text('Item 4'), findsNothing);
  });

  testWidgets('ignores an equipped item whose rarity this app does not know', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(
        _payload(
          cosmetics: const [
            EquippedCosmeticInfo(
              id: 'x',
              name: 'Future Thing',
              seriesId: null,
              rarity: 'MYTHIC',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Future Thing'), findsNothing);
  });

  testWidgets('shows progress for series the user has started', (tester) async {
    await tester.pumpWidget(_card(_payload()));

    expect(find.text('Series #1 · Founders'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets(
    'shows Complete for a finished series and hides untouched or unknown ones',
    (tester) async {
      await tester.pumpWidget(
        _card(
          _payload(
            completion: const [
              SeriesCompletion(
                seriesId: 'series_1',
                currentCount: 3,
                totalCount: 3,
              ),
              SeriesCompletion(
                seriesId: 'series_99',
                currentCount: 1,
                totalCount: 2,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Complete'), findsOneWidget);
      expect(find.textContaining('99'), findsNothing);
    },
  );

  testWidgets('hides a series with nothing collected yet', (tester) async {
    await tester.pumpWidget(
      _card(
        _payload(
          completion: const [
            SeriesCompletion(
              seriesId: 'series_1',
              currentCount: 0,
              totalCount: 3,
            ),
          ],
        ),
      ),
    );

    expect(find.textContaining('Series #1'), findsNothing);
  });

  testWidgets(
    'has no discovery or storage behaviour: it is purely presentational',
    (tester) async {
      // The card takes data in and draws it. It has no provider or repository
      // dependency, so it renders under a bare MaterialApp with no ProviderScope.
      await tester.pumpWidget(_card(_payload()));

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'says so instead of drawing a QR code when the card cannot be shared',
    (tester) async {
      await tester.pumpWidget(_card(_payload(), qrData: null));

      expect(find.byKey(const Key('shareQrCode')), findsNothing);
      expect(find.byKey(const Key('cardTooLarge')), findsOneWidget);
      expect(find.text('Tap or scan to discover'), findsNothing);
    },
  );

  group('collector\'s frame', () {
    Border border(WidgetTester tester) {
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(IdentityCard),
              matching: find.byType(Container),
            )
            .first,
      );
      return (box.decoration as BoxDecoration).border! as Border;
    }

    testWidgets('a completed series earns a 2px brass frame', (tester) async {
      await tester.pumpWidget(
        _card(
          _payload(
            completion: const [
              SeriesCompletion(
                seriesId: 'series_1',
                currentCount: 3,
                totalCount: 3,
              ),
            ],
          ),
        ),
      );

      expect(border(tester).top.color, AmiroColors.primary);
      expect(border(tester).top.width, 2);
    });

    testWidgets('an unfinished collection keeps the neutral hairline', (
      tester,
    ) async {
      await tester.pumpWidget(_card(_payload()));

      expect(border(tester).top.color, AmiroColors.surfaceBorder);
      expect(border(tester).top.width, 1);
    });
  });
}
