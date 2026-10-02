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

void _publishSceneDefinition(WidgetRef ref, AvatarDefinition? definition) {
  ref.read(avatarSceneDefinitionProvider.notifier).set(definition);
}

/// Ensures the singleton [AvatarRenderer] has a loaded definition, loading
/// the persisted (or default) one if nothing is loaded yet.
///
/// Pass [forceReload: true] after [Identity.avatarGender] changes so a prior
/// unload/pause cycle cannot leave a stale [AvatarRenderer.current].
Future<AvatarLoadResult> ensureAvatarLoaded(
  WidgetRef ref, {
  bool forceReload = false,
}) async {
  final identity = await ref.read(currentIdentityProvider.future);
  final renderer = ref.read(avatarRendererProvider);

  if (!canRenderAvatarForIdentity(identity)) {
    if (renderer.current != null) {
      await renderer.unload();
    }
    _publishSceneDefinition(ref, null);
    return (
      definition: null,
      isFirstReveal: false,
      bodyAssetPending: true,
    );
  }

  if (forceReload && renderer.current != null) {
    await renderer.unload();
  }

  final loaded = renderer.current;
  if (loaded != null && !forceReload) {
    _publishSceneDefinition(ref, loaded);
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
  _publishSceneDefinition(ref, definition);
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
