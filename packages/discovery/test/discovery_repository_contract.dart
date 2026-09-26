import 'package:discovery/discovery.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Behaviour every [DiscoveryRepository] must have, whatever its storage.
void discoveryRepositoryContract(
  Future<DiscoveryRepository> Function() create,
) {
  late DiscoveryRepository repo;

  setUp(() async => repo = await create());

  test('starts empty', () async {
    expect(await repo.getAll(), isEmpty);
    expect(await repo.findByRemoteIdentityId('remote-1'), isNull);
  });

  test(
    'a saved record can be listed and found by remote identity id',
    () async {
      final r = record();

      await repo.save(r);

      expect(await repo.getAll(), [r]);
      expect(await repo.findByRemoteIdentityId('remote-1'), r);
    },
  );

  test('finding an unknown remote identity id returns null', () async {
    await repo.save(record());

    expect(await repo.findByRemoteIdentityId('someone-else'), isNull);
  });

  test('saving the same localRecordId replaces the record', () async {
    await repo.save(record());

    await repo.save(
      record().copyWith(
        encounterCount: 2,
        lastEncountered: t0.add(const Duration(hours: 1)),
      ),
    );

    final all = await repo.getAll();
    expect(all, hasLength(1));
    expect(all.single.encounterCount, 2);
  });

  test('two records for one remote identity are rejected', () async {
    await repo.save(record(localRecordId: 'local-1'));

    expect(
      () => repo.save(record(localRecordId: 'local-2')),
      throwsArgumentError,
    );
    expect(await repo.getAll(), hasLength(1));
  });

  test('different identities each get their own record', () async {
    await repo.save(record(localRecordId: 'l-a', remoteIdentityId: 'a'));
    await repo.save(record(localRecordId: 'l-b', remoteIdentityId: 'b'));

    expect(await repo.getAll(), hasLength(2));
    expect((await repo.findByRemoteIdentityId('b'))!.localRecordId, 'l-b');
  });

  test('getAll is ordered by first encounter, oldest first', () async {
    await repo.save(
      record(
        localRecordId: 'l-late',
        remoteIdentityId: 'late',
        firstEncountered: t0.add(const Duration(days: 1)),
      ),
    );
    await repo.save(
      record(
        localRecordId: 'l-early',
        remoteIdentityId: 'early',
        firstEncountered: t0,
      ),
    );

    expect((await repo.getAll()).map((r) => r.remoteIdentityId), [
      'early',
      'late',
    ]);
  });

  test(
    'the list returned by getAll cannot be used to mutate the store',
    () async {
      await repo.save(record());

      final all = await repo.getAll();

      expect(() => all.clear(), throwsUnsupportedError);
      expect(await repo.getAll(), hasLength(1));
    },
  );

  test('delete removes the record and frees the remote identity id', () async {
    await repo.save(record());

    await repo.delete('local-1');

    expect(await repo.getAll(), isEmpty);
    await repo.save(record(localRecordId: 'local-2')); // allowed again
    expect(await repo.getAll(), hasLength(1));
  });

  test('deleting an unknown record is a no-op', () async {
    await repo.save(record());

    await repo.delete('nope');

    expect(await repo.getAll(), hasLength(1));
  });
}
