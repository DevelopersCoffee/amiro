import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:thermion_flutter/thermion_flutter.dart';

import 'package:identity_core/identity_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';

import 'app.dart';
import 'identity/identity_providers.dart';
import 'avatar/avatar_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final supportDir = await getApplicationSupportDirectory();
  final isar = await openIdentityIsar(directory: supportDir.path);
  final repository = IsarIdentityRepository(isar);

  // `ThermionFlutterPlugin.createViewer()` is a static async factory that
  // initializes the Filament engine and returns a live `ThermionViewer`.
  // Like `openIdentityIsar` above, it only needs to be awaited before
  // `runApp` — it doesn't need a `BuildContext` or a mounted widget tree.
  final viewer = await ThermionFlutterPlugin.createViewer();
  final avatarRenderer = ThermionAvatarRenderer(
    surface: ThermionFilamentSurface(viewer),
  );

  runApp(
    ProviderScope(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repository),
        avatarRendererProvider.overrideWithValue(avatarRenderer),
      ],
      child: const AmiroApp(),
    ),
  );
}
