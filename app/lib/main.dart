import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'package:identity_core/identity_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:nfc/nfc.dart';
import 'package:discovery/discovery.dart';

import 'app.dart';
import 'crash/crash_reporter.dart';
import 'identity/cloud_backup_preferences.dart';
import 'identity/profile_secrets_store.dart';
import 'identity/supabase_profile_cloud.dart';
import 'identity/supabase_public.dart';
import 'launch/provider_overrides.dart';
import 'sharing/encounter_share_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final supportDir = await getApplicationSupportDirectory();
  final ingestUrl = const String.fromEnvironment('AMIRO_CRASH_INGEST_URL');
  installCrashReporting(
    CrashReporter(
      appVersion: '1.0.6+12',
      sinks: [
        FileCrashSink(File('${supportDir.path}/crashes.jsonl')),
        if (ingestUrl.isNotEmpty) HttpCrashSink(Uri.parse(ingestUrl)),
      ],
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
  if (await repository.getCurrent() == null && await backupPreferences.isEnabled()) {
    final restored = await profileCloud.pull();
    if (restored != null) await repository.save(restored);
  }
  final encounterSharePreferences =
      EncounterSharePreferences.inDirectory(supportDir);

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
        profileCloud: profileCloud,
        avatarRenderer: avatarRenderer,
        avatarRendererFactory: ThermionAvatarRenderer.create,
        discoveryRepository: discoveryRepository,
        encounterSharePreferences: encounterSharePreferences,
        nfcEmulator:
            Platform.isAndroid ? AndroidNfcEmulator() : NoopNfcEmulator(),
        nfcReader: ManagerNfcReader(),
      ),
      child: const AmiroApp(),
    ),
  );
}
