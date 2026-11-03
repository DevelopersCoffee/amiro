import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/identity/profile_secrets_store.dart';
import 'package:amiro_app/identity/secret_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingSecretStorage implements SecretStorage {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => throw StateError('keystore down');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('keystore down');
}

class _SlowWriteStorage implements SecretStorage {
  final _inner = InMemorySecretStorage();

  @override
  Future<void> delete(String key) => _inner.delete(key);

  @override
  Future<String?> read(String key) => _inner.read(key);

  @override
  Future<void> write(String key, String value) async {
    await Future<void>.delayed(const Duration(seconds: 5));
    await _inner.write(key, value);
  }
}

class _ReadOkWriteFailStorage implements SecretStorage {
  final _inner = InMemorySecretStorage();

  @override
  Future<void> delete(String key) => _inner.delete(key);

  @override
  Future<String?> read(String key) => _inner.read(key);

  @override
  Future<void> write(String key, String value) async {
    throw StateError('write failed');
  }
}

void main() {
  test('migrate skips secure storage when no legacy files exist', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_secrets_skip');
    addTearDown(() => dir.delete(recursive: true));

    final store = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: _ThrowingSecretStorage(),
    );
    await expectLater(store.migrateFromLegacyPlaintext(), completes);
  });

  test('runProfileSecretsMigrationSafely continues when migration throws', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_secrets_safe');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/supabase_session.json').writeAsString('{}');

    final store = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: _ThrowingSecretStorage(),
    );
    await runProfileSecretsMigrationSafely(store);
    expect(await File('${dir.path}/supabase_session.json').exists(), isTrue);
  });

  test('M3: legacy file remains when secure write fails during migration', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_secrets_m3');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/supabase_session.json').writeAsString('{"x":1}');

    final store = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: _ReadOkWriteFailStorage(),
    );
    await expectLater(store.migrateFromLegacyPlaintext(), throwsStateError);
    expect(await File('${dir.path}/supabase_session.json').exists(), isTrue);
  });

  test('M5: writeRecoveryCode removes legacy plaintext file', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_secrets_m5');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/profile_recovery_code.txt').writeAsString('code123');

    final store = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: InMemorySecretStorage(),
    );
    await store.writeRecoveryCode('code123');
    expect(await File('${dir.path}/profile_recovery_code.txt').exists(), isFalse);
  });

  test('runProfileSecretsMigrationSafely times out without losing legacy file', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_secrets_n1');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/supabase_session.json').writeAsString('{}');

    final store = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: _SlowWriteStorage(),
    );
    final stopwatch = Stopwatch()..start();
    await runProfileSecretsMigrationSafely(
      store,
      timeout: const Duration(milliseconds: 100),
    );
    stopwatch.stop();
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(await File('${dir.path}/supabase_session.json').exists(), isTrue);
  });

  test('removes stale legacy session when secure storage already has a value', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_stale_legacy');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/supabase_session.json').writeAsString('stale');

    final storage = InMemorySecretStorage();
    await storage.write('supabase_session_json', '{"secure":true}');
    final store = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: storage,
    );
    await store.migrateFromLegacyPlaintext();
    expect(await File('${dir.path}/supabase_session.json').exists(), isFalse);
  });

  test('writeSessionJson removes legacy plaintext file', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_secrets_write');
    addTearDown(() => dir.delete(recursive: true));
    await File('${dir.path}/supabase_session.json').writeAsString('legacy');

    final store = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: InMemorySecretStorage(),
    );
    await store.writeSessionJson('{"access_token":"a"}');
    expect(await File('${dir.path}/supabase_session.json').exists(), isFalse);
  });

  test('migrates legacy plaintext session and recovery code', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_secrets');
    addTearDown(() => dir.delete(recursive: true));

    await File('${dir.path}/supabase_session.json').writeAsString(
      jsonEncode({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'user_id': 'user-1',
        'expires_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    await File('${dir.path}/profile_recovery_code.txt').writeAsString('abc123');

    final store = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: InMemorySecretStorage(),
    );
    await store.migrateFromLegacyPlaintext();

    expect(await store.readSessionJson(), isNotNull);
    expect(await store.readRecoveryCode(), 'abc123');
    expect(await File('${dir.path}/supabase_session.json').exists(), isFalse);
    expect(await File('${dir.path}/profile_recovery_code.txt').exists(), isFalse);

    final parsed = sessionJsonFromStored(await store.readSessionJson());
    expect(parsed?['access_token'], 'access');
  });
}
