import 'dart:io';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

void main() {
  test('corrupt opt-in file is treated as off', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_backup_corrupt');
    addTearDown(() => dir.delete(recursive: true));
    final prefs = CloudBackupPreferences.inDirectory(dir);
    await File('${dir.path}/cloud_backup_opt_in.json').writeAsString('not-json');
    expect(await prefs.isEnabled(), isFalse);
  });

  test('cloud backup defaults to off', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_backup');
    addTearDown(() => dir.delete(recursive: true));
    final prefs = CloudBackupPreferences.inDirectory(dir);
    expect(await prefs.isEnabled(), isFalse);
  });

  test('identityToCloudPayload omits private contact fields', () {
    const identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      email: 'secret@example.com',
      bio: 'private bio',
      privacy: {'email': PrivacyFlag(false), 'bio': PrivacyFlag(false)},
    );

    final payload = identityToCloudPayload(identity);

    expect(payload['displayName'], 'Uday');
    expect(payload.containsKey('email'), isFalse);
    expect(payload.containsKey('bio'), isFalse);
  });

  test('identityToCloudPayload includes public contact fields', () {
    const identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      email: 'public@example.com',
      privacy: {'email': PrivacyFlag(true)},
    );

    final payload = identityToCloudPayload(identity);

    expect(payload['email'], 'public@example.com');
  });
}
