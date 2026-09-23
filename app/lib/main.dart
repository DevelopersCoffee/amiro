import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:identity_core/identity_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:nfc/nfc.dart';

import 'app.dart';
import 'identity/identity_providers.dart';
import 'avatar/avatar_providers.dart';
import 'sharing/sharing_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportDir = await getApplicationSupportDirectory();
  final isar = await openIdentityIsar(directory: supportDir.path);
  final repository = IsarIdentityRepository(isar);

  // Engine construction lives behind `avatar_renderer`'s own factory: per the
  // spec's global constraint, nothing outside `packages/avatar_renderer` may
  // import `thermion_flutter` directly.
  final avatarRenderer = await ThermionAvatarRenderer.create();

  runApp(
    ProviderScope(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repository),
        avatarRendererProvider.overrideWithValue(avatarRenderer),
        avatarRendererFactoryProvider.overrideWithValue(
          ThermionAvatarRenderer.create,
        ),
        nfcEmulatorProvider.overrideWithValue(
          Platform.isAndroid ? AndroidNfcEmulator() : NoopNfcEmulator(),
        ),
        nfcReaderProvider.overrideWithValue(ManagerNfcReader()),
      ],
      child: const AmiroApp(),
    ),
  );
}
