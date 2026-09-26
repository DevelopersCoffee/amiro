import 'package:discovery/discovery.dart';
import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

import 'support.dart';

AmiroSharingPayload payload({
  String remoteIdentityId = 'remote-a',
  String displayName = 'Ada',
  String avatar = '{"id":"a"}',
  List<EquippedCosmeticInfo> cosmetics = const [
    EquippedCosmeticInfo(
      id: 'riviera_optics',
      name: 'Riviera Optics',
      seriesId: 'series_1',
      rarity: 'RARE',
    ),
  ],
  List<SeriesCompletion> collections = const [
    SeriesCompletion(seriesId: 'series_1', currentCount: 1, totalCount: 3),
  ],
}) {
  return AmiroSharingPayload(
    remoteIdentityId: remoteIdentityId,
    displayName: displayName,
    activeAvatarConfig: avatar,
    equippedCosmetics: cosmetics,
    collectionCompletion: collections,
  );
}

void main() {
  late InMemoryDiscoveryRepository repo;
  late DateTime now;
  late int idSeq;
  late EncounterProcessor processor;

  EncounterProcessor build({String? ownIdentityId}) => EncounterProcessor(
    repo,
    clock: () => now,
    newId: () => 'local-${++idSeq}',
    ownIdentityId: ownIdentityId,
  );

  setUp(() {
    repo = InMemoryDiscoveryRepository();
    now = t0;
    idSeq = 0;
    processor = build();
  });

  /// Receive then save, as the UI does when the user commits.
  Future<EncounterRecord> meet(AmiroSharingPayload p) async {
    final result = await processor.receivePayload(p);
    return processor.save(result as PendingEncounter);
  }

  group('a new identity', () {
    test('is a NewEncounter that writes nothing until saved', () async {
      final result = await processor.receivePayload(payload());

      expect(result, isA<NewEncounter>());
      expect(await processor.uniqueEncounterCount(), 0);
      expect(await repo.getAll(), isEmpty);
    });

    test(
      'creates a record with its own local id and a first-contact count of 1',
      () async {
        final saved = await meet(payload());

        expect(saved.localRecordId, 'local-1');
        expect(saved.remoteIdentityId, 'remote-a');
        expect(saved.localRecordId, isNot(saved.remoteIdentityId));
        expect(saved.encounterCount, 1);
        expect(saved.firstEncountered, t0);
        expect(saved.lastEncountered, t0);
        expect(saved.displayName, 'Ada');
        expect(saved.latestAvatarConfig, '{"id":"a"}');
        expect(saved.observedCosmetics.single.id, 'riviera_optics');
        expect(saved.observedCollections.single.currentCount, 1);
        expect(await processor.uniqueEncounterCount(), 1);
      },
    );

    test('previews the record it would create', () async {
      final result = await processor.receivePayload(payload()) as NewEncounter;

      expect(result.proposed.encounterCount, 1);
      expect(result.proposed.remoteIdentityId, 'remote-a');
    });
  });

  group('a known identity', () {
    test('is a KnownEncounter carrying the record it would update', () async {
      final first = await meet(payload());
      now = t0.add(const Duration(days: 1));

      final result = await processor.receivePayload(payload());

      expect(result, isA<KnownEncounter>());
      expect((result as KnownEncounter).previous, first);
      expect(result.proposed.encounterCount, 2);
    });

    test('updates the record without adding to the unique count', () async {
      await meet(payload());
      now = t0.add(const Duration(days: 1));

      final updated = await meet(payload());

      expect(updated.localRecordId, 'local-1'); // same record, not a new one
      expect(updated.encounterCount, 2);
      expect(updated.firstEncountered, t0);
      expect(updated.lastEncountered, now);
      expect(await processor.uniqueEncounterCount(), 1);
    });

    test('refreshes their name, look, cosmetics and collections', () async {
      await meet(payload());
      now = t0.add(const Duration(days: 1));

      final updated = await meet(
        payload(
          displayName: 'Ada L.',
          avatar: '{"id":"a2"}',
          cosmetics: const [],
          collections: const [
            SeriesCompletion(
              seriesId: 'series_1',
              currentCount: 3,
              totalCount: 3,
            ),
          ],
        ),
      );

      expect(updated.displayName, 'Ada L.');
      expect(updated.latestAvatarConfig, '{"id":"a2"}');
      expect(updated.observedCosmetics, isEmpty);
      expect(updated.observedCollections.single.currentCount, 3);
    });

    test('lastEncountered never moves backwards if the clock does', () async {
      await meet(payload());
      now = t0.subtract(const Duration(hours: 5));

      final updated = await meet(payload());

      expect(updated.lastEncountered, t0);
      expect(updated.encounterCount, 2);
    });
  });

  group('unique count invariant', () {
    test('A, A, A, B gives 1, 1, 1, 2 unique encounters', () async {
      await meet(payload(remoteIdentityId: 'A'));
      expect(await processor.uniqueEncounterCount(), 1);
      await meet(payload(remoteIdentityId: 'A'));
      expect(await processor.uniqueEncounterCount(), 1);
      await meet(payload(remoteIdentityId: 'A'));
      expect(await processor.uniqueEncounterCount(), 1);
      await meet(payload(remoteIdentityId: 'B'));
      expect(await processor.uniqueEncounterCount(), 2);
    });

    test(
      'the same identity twelve times is one discovery met twelve times',
      () async {
        EncounterRecord? last;
        for (var i = 0; i < 12; i++) {
          now = t0.add(Duration(minutes: i));
          last = await meet(payload());
        }

        expect(await processor.uniqueEncounterCount(), 1);
        expect(last!.encounterCount, 12);
        expect((await repo.getAll()).single.localRecordId, 'local-1');
      },
    );

    test(
      'different identities each get their own record and local id',
      () async {
        final a = await meet(payload(remoteIdentityId: 'A'));
        final b = await meet(payload(remoteIdentityId: 'B'));

        expect(a.localRecordId, isNot(b.localRecordId));
        expect(await processor.uniqueEncounterCount(), 2);
      },
    );
  });

  group('the save gate', () {
    test(
      'dismissing a known encounter without saving changes nothing',
      () async {
        final before = await meet(payload());

        await processor.receivePayload(payload()); // shown, then dismissed

        expect(await repo.getAll(), [before]);
      },
    );

    test('saving the same encounter twice counts it once', () async {
      final pending =
          await processor.receivePayload(payload()) as PendingEncounter;

      await processor.save(pending);
      await processor.save(pending); // double tap

      final record = (await repo.getAll()).single;
      expect(record.encounterCount, 1);
    });

    test('saving a known encounter twice counts it once', () async {
      await meet(payload());
      now = t0.add(const Duration(hours: 1));
      final pending =
          await processor.receivePayload(payload()) as PendingEncounter;

      await processor.save(pending);
      await processor.save(pending);

      expect((await repo.getAll()).single.encounterCount, 2);
    });

    test(
      'a stale preview is recomputed against what has been saved since',
      () async {
        final first =
            await processor.receivePayload(payload()) as PendingEncounter;
        final second =
            await processor.receivePayload(payload()) as PendingEncounter;
        expect(first, isA<NewEncounter>());
        expect(second, isA<NewEncounter>());

        await processor.save(second);
        final saved = await processor.save(first); // was "new", is now known

        expect(await processor.uniqueEncounterCount(), 1);
        expect(saved.encounterCount, 2);
        expect(saved.localRecordId, 'local-2'); // the record that landed first
      },
    );

    test(
      'concurrent saves of the same new identity still make one record',
      () async {
        final a = await processor.receivePayload(payload()) as PendingEncounter;
        final b = await processor.receivePayload(payload()) as PendingEncounter;

        await Future.wait([processor.save(a), processor.save(b)]);

        expect(await processor.uniqueEncounterCount(), 1);
        expect((await repo.getAll()).single.encounterCount, 2);
      },
    );

    test('concurrent saves of different identities all land', () async {
      final pendings = [
        for (var i = 0; i < 10; i++)
          await processor.receivePayload(payload(remoteIdentityId: 'r$i'))
              as PendingEncounter,
      ];

      await Future.wait([for (final p in pendings) processor.save(p)]);

      expect(await processor.uniqueEncounterCount(), 10);
    });
  });

  group('rejection', () {
    test('malformed JSON is rejected and never reaches the ledger', () async {
      final result = await processor.receive('{nope');

      expect(result, isA<EncounterRejected>());
      expect(
        (result as EncounterRejected).error.kind,
        PayloadErrorKind.malformed,
      );
      expect(await repo.getAll(), isEmpty);
    });

    test('an unsupported schema version is rejected as such', () async {
      final result = await processor.receive('{"schemaVersion":2}');

      expect(
        (result as EncounterRejected).error.kind,
        PayloadErrorKind.unsupportedVersion,
      );
    });

    test('an oversized payload is rejected', () async {
      final result = await processor.receive(
        'x' * (maxSharingPayloadBytes + 1),
      );

      expect(
        (result as EncounterRejected).error.kind,
        PayloadErrorKind.tooLarge,
      );
    });

    test('a payload with a duplicate cosmetic is rejected', () async {
      const dup = EquippedCosmeticInfo(
        id: 'a',
        name: 'A',
        seriesId: null,
        rarity: 'COMMON',
      );

      final result = await processor.receivePayload(
        payload(cosmetics: const [dup, dup]),
      );

      expect(result, isA<EncounterRejected>());
      expect(await repo.getAll(), isEmpty);
    });

    test('a valid encoded payload is accepted through receive', () async {
      final result = await processor.receive(payload().encode());

      expect(result, isA<NewEncounter>());
    });
  });

  group('your own card', () {
    test('scanning yourself is not an encounter', () async {
      processor = build(ownIdentityId: 'remote-a');

      final result = await processor.receivePayload(
        payload(remoteIdentityId: 'remote-a'),
      );

      expect(result, isA<SelfEncounter>());
      expect(await repo.getAll(), isEmpty);
    });

    test('other identities are unaffected when an own id is set', () async {
      processor = build(ownIdentityId: 'me');

      expect(
        await processor.receivePayload(payload(remoteIdentityId: 'someone')),
        isA<NewEncounter>(),
      );
    });
  });
}
