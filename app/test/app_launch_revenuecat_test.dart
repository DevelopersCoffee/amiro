import 'dart:io';

import 'package:amiro_app/app.dart';
import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:amiro_app/launch/provider_overrides.dart';
import 'package:amiro_app/sharing/encounter_share_options.dart';
import 'package:amiro_app/store/store_providers.dart';
import 'package:amiro_app/store/store_screen.dart';
import 'package:discovery/discovery.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc/nfc.dart';
import 'package:store/store.dart';

import 'avatar/fake_avatar_renderer.dart';
import 'identity/in_memory_identity_repository.dart';

class _SilentNfcReader implements NfcReader {
  @override
  Stream<String> readIncomingPayload() => const Stream.empty();

  @override
  Future<void> stop() async {}
}

/// R3: cold start uses [amiroLaunchProviderOverrides] and [AmiroRootTabs] keeps
/// the store tab inactive until selected.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');
  final purchasesCalls = <MethodCall>[];

  setUp(() {
    purchasesCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          purchasesCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('R3: launch tab index keeps store screen inactive', () {
    const launchTabIndex = 0;
    final screen = amiroRootTabStoreScreenForIndex(launchTabIndex);
    expect(screen, isA<StoreScreen>());
    expect((screen as StoreScreen).isActive, isFalse);
  });

  test('R3: main launch provider wiring does not configure RevenueCat', () async {
    final supportDir = await Directory.systemTemp.createTemp('amiro_launch');
    addTearDown(() => supportDir.delete(recursive: true));

    final container = ProviderContainer(
      overrides: [
        ...amiroLaunchProviderOverrides(
          identityRepository: InMemoryIdentityRepository(),
          cloudBackupPreferences: CloudBackupPreferences.inMemory(),
          profileCloud: const NoopProfileCloud(),
          avatarRenderer: FakeAvatarRenderer(),
          avatarRendererFactory: () async => FakeAvatarRenderer(),
          discoveryRepository: InMemoryDiscoveryRepository(),
          encounterSharePreferences: EncounterSharePreferences.inDirectory(
            supportDir,
          ),
          nfcEmulator: NoopNfcEmulator(),
          nfcReader: _SilentNfcReader(),
        ),
        entitlementStoreProvider.overrideWithValue(InMemoryEntitlementStore()),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(ownedCosmeticsProvider.future), isEmpty);
    expect(
      purchasesCalls.where((c) => c.method == 'setupPurchases'),
      isEmpty,
      reason: 'Launch overrides must not configure RevenueCat before Store tab',
    );
  });
}
