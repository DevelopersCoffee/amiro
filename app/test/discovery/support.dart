import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovery/discovery.dart';
import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/avatar/avatar_providers.dart';
import 'package:amiro_app/discovery/discovery_providers.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/theme/amiro_theme.dart';

import '../avatar/fake_avatar_renderer.dart';
import '../identity/in_memory_identity_repository.dart';

const rivieraOptics = EquippedCosmeticInfo(
  id: 'riviera_optics',
  name: 'Riviera Optics',
  seriesId: 'series_1',
  rarity: 'RARE',
);

AmiroSharingPayload payloadFor({
  String id = 'remote-1',
  String name = 'Ada',
  List<EquippedCosmeticInfo> cosmetics = const [rivieraOptics],
  List<SeriesCompletion> completion = const [
    SeriesCompletion(seriesId: 'series_1', currentCount: 1, totalCount: 3),
  ],
}) {
  return AmiroSharingPayload(
    remoteIdentityId: id,
    displayName: name,
    activeAvatarConfig: '{"id":"a","body":"body_superhero_male"}',
    equippedCosmetics: cosmetics,
    collectionCompletion: completion,
  );
}

EncounterQr encounterFor({AmiroSharingPayload? payload, ContactCard? contact}) {
  return EncounterQr(payload ?? payloadFor(), contact);
}

/// Everything an encounter screen needs, with an inspectable passport.
class TestApp {
  final InMemoryDiscoveryRepository passport = InMemoryDiscoveryRepository();
  final Identity identity;

  TestApp({Identity? identity})
    : identity =
          identity ?? Identity(id: 'me', displayName: 'Uday', username: 'uday');

  List<Override> get overrides => [
    identityRepositoryProvider.overrideWithValue(
      InMemoryIdentityRepository(identity),
    ),
    avatarRendererProvider.overrideWithValue(FakeAvatarRenderer()),
    avatarRendererFactoryProvider.overrideWithValue(
      () async => FakeAvatarRenderer(),
    ),
    discoveryRepositoryProvider.overrideWithValue(passport),
  ];

  /// A home screen with one button that opens [screen], so popping is observable.
  Widget host(Widget screen, {List<Override> extra = const []}) {
    return ProviderScope(
      overrides: [...overrides, ...extra],
      child: MaterialApp(
        theme: buildAmiroTheme(loadFonts: false),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => screen)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
