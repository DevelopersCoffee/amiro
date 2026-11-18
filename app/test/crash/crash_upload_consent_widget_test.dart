import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/crash/crash_providers.dart';
import 'package:amiro_app/crash/crash_upload_preferences.dart';
import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/identity_edit_screen.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:identity_core/identity_core.dart';

import '../identity/in_memory_identity_repository.dart';
import '../pump_helpers.dart';

void main() {
  testWidgets('crash upload toggle defaults off and can opt in', (tester) async {
    useTallTestViewport(tester);
    final prefs = CrashUploadPreferences.inMemory();
    const identity = Identity(id: 'id-1', displayName: 'A', username: 'a');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(identity),
          ),
          cloudBackupPreferencesProvider.overrideWithValue(
            CloudBackupPreferences.inMemory(),
          ),
          crashUploadPreferencesProvider.overrideWithValue(prefs),
          crashIngestConfiguredProvider.overrideWithValue(true),
          profileCloudProvider.overrideWithValue(const NoopProfileCloud()),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.byKey(const Key('crashUploadToggle')));

    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('crashUploadToggle')))
          .value,
      isFalse,
    );

    await tester.ensureVisible(find.byKey(const Key('crashUploadToggle')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('crashUploadToggle')),
        matching: find.byType(Switch),
      ),
      warnIfMissed: false,
    );
    await pumpShort(tester, frames: 4);

    expect(await prefs.isEnabled(), isTrue);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('crashUploadToggle')))
          .value,
      isTrue,
    );
  });
}