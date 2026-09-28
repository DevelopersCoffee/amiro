import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:discovery/discovery.dart';
import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/discovery/date_format.dart';
import 'package:amiro_app/discovery/encounter_screen.dart';

import 'support.dart';

Future<void> _open(
  WidgetTester tester,
  TestApp app,
  EncounterQr encounter,
) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app.host(EncounterScreen(encounter: encounter)));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

EncounterRecord _record({int count = 2}) {
  final first = DateTime.utc(2026, 9, 20, 12);
  return EncounterRecord(
    localRecordId: 'local-1',
    remoteIdentityId: 'remote-1',
    displayName: 'Ada',
    firstEncountered: first,
    lastEncountered: first.add(const Duration(days: 1)),
    encounterCount: count,
    latestAvatarConfig: '{"id":"a"}',
    observedCosmetics: const [],
    observedCollections: const [],
  );
}

void main() {
  group('a new identity', () {
    testWidgets('is shown with the comparison and nothing is saved yet', (
      tester,
    ) async {
      final app = TestApp();

      await _open(tester, app, encounterFor());

      expect(find.text('NEW AMIRO'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('THEM'), findsOneWidget);
      expect(find.text('Save to passport'), findsOneWidget);
      expect(await app.passport.getAll(), isEmpty);
    });

    testWidgets(
      'Save to passport writes one entry, confirms, and leaves the screen',
      (tester) async {
        final app = TestApp();
        await _open(tester, app, encounterFor());

        await tester.tap(find.byKey(const Key('saveToPassportButton')));
        await tester.pumpAndSettle();

        final saved = await app.passport.getAll();
        expect(saved, hasLength(1));
        expect(saved.single.remoteIdentityId, 'remote-1');
        expect(saved.single.encounterCount, 1);
        expect(find.byType(EncounterScreen), findsNothing);
        expect(find.text('Saved to your passport'), findsOneWidget);
      },
    );

    testWidgets('leaving without saving writes nothing', (tester) async {
      final app = TestApp();
      await _open(tester, app, encounterFor());

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(await app.passport.getAll(), isEmpty);
    });
  });

  group('someone already in the passport', () {
    testWidgets('shows how often and since when you have met', (tester) async {
      final app = TestApp();
      final record = _record();
      await app.passport.save(record);

      await _open(tester, app, encounterFor());

      expect(find.text('MET BEFORE'), findsOneWidget);
      expect(find.textContaining('2×'), findsOneWidget);
      expect(
        find.textContaining(formatShortDate(record.firstEncountered)),
        findsOneWidget,
      );
    });

    testWidgets('saving updates their entry without adding a second one', (
      tester,
    ) async {
      final app = TestApp();
      await app.passport.save(_record());
      await _open(tester, app, encounterFor());

      await tester.tap(find.text('Update passport'));
      await tester.pumpAndSettle();

      final all = await app.passport.getAll();
      expect(all, hasLength(1));
      expect(all.single.encounterCount, 3);
      expect(all.single.localRecordId, 'local-1');
    });

    testWidgets('leaving without saving does not bump the count', (
      tester,
    ) async {
      final app = TestApp();
      await app.passport.save(_record());
      await _open(tester, app, encounterFor());

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect((await app.passport.getAll()).single.encounterCount, 2);
    });
  });

  testWidgets('your own card is not an encounter and cannot be saved', (
    tester,
  ) async {
    final app = TestApp(
      identity: Identity(id: 'remote-1', displayName: 'Uday', username: 'uday'),
    );

    await _open(tester, app, encounterFor());

    expect(find.text("That's your own Amiro."), findsOneWidget);
    expect(find.byKey(const Key('saveToPassportButton')), findsNothing);
    expect(await app.passport.getAll(), isEmpty);
  });

  testWidgets('shows their contact details when they shared some', (
    tester,
  ) async {
    final app = TestApp();

    await _open(
      tester,
      app,
      encounterFor(
        contact: const ContactCard(username: 'ada', email: 'ada@example.com'),
      ),
    );

    expect(find.text('@ada'), findsOneWidget);
    expect(find.text('Email: ada@example.com'), findsOneWidget);
  });

  testWidgets('omits the contact section when they shared none', (
    tester,
  ) async {
    await _open(tester, TestApp(), encounterFor());

    expect(find.text('CONTACT'), findsNothing);
  });
}
