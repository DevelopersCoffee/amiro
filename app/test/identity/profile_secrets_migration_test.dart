import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/identity/profile_secrets_store.dart';
import 'package:amiro_app/identity/secret_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
