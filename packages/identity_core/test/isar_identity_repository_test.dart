import 'dart:io';

import 'package:identity_core/identity_core.dart';
import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'test_isar_setup.dart';

void main() {
  late Directory tempDir;
  late Isar isar;
  late IsarIdentityRepository repository;

  setUpAll(() async {
    await initializeIsarCoreForTesting();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('identity_core_test');
    isar = await openIdentityIsar(directory: tempDir.path);
    repository = IsarIdentityRepository(isar);
  });

  tearDown(() async {
    await isar.close();
    await tempDir.delete(recursive: true);
  });

  test('getCurrent returns null when nothing saved', () async {
    expect(await repository.getCurrent(), isNull);
  });

  test('save then getCurrent returns the saved identity', () async {
    final identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      bio: 'Software Engineer',
      privacy: const {'bio': PrivacyFlag(true)},
    );

    await repository.save(identity);
    final restored = await repository.getCurrent();

    expect(restored, isNotNull);
    expect(restored!.displayName, 'Uday');
    expect(restored.bio, 'Software Engineer');
    expect(restored.privacy['bio']!.isPublic, true);
  });

  test('save overwrites the previous identity (single-row semantics)', () async {
    await repository.save(Identity(id: 'id-1', displayName: 'Uday', username: 'uday'));
    await repository.save(Identity(id: 'id-1', displayName: 'Uday C', username: 'uday'));

    final restored = await repository.getCurrent();
    expect(restored!.displayName, 'Uday C');
  });

  test('clear removes the saved identity', () async {
    await repository.save(Identity(id: 'id-1', displayName: 'Uday', username: 'uday'));
    await repository.clear();

    expect(await repository.getCurrent(), isNull);
  });
}
