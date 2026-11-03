import 'dart:io';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/profile_secrets_store.dart';
import 'package:amiro_app/identity/secret_storage.dart';
import 'package:amiro_app/identity/supabase_profile_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

void main() {
  test('push is a no-op when cloud backup is disabled', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_cloud_push');
    addTearDown(() => dir.delete(recursive: true));
    final prefs = CloudBackupPreferences.inDirectory(dir);
    final cloud = SupabaseProfileCloud(
      directory: dir,
      projectUrl: Uri.parse('https://example.supabase.co'),
      anonKey: 'anon-key',
      backupPreferences: prefs,
      secrets: ProfileSecretsStore(
        legacyDirectory: dir,
        secureStorage: InMemorySecretStorage(),
      ),
    );

    const identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      email: 'secret@example.com',
    );

    expect(await cloud.push(identity), isFalse);
  });
}
