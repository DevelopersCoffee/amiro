import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:discovery/discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:identity_core/identity_core.dart';
import 'package:nfc/nfc.dart';

import '../avatar/avatar_providers.dart';
import '../discovery/discovery_providers.dart';
import '../analytics/analytics_install_id.dart';
import '../analytics/analytics_once.dart';
import '../analytics/analytics_preferences.dart';
import '../analytics/analytics_providers.dart';
import '../analytics/analytics_sink.dart';
import '../crash/crash_providers.dart';
import '../crash/crash_upload_preferences.dart';
import '../identity/cloud_backup_preferences.dart';
import '../identity/identity_providers.dart';
import '../identity/profile_cloud.dart';
import '../sharing/encounter_share_options.dart';
import '../sharing/sharing_preferences_providers.dart';
import '../sharing/sharing_providers.dart';
import '../sharing/web_share_preferences.dart';
import '../sharing/web_share_providers.dart';

/// Provider overrides used at cold start in `main.dart`. Tests use the same
/// wiring so launch behavior matches production.
List<Override> amiroLaunchProviderOverrides({
  required IdentityRepository identityRepository,
  required CloudBackupPreferences cloudBackupPreferences,
  required CrashUploadPreferences crashUploadPreferences,
  required AnalyticsPreferences analyticsPreferences,
  required AnalyticsInstallIdStore analyticsInstallIdStore,
  required AnalyticsOnceStore analyticsOnceStore,
  required List<AnalyticsSink> analyticsSinks,
  required ProfileCloud profileCloud,
  required AvatarRenderer avatarRenderer,
  required Future<AvatarRenderer> Function() avatarRendererFactory,
  required DiscoveryRepository discoveryRepository,
  required EncounterSharePreferences encounterSharePreferences,
  required WebSharePreferences webSharePreferences,
  required NfcEmulator nfcEmulator,
  required NfcReader nfcReader,
}) {
  return [
    identityRepositoryProvider.overrideWithValue(identityRepository),
    cloudBackupPreferencesProvider.overrideWithValue(cloudBackupPreferences),
    crashUploadPreferencesProvider.overrideWithValue(crashUploadPreferences),
    analyticsPreferencesProvider.overrideWithValue(analyticsPreferences),
    analyticsInstallIdStoreProvider.overrideWithValue(analyticsInstallIdStore),
    analyticsOnceStoreProvider.overrideWithValue(analyticsOnceStore),
    analyticsSinksProvider.overrideWithValue(analyticsSinks),
    encounterSharePreferencesProvider.overrideWithValue(
      encounterSharePreferences,
    ),
    webSharePreferencesProvider.overrideWithValue(webSharePreferences),
    profileCloudProvider.overrideWithValue(profileCloud),
    avatarRendererProvider.overrideWithValue(avatarRenderer),
    avatarRendererFactoryProvider.overrideWithValue(avatarRendererFactory),
    nfcEmulatorProvider.overrideWithValue(nfcEmulator),
    nfcReaderProvider.overrideWithValue(nfcReader),
    discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
  ];
}
