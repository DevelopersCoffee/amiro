import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';

import '../identity/identity_providers.dart';
import 'avatar_defaults.dart';
import 'avatar_providers.dart';

/// Male default — prefer [defaultAvatarDefinitionForGender] when identity is known.
const defaultAvatarDefinition = AvatarDefinition(
  id: 'default',
  body: 'body_superhero_male',
  hair: 'hair_simple_parted',
  top: 'top_peasant_shirt',
  bottom: 'bottom_peasant_trousers',
  shoes: 'shoes_peasant_boots',
);

/// The definition [ensureAvatarLoaded] loaded, and whether this was the
/// user's first-ever avatar (no persisted definition existed yet) — the
/// signal a screen uses to decide whether to play the first-launch reveal
/// ceremony (see DESIGN.md's Motion section) or just show the avatar.
typedef AvatarLoadResult = ({
  AvatarDefinition? definition,
  bool isFirstReveal,
  /// True when [Identity.avatarGender] is set but the body glb is not shipped yet.
  bool bodyAssetPending,
});

/// Ensures the singleton [AvatarRenderer] has a loaded definition, loading
/// the persisted (or default) one if nothing is loaded yet.
///
/// The renderer is an app-lifetime singleton, but a screen's State is
/// recreated every time the user switches back to its tab. Reloading here
/// would queue a duplicate set of Filament asset loads and reset the UI's
/// idea of what is equipped, so any screen that needs the avatar visible or
/// equippable (Avatar tab, Store tab) should call this rather than loading
/// directly — a call after the first is a no-op that just returns the
/// already-loaded definition (and `isFirstReveal: false`, since there's
/// nothing to reveal a second time).
Future<AvatarLoadResult> ensureAvatarLoaded(WidgetRef ref) async {
  final identity = await ref.read(currentIdentityProvider.future);
  final renderer = ref.read(avatarRendererProvider);

  if (!canRenderAvatarForIdentity(identity)) {
    if (renderer.current != null) {
      await renderer.unload();
    }
    return (
      definition: null,
      isFirstReveal: false,
      bodyAssetPending: true,
    );
  }

  final loaded = renderer.current;
  if (loaded != null) {
    return (
      definition: loaded,
      isFirstReveal: false,
      bodyAssetPending: false,
    );
  }
  final persisted = identity?.avatarDefinitionJson;
  final definition = persisted == null
      ? defaultAvatarDefinitionForGender(resolveAvatarGender(identity))
      : AvatarDefinition.fromJson(
          jsonDecode(persisted) as Map<String, dynamic>,
        );

  await renderer.load(definition);
  await persistAvatarDefinition(ref, definition);
  return (
    definition: definition,
    isFirstReveal: persisted == null,
    bodyAssetPending: false,
  );
}

/// Stores [definition] on the current [Identity], closing the spec's
/// "definition JSON -> render -> swap -> persist" pipeline. No-op when the
/// user hasn't created an identity yet — there's nothing to attach it to.
Future<void> persistAvatarDefinition(
  WidgetRef ref,
  AvatarDefinition definition,
) async {
  final identity = ref.read(currentIdentityProvider).value;
  if (identity == null) return;
  await ref
      .read(currentIdentityProvider.notifier)
      .save(
        identity.copyWith(
          avatarDefinitionJson: jsonEncode(definition.toJson()),
        ),
      );
}
