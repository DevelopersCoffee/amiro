import 'dart:io';

import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:amiro_app/sharing/encounter_share_options.dart';
import 'package:amiro_app/sharing/share_screen.dart';
import 'package:amiro_app/sharing/web_share_preferences.dart';
import 'package:amiro_app/sharing/web_share_providers.dart';
import 'package:amiro_app/theme/amiro_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';
import 'package:nfc/nfc.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/sharing/sharing_preferences_providers.dart';
import 'package:amiro_app/sharing/sharing_providers.dart';
import '../avatar/fake_avatar_renderer.dart';
import '../identity/in_memory_identity_repository.dart';
import '../pump_helpers.dart';
import 'fake_web_share_service.dart';

const _defaultAvatarJson =
    '{"id":"default","body":"body_superhero_male","hair":"hair_simple_parted"}';

Identity _identity() => Identity(
  id: 'id-1',
  displayName: 'Uday',
  username: 'uday',
  avatarDefinitionJson: _defaultAvatarJson,
);

Widget _screen(FakeWebShareService service) {
  final dir = Directory.systemTemp.createTempSync('web_share_test_');
  return ProviderScope(
    overrides: [
      webShareClientProvider.overrideWithValue(service),
      webSharePreferencesProvider.overrideWithValue(
        WebSharePreferences.inDirectory(dir),
      ),
      encounterSharePreferencesProvider.overrideWithValue(
        EncounterSharePreferences.inDirectory(dir),
      ),
      profileCloudProvider.overrideWithValue(const NoopProfileCloud()),
      identityRepositoryProvider.overrideWithValue(
        InMemoryIdentityRepository(_identity()),
      ),
      nfcEmulatorProvider.overrideWithValue(NoopNfcEmulator()),
      avatarRendererProvider.overrideWithValue(FakeAvatarRenderer()),
    ],
    child: MaterialApp(
      theme: buildAmiroTheme(loadFonts: false),
      home: const ShareScreen(),
    ),
  );
}

void main() {
  testWidgets('publish shows consent then stores https link', (tester) async {
    final service = FakeWebShareService();
    await tester.pumpWidget(_screen(service));
    await pumpUntilFound(tester, find.byKey(const Key('webSharePublishButton')));

    await tester.tap(find.byKey(const Key('webSharePublishButton')));
    await pumpShort(tester);
    await tester.tap(find.byKey(const Key('webShareConsentAccept')));
    await tester.pumpAndSettle();

    expect(service.publishCalls, 1);
    expect(find.byKey(const Key('webSharePublishedUri')), findsOneWidget);
    expect(find.textContaining('https://'), findsWidgets);
  });

  testWidgets('revoke clears published uri', (tester) async {
    final service = FakeWebShareService();
    final dir = Directory.systemTemp.createTempSync('web_share_revoke_');
    final prefs = WebSharePreferences.inDirectory(dir);
    await prefs.write(
      const WebShareState(
        consentGiven: true,
        activeToken: 'testtokenabcdefghijklmnopqrst',
        useHttpsForQr: true,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          webShareClientProvider.overrideWithValue(service),
          webSharePreferencesProvider.overrideWithValue(prefs),
          encounterSharePreferencesProvider.overrideWithValue(
            EncounterSharePreferences.inDirectory(dir),
          ),
          profileCloudProvider.overrideWithValue(const NoopProfileCloud()),
          identityRepositoryProvider.overrideWithValue(
            InMemoryIdentityRepository(_identity()),
          ),
          nfcEmulatorProvider.overrideWithValue(NoopNfcEmulator()),
          avatarRendererProvider.overrideWithValue(FakeAvatarRenderer()),
        ],
        child: MaterialApp(
          theme: buildAmiroTheme(loadFonts: false),
          home: const ShareScreen(),
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('webShareRevokeButton')));
    await tester.tap(find.byKey(const Key('webShareRevokeButton')));
    await pumpShort(tester, frames: 20);

    expect(service.revokeCalls, 1);
    expect(find.byKey(const Key('webSharePublishedUri')), findsNothing);
  });
}