import 'dart:io';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import 'recording_profile_cloud.dart';

void main() {
  test('write gate skips push when prefs are off even if UI flag is stale', () async {
    final dir = await Directory.systemTemp.createTemp('amiro_c2');
    addTearDown(() => dir.delete(recursive: true));
    final prefs = CloudBackupPreferences.inDirectory(dir);
    await prefs.setEnabled(false);
    final cloud = RecordingProfileCloud();
    const identity = Identity(id: '1', displayName: 'A', username: 'a');

    const uiFlag = false;
    final backupOn = uiFlag || await prefs.isEnabled();
    if (backupOn) {
      await cloud.push(identity);
    }
    expect(cloud.pushCalls, 0);

    await prefs.setEnabled(true);
    final backupOnEnabled = uiFlag || await prefs.isEnabled();
    if (backupOnEnabled) {
      await cloud.push(identity);
    }
    expect(cloud.pushCalls, 1);
  });
}
