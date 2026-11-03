import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';

import '../pump_helpers.dart';
import 'in_memory_identity_repository.dart';
import 'recording_profile_cloud.dart';

Finder get _cloudBackupSwitch => find.descendant(
  of: find.byKey(const Key('cloudBackupToggle')),
  matching: find.byType(Switch),
);

Future<void> _waitForCloudToggle(WidgetTester tester) async {
  await pumpUntilFound(tester, find.byKey(const Key('cloudBackupToggle')));
}

Future<void> _dismissOpenConsentDialog(WidgetTester tester) async {
  final decline = find.byKey(const Key('cloudBackupConsentDecline'));
  if (decline.evaluate().isEmpty) return;
  await tester.tap(decline);
  await tester.pump();
  await pumpShort(tester, frames: 4);
}

void main() {
  testWidgets('C6: enabling backup shows consent before opt-in is persisted', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final prefs = CloudBackupPreferences.inMemory();
    final cloud = RecordingProfileCloud();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(),
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
    await tester.tap(_cloudBackupSwitch, warnIfMissed: false);
    await pumpShort(tester, frames: 4);

    expect(await prefs.isEnabled(), isFalse, reason: 'C6: no opt-in before consent');
    expect(cloud.pushCalls, 0);

    await pumpUntilFound(
      tester,
      find.byKey(const Key('cloudBackupConsentDecline')),
    );
    expect(await prefs.isEnabled(), isFalse);

    await _dismissOpenConsentDialog(tester);
  });

  testWidgets('C7: Not now keeps backup off and does not push', (tester) async {
    useTallTestViewport(tester);
    final prefs = CloudBackupPreferences.inMemory();
    final cloud = RecordingProfileCloud();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(),
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
    await tester.tap(_cloudBackupSwitch, warnIfMissed: false);
    await pumpUntilFound(
      tester,
      find.byKey(const Key('cloudBackupConsentDecline')),
    );
    await tester.tap(find.byKey(const Key('cloudBackupConsentDecline')));
    await pumpShort(tester, frames: 6);

    expect(await prefs.isEnabled(), isFalse);
    expect(cloud.pushCalls, 0);
    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('cloudBackupToggle'))).value,
      isFalse,
    );
  });
}
