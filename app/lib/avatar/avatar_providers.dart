import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_renderer/avatar_renderer.dart';

/// Overridden in `main.dart` with a real [ThermionAvatarRenderer];
/// overridden in tests with a fake [AvatarRenderer].
///
/// This is an app-lifetime singleton — it backs `AvatarScreen`'s view of
/// the user's own avatar and must never be handed someone else's
/// definition (see `avatarRendererFactoryProvider` below for that case).
final avatarRendererProvider = Provider<AvatarRenderer>((ref) {
  throw UnimplementedError('avatarRendererProvider must be overridden');
});

/// Factory for a fresh, screen-scoped [AvatarRenderer] instance — for
/// anywhere that needs to render an avatar without touching the
/// app-lifetime singleton behind [avatarRendererProvider]. The only
/// current caller is `SharedProfileScreen`, which previews a scanned
/// stranger's avatar: calling `load()` on the shared singleton for that
/// would bleed the stranger's meshes into the user's own live scene and
/// corrupt `AvatarScreen`'s re-entry guard. Overridden in `main.dart` with
/// `ThermionAvatarRenderer.create`; overridden in tests with a fake
/// factory.
final avatarRendererFactoryProvider =
    Provider<Future<AvatarRenderer> Function()>((ref) {
      throw UnimplementedError(
        'avatarRendererFactoryProvider must be overridden',
      );
    });
