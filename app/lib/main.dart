import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'package:identity_core/identity_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:nfc/nfc.dart';
import 'package:discovery/discovery.dart';

import 'app.dart';
import 'analytics/analytics_install_id.dart';
import 'analytics/analytics_once.dart';
import 'analytics/analytics_preferences.dart';
import 'analytics/analytics_ingest.dart';
import 'crash/crash_reporter.dart';
import 'crash/crash_upload_throttle.dart';
import 'crash/crash_upload_throttle_store.dart';
import 'crash/crash_upload_preferences.dart';
import 'identity/cloud_backup_preferences.dart';
import 'identity/profile_secrets_store.dart';
import 'identity/supabase_profile_cloud.dart';
import 'identity/supabase_public.dart';
import 'launch/provider_overrides.dart';
import 'launch/startup_cloud_restore.dart';
import 'sharing/encounter_share_options.dart';
import 'sharing/web_share_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final supportDir = await getApplicationSupportDirectory();
  final ingestUrl = const String.fromEnvironment('AMIRO_CRASH_INGEST_URL');
  final crashUploadPreferences =
      CrashUploadPreferences.inDirectory(supportDir);
  final crashSinks = <CrashSink>[
    FileCrashSink(File('${supportDir.path}/crashes.jsonl')),
  ];
  final crashUploadThrottle = CrashUploadThrottle(
    store: CrashUploadThrottleStore.inDirectory(supportDir),
  );
  if (ingestUrl.isNotEmpty) {
    final ingestUri = Uri.tryParse(ingestUrl);
    if (ingestUri == null) {
      debugPrint('AMIRO_CRASH_INGEST_URL is invalid; crash upload disabled.');
    } else if (ingestUri.scheme == 'https') {
      crashSinks.add(
        ConsentGatedHttpCrashSink(
          crashUploadPreferences,
          crashUploadThrottle,
          HttpCrashSink(ingestUri),
        ),
      );
    } else if (!kReleaseMode) {
      crashSinks.add(
        ConsentGatedHttpCrashSink(
          crashUploadPreferences,
          crashUploadThrottle,
          HttpCrashSink(ingestUri, allowInsecureHttp: true),
        ),
      );
    } else {
      debugPrint(
        'AMIRO_CRASH_INGEST_URL must use https in release builds; crash upload disabled.',
      );
    }
  }
  installCrashReporting(
    CrashReporter(
      appVersion: '1.0.6+12',
      sinks: crashSinks,
    ),
  );
  final isar = await openIdentityIsar(directory: supportDir.path);
  final repository = IsarIdentityRepository(isar);
  final backupPreferences = CloudBackupPreferences.inDirectory(supportDir);
  final profileSecrets = ProfileSecretsStore(legacyDirectory: supportDir);
  await runProfileSecretsMigrationSafely(profileSecrets);
  final profileCloud = SupabaseProfileCloud(
    directory: supportDir,
    projectUrl: Uri.parse(supabaseProjectUrl),
    anonKey: supabaseAnonKey,
    backupPreferences: backupPreferences,
    secrets: profileSecrets,
  );
  await tryRestoreIdentityFromCloud(
    getCurrent: repository.getCurrent,
    isBackupEnabled: backupPreferences.isEnabled,
    pull: profileCloud.pull,
    save: repository.save,
  );
  final encounterSharePreferences =
      EncounterSharePreferences.inDirectory(supportDir);
  final webSharePreferences = WebSharePreferences.inDirectory(supportDir);
  final analyticsPreferences = AnalyticsPreferences.inDirectory(supportDir);
  final analyticsInstallId = AnalyticsInstallIdStore.inDirectory(supportDir);
  final analyticsOnce = AnalyticsOnceStore.inDirectory(supportDir);
  final analyticsIngestUrl =
      const String.fromEnvironment('AMIRO_ANALYTICS_INGEST_URL');
  final analyticsSinks = analyticsSinksFromIngestUrl(analyticsIngestUrl);

  // Engine construction lives behind `avatar_renderer`'s own factory: per the
  // spec's global constraint, nothing outside `packages/avatar_renderer` may
  // import `thermion_flutter` directly.
  final avatarRenderer = await ThermionAvatarRenderer.create();

  final discoveryRepository =
      FileDiscoveryRepository(File('${supportDir.path}/discovery.json'));

  runApp(
    ProviderScope(
      overrides: amiroLaunchProviderOverrides(
        identityRepository: repository,
        cloudBackupPreferences: backupPreferences,
        crashUploadPreferences: crashUploadPreferences,
        analyticsPreferences: analyticsPreferences,
        analyticsInstallIdStore: analyticsInstallId,
        analyticsOnceStore: analyticsOnce,
        analyticsSinks: analyticsSinks,
        profileCloud: profileCloud,
        avatarRenderer: avatarRenderer,
        avatarRendererFactory: ThermionAvatarRenderer.create,
        discoveryRepository: discoveryRepository,
        encounterSharePreferences: encounterSharePreferences,
        webSharePreferences: webSharePreferences,
        nfcEmulator:
            Platform.isAndroid ? AndroidNfcEmulator() : NoopNfcEmulator(),
        nfcReader: ManagerNfcReader(),
      ),
      child: const AmiroApp(),
    ),
  );
}
