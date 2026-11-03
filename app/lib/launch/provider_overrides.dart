import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:discovery/discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';
import 'package:nfc/nfc.dart';

import '../avatar/avatar_providers.dart';
import '../discovery/discovery_providers.dart';
import '../identity/cloud_backup_preferences.dart';
import '../identity/identity_providers.dart';
import '../identity/profile_cloud.dart';
import '../sharing/encounter_share_options.dart';
import '../sharing/sharing_preferences_providers.dart';
import '../sharing/sharing_providers.dart';

/// Provider overrides used at cold start in `main.dart`. Tests use the same
/// wiring so launch behavior matches production.
List<Override> amiroLaunchProviderOverrides({
  required IdentityRepository identityRepository,
  required CloudBackupPreferences cloudBackupPreferences,
  required ProfileCloud profileCloud,
  required AvatarRenderer avatarRenderer,
  required Future<AvatarRenderer> Function() avatarRendererFactory,
  required DiscoveryRepository discoveryRepository,
  required EncounterSharePreferences encounterSharePreferences,
  required NfcEmulator nfcEmulator,
  required NfcReader nfcReader,
}) {
  return [
    identityRepositoryProvider.overrideWithValue(identityRepository),
    cloudBackupPreferencesProvider.overrideWithValue(cloudBackupPreferences),
    encounterSharePreferencesProvider.overrideWithValue(
      encounterSharePreferences,
    ),
    profileCloudProvider.overrideWithValue(profileCloud),
    avatarRendererProvider.overrideWithValue(avatarRenderer),
    avatarRendererFactoryProvider.overrideWithValue(avatarRendererFactory),
    nfcEmulatorProvider.overrideWithValue(nfcEmulator),
    nfcReaderProvider.overrideWithValue(nfcReader),
    discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
  ];
}
