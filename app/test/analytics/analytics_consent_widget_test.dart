import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amiro_app/analytics/analytics_preferences.dart';
import 'package:amiro_app/analytics/analytics_providers.dart';
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
  testWidgets('analytics defaults off; consent dialog before opt-in', (
    tester,
  ) async {
    useTallTestViewport(tester);
    final prefs = AnalyticsPreferences.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(
              const Identity(id: 'id-1', displayName: 'A', username: 'a'),
            ),
          ),
          cloudBackupPreferencesProvider.overrideWithValue(
            CloudBackupPreferences.inMemory(),
          ),
          crashUploadPreferencesProvider.overrideWithValue(
            CrashUploadPreferences.inMemory(),
          ),
          crashIngestConfiguredProvider.overrideWithValue(false),
          analyticsPreferencesProvider.overrideWithValue(prefs),
          analyticsIngestConfiguredProvider.overrideWithValue(true),
          profileCloudProvider.overrideWithValue(const NoopProfileCloud()),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.byKey(const Key('analyticsToggle')));

    expect(
      tester.widget<SwitchListTile>(find.byKey(const Key('analyticsToggle'))).value,
      isFalse,
    );

    await tester.ensureVisible(find.byKey(const Key('analyticsToggle')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('analyticsToggle')),
        matching: find.byType(Switch),
      ),
      warnIfMissed: false,
    );
    await pumpShort(tester, frames: 4);
    expect(find.byKey(const Key('analyticsConsentAccept')), findsOneWidget);

    await tester.tap(find.byKey(const Key('analyticsConsentAccept')));
    await pumpShort(tester, frames: 4);

    expect(await prefs.isEnabled(), isTrue);
  });

  testWidgets('turning analytics off stops without dialog', (tester) async {
    useTallTestViewport(tester);
    final prefs = AnalyticsPreferences.inMemory(enabled: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(
              const Identity(id: 'id-1', displayName: 'A', username: 'a'),
            ),
          ),
          cloudBackupPreferencesProvider.overrideWithValue(
            CloudBackupPreferences.inMemory(),
          ),
          analyticsPreferencesProvider.overrideWithValue(prefs),
          analyticsIngestConfiguredProvider.overrideWithValue(true),
          profileCloudProvider.overrideWithValue(const NoopProfileCloud()),
        ],
        child: const MaterialApp(home: IdentityEditScreen()),
      ),
    );
    await tester.pump();
    await pumpUntilFound(tester, find.byKey(const Key('analyticsToggle')));

    await tester.ensureVisible(find.byKey(const Key('analyticsToggle')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('analyticsToggle')),
        matching: find.byType(Switch),
      ),
      warnIfMissed: false,
    );
    await pumpShort(tester, frames: 4);

    expect(await prefs.isEnabled(), isFalse);
    expect(find.byKey(const Key('analyticsConsentAccept')), findsNothing);
  });
}