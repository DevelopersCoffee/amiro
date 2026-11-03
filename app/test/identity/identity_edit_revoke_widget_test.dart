import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:identity_core/identity_core.dart';

import '../pump_helpers.dart';
import 'in_memory_identity_repository.dart';
import 'recording_profile_cloud.dart';

Future<void> _waitForCloudToggle(WidgetTester tester) async {
  await pumpUntilFound(tester, find.byKey(const Key('cloudBackupToggle')));
}

void main() {
  testWidgets('failed revoke keeps backup on and shows an error', (tester) async {
    useTallTestViewport(tester);
    final prefs = CloudBackupPreferences.inMemory(enabled: true);
    final cloud = RecordingProfileCloud()
      ..revokeResult = const RevokeBackupResult.failed('Server copy still there');
    const identity = Identity(id: 'id-1', displayName: 'A', username: 'a');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(identity),
          ),
          cloudBackupPreferencesProvider.overrideWithValue(prefs),
          profileCloudProvider.overrideWithValue(cloud),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await _waitForCloudToggle(tester);

    await tester.ensureVisible(find.byKey(const Key('cloudBackupToggle')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('cloudBackupToggle')),
        matching: find.byType(Switch),
      ),
      warnIfMissed: false,
    );
    await pumpUntilFound(tester, find.byKey(const Key('cloudBackupRevokeConfirm')));
    await tester.tap(find.byKey(const Key('cloudBackupRevokeConfirm')));
    await pumpShort(tester, frames: 8);

    expect(await prefs.isEnabled(), isTrue);
    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('cloudBackupToggle'))).value,
      isTrue,
    );
    expect(find.textContaining('Server copy still there'), findsOneWidget);
    expect(find.byKey(const Key('recoveryCode')), findsOneWidget);
  });

  testWidgets('X12: successful revoke clears recovery code from the UI', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final prefs = CloudBackupPreferences.inMemory(enabled: true);
    final cloud = RecordingProfileCloud();
    const identity = Identity(id: 'id-1', displayName: 'A', username: 'a');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(identity),
          ),
          cloudBackupPreferencesProvider.overrideWithValue(prefs),
          profileCloudProvider.overrideWithValue(cloud),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.byKey(const Key('recoveryCode')));
    expect(find.byKey(const Key('recoveryCode')), findsOneWidget);

    await _waitForCloudToggle(tester);
    await tester.ensureVisible(find.byKey(const Key('cloudBackupToggle')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('cloudBackupToggle')),
        matching: find.byType(Switch),
      ),
      warnIfMissed: false,
    );
    await pumpUntilFound(tester, find.byKey(const Key('cloudBackupRevokeConfirm')));
    await tester.tap(find.byKey(const Key('cloudBackupRevokeConfirm')));
    await pumpShort(tester, frames: 8);

    expect(cloud.revokeCalls, 1);
    expect(find.byKey(const Key('recoveryCode')), findsNothing);
  });

  testWidgets('cancel revoke dialog keeps backup on', (tester) async {
    useTallTestViewport(tester);
    final prefs = CloudBackupPreferences.inMemory(enabled: true);
    final cloud = RecordingProfileCloud();
    const identity = Identity(id: 'id-1', displayName: 'A', username: 'a');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(identity),
          ),
          cloudBackupPreferencesProvider.overrideWithValue(prefs),
          profileCloudProvider.overrideWithValue(cloud),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await _waitForCloudToggle(tester);

    await tester.ensureVisible(find.byKey(const Key('cloudBackupToggle')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('cloudBackupToggle')),
        matching: find.byType(Switch),
      ),
      warnIfMissed: false,
    );
    await pumpUntilFound(tester, find.byKey(const Key('cloudBackupRevokeCancel')));
    await tester.tap(find.byKey(const Key('cloudBackupRevokeCancel')));
    await pumpShort(tester, frames: 6);

    expect(cloud.revokeCalls, 0);
    expect(await prefs.isEnabled(), isTrue);
  });
}
