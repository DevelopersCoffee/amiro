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
