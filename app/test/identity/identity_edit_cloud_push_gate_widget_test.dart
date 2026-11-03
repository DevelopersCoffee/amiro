import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';

import '../pump_helpers.dart';
import 'in_memory_identity_repository.dart';
import 'recording_profile_cloud.dart';

/// C2: [_write] must not push when prefs are off and the UI toggle is off.
void main() {
  testWidgets('C2: save does not push when cloud backup prefs are off', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final prefs = CloudBackupPreferences.inMemory(enabled: false);
    final cloud = RecordingProfileCloud(supportsRestoreValue: false);
    final repo = InMemoryIdentityRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(repo),
          cloudBackupPreferencesProvider.overrideWithValue(prefs),
          profileCloudProvider.overrideWithValue(cloud),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.byKey(const Key('displayNameField')));

    await tester.enterText(find.byKey(const Key('displayNameField')), 'A');
    await tester.enterText(find.byKey(const Key('usernameField')), 'a');
    await tester.ensureVisible(find.byKey(const Key('saveButton')));
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pump();

    expect(cloud.pushCalls, 0);
    expect(await prefs.isEnabled(), isFalse);
  });
}
