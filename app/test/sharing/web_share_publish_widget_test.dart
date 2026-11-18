import 'dart:io';

import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:amiro_app/identity/supabase_public.dart';
import 'package:amiro_app/sharing/encounter_share_options.dart';
import 'package:amiro_app/sharing/share_screen.dart';
import 'package:amiro_app/sharing/web_share_preferences.dart';
import 'package:amiro_app/sharing/web_share_providers.dart';
import 'package:amiro_app/store/store_providers.dart';
import 'package:amiro_app/theme/amiro_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';
import 'package:nfc/nfc.dart';
import 'package:avatar_core/avatar_core.dart';
import 'package:store/store.dart';

import 'package:amiro_app/avatar/avatar_loader.dart';
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

const _cardDefinition = AvatarDefinition(
  id: 'default',
  body: 'body_superhero_male',
  hair: 'hair_simple_parted',
);

const _publishedToken = 'testtokenabcdefghijklmnopqrst';

Identity _identity() => Identity(
  id: 'id-1',
  displayName: 'Uday',
  username: 'uday',
  avatarDefinitionJson: _defaultAvatarJson,
);

/// Supplies initial web-share prefs synchronously so a tap on Publish never
/// opens the consent dialog while [webShareStateProvider] is still loading.
class TestWebShareStateNotifier extends WebShareStateNotifier {
  TestWebShareStateNotifier(this._initial);

  final WebShareState _initial;

  @override
  Future<WebShareState> build() => Future.value(_initial);
}

Future<FakeAvatarRenderer> _loadedRenderer() async {
  final renderer = FakeAvatarRenderer();
  await renderer.load(_cardDefinition);
  return renderer;
}

Widget _shareHarness({
  required FakeWebShareService service,
  required WebSharePreferences prefs,
  required Directory dir,
  required FakeAvatarRenderer renderer,
  required WebShareState initialWebShareState,
}) {
  return ProviderScope(
    overrides: [
      webShareClientProvider.overrideWithValue(service),
      webSharePreferencesProvider.overrideWithValue(prefs),
      webShareStateProvider.overrideWith(
        () => TestWebShareStateNotifier(initialWebShareState),
      ),
      encounterSharePreferencesProvider.overrideWithValue(
        EncounterSharePreferences.inDirectory(dir),
      ),
      profileCloudProvider.overrideWithValue(const NoopProfileCloud()),
      identityRepositoryProvider.overrideWithValue(
        InMemoryIdentityRepository(_identity()),
      ),
      nfcEmulatorProvider.overrideWithValue(NoopNfcEmulator()),
      avatarRendererProvider.overrideWithValue(renderer),
      entitlementStoreProvider.overrideWithValue(InMemoryEntitlementStore()),
    ],
    child: MaterialApp(
      theme: buildAmiroTheme(loadFonts: false),
      home: const ShareScreen(),
    ),
  );
}

void main() {
  setUp(resetAvatarLoadChainForTest);

  testWidgets('publish shows consent then stores https link', (tester) async {
    if (!kWebSharePublishEnabled) {
      return;
    }
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final renderer = await _loadedRenderer();
    final service = FakeWebShareService();
    final dir = Directory.systemTemp.createTempSync('web_share_pub_');
    final prefs = WebSharePreferences.inDirectory(dir);

    await tester.pumpWidget(
      _shareHarness(
        service: service,
        prefs: prefs,
        dir: dir,
        renderer: renderer,
        initialWebShareState: const WebShareState(consentGiven: true),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('shareQrCode')));
    await pumpUntilFound(tester, find.byKey(const Key('webSharePublishButton')));

    await tester.tap(find.byKey(const Key('webSharePublishButton')));
    await pumpUntilFound(tester, find.byKey(const Key('webSharePublishedUri')));

    expect(service.publishCalls, 1);
    expect(find.byKey(const Key('webSharePublishedUri')), findsOneWidget);
    expect(find.textContaining('https://'), findsWidgets);
  });

  testWidgets('revoke clears published uri', (tester) async {
    if (!kWebSharePublishEnabled) {
      return;
    }
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final renderer = await _loadedRenderer();
    final service = FakeWebShareService();
    final dir = Directory.systemTemp.createTempSync('web_share_revoke_');
    final prefs = WebSharePreferences.inDirectory(dir);

    await tester.pumpWidget(
      _shareHarness(
        service: service,
        prefs: prefs,
        dir: dir,
        renderer: renderer,
        initialWebShareState: const WebShareState(
          consentGiven: true,
          activeToken: _publishedToken,
          useHttpsForQr: true,
        ),
      ),
    );
    await pumpUntilFound(tester, find.byKey(const Key('shareQrCode')));
    await pumpUntilFound(tester, find.byKey(const Key('webShareRevokeButton')));
    await tester.tap(find.byKey(const Key('webShareRevokeButton')));
    await pumpUntilAbsent(
      tester,
      find.byKey(const Key('webSharePublishedUri')),
    );

    expect(service.revokeCalls, 1);
    expect(find.byKey(const Key('webSharePublishedUri')), findsNothing);
  });
}