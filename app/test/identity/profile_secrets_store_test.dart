import 'dart:io';

import 'package:amiro_app/identity/profile_secrets_store.dart';
import 'package:amiro_app/identity/secret_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('X11: migrateFromLegacyPlaintext imports recovery code and deletes file', () async {
    final dir = Directory.systemTemp.createTempSync('amiro_legacy_migrate');
    final secrets = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: InMemorySecretStorage(),
    );
    final legacyFile = File('${dir.path}/profile_recovery_code.txt');
    await legacyFile.writeAsString('legacy-plaintext-code');

    await secrets.migrateFromLegacyPlaintext();

    expect(await legacyFile.exists(), isFalse);
    expect(await secrets.readRecoveryCode(), 'legacy-plaintext-code');
  });

  test('X11b: clearCloudBackupCredentials deletes legacy recovery plaintext file', () async {
    final dir = Directory.systemTemp.createTempSync('amiro_legacy_clear');
    final secrets = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: InMemorySecretStorage(),
    );
    await secrets.writeSessionJson('{"access_token":"a"}');
    await secrets.writeRecoveryCode('secure-code');
    final legacyFile = File('${dir.path}/profile_recovery_code.txt');
    await legacyFile.writeAsString('leftover-on-disk');

    await secrets.clearCloudBackupCredentials();

    expect(await legacyFile.exists(), isFalse);
    expect(await secrets.readSessionJson(), isNull);
    expect(await secrets.readRecoveryCode(), isNull);
  });
}
