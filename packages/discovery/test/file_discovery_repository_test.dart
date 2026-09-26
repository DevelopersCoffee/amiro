import 'dart:io';

import 'package:discovery/discovery.dart';
import 'package:test/test.dart';

import 'discovery_repository_contract.dart';
import 'support.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('discovery_test_');
    file = File('${dir.path}/nested/encounters.json');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  group('FileDiscoveryRepository', () {
    discoveryRepositoryContract(() async {
      final d = Directory.systemTemp.createTempSync('discovery_contract_');
      addTearDown(() => d.deleteSync(recursive: true));
      return FileDiscoveryRepository(File('${d.path}/encounters.json'));
    });

    test('a fresh instance on the same file sees earlier records', () async {
      await FileDiscoveryRepository(file).save(record());

      final restored = await FileDiscoveryRepository(file).getAll();

      expect(restored, [record()]);
    });

    test('an empty file reads as an empty ledger', () async {
      await file.create(recursive: true);

      expect(await FileDiscoveryRepository(file).getAll(), isEmpty);
    });

    test(
      'a corrupt file throws instead of silently reading as empty',
      () async {
        await file.create(recursive: true);
        await file.writeAsString('{not json');

        expect(
          () => FileDiscoveryRepository(file).getAll(),
          throwsFormatException,
        );
      },
    );

    test('a corrupt file is left untouched by a failed save', () async {
      await file.create(recursive: true);
      await file.writeAsString('{not json');

      await expectLater(
        () => FileDiscoveryRepository(file).save(record()),
        throwsFormatException,
      );

      expect(await file.readAsString(), '{not json');
    });

    test('an entry that is not a valid record fails the read', () async {
      await file.create(recursive: true);
      await file.writeAsString('[{"localRecordId":"x"}]');

      expect(
        () => FileDiscoveryRepository(file).getAll(),
        throwsFormatException,
      );
    });

    test('overlapping saves are all kept', () async {
      final repo = FileDiscoveryRepository(file);

      await Future.wait([
        for (var i = 0; i < 25; i++)
          repo.save(record(localRecordId: 'l$i', remoteIdentityId: 'r$i')),
      ]);

      expect(await repo.getAll(), hasLength(25));
    });

    test('a rejected save does not block later ones', () async {
      final repo = FileDiscoveryRepository(file);
      await repo.save(record(localRecordId: 'l1'));

      await expectLater(
        repo.save(record(localRecordId: 'l2')),
        throwsArgumentError,
      );
      await repo.save(record(localRecordId: 'l3', remoteIdentityId: 'other'));

      expect(await repo.getAll(), hasLength(2));
    });

    test('saving leaves no temp file behind', () async {
      await FileDiscoveryRepository(file).save(record());

      expect(file.parent.listSync().map((e) => e.path.split('/').last), [
        'encounters.json',
      ]);
    });
  });
}
