import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:identity_core/identity_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:nfc/nfc.dart';
import 'package:discovery/discovery.dart';

import 'app.dart';
import 'crash/crash_reporter.dart';
import 'identity/identity_providers.dart';
import 'identity/supabase_profile_cloud.dart';
import 'identity/supabase_public.dart';
import 'avatar/avatar_providers.dart';
import 'discovery/discovery_providers.dart';
import 'sharing/sharing_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportDir = await getApplicationSupportDirectory();
  final ingestUrl = const String.fromEnvironment('AMIRO_CRASH_INGEST_URL');
  installCrashReporting(
    CrashReporter(
      appVersion: '1.0.4+10',
      sinks: [
        FileCrashSink(File('${supportDir.path}/crashes.jsonl')),
        if (ingestUrl.isNotEmpty) HttpCrashSink(Uri.parse(ingestUrl)),
      ],
    ),
  );
  final isar = await openIdentityIsar(directory: supportDir.path);
  final repository = IsarIdentityRepository(isar);
  final profileCloud = SupabaseProfileCloud(
    directory: supportDir,
    projectUrl: Uri.parse(supabaseProjectUrl),
    anonKey: supabaseAnonKey,
  );
  if (await repository.getCurrent() == null) {
    final restored = await profileCloud.pull();
    if (restored != null) await repository.save(restored);
  }

  // Engine construction lives behind `avatar_renderer`'s own factory: per the
  // spec's global constraint, nothing outside `packages/avatar_renderer` may
  // import `thermion_flutter` directly.
  final avatarRenderer = await ThermionAvatarRenderer.create();

  final discoveryRepository =
      FileDiscoveryRepository(File('${supportDir.path}/discovery.json'));

  runApp(
    ProviderScope(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repository),
        profileCloudProvider.overrideWithValue(profileCloud),
        avatarRendererProvider.overrideWithValue(avatarRenderer),
        avatarRendererFactoryProvider.overrideWithValue(
          ThermionAvatarRenderer.create,
        ),
        nfcEmulatorProvider.overrideWithValue(
          Platform.isAndroid ? AndroidNfcEmulator() : NoopNfcEmulator(),
        ),
        nfcReaderProvider.overrideWithValue(ManagerNfcReader()),
        // entitlementStoreProvider is deliberately not overridden: its
        // default is the RevenueCat-backed store, so every purchase goes
        // through Play Billing.
        discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
      ],
      child: const AmiroApp(),
    ),
  );
}
