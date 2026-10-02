import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:identity_core/identity_core.dart';

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

/// Resolves which [AvatarDefinition] to load for [identity].
///
/// After a gender change ([afterGenderChange]), the persisted JSON body slot
/// is aligned to [Identity.avatarGender] (same rules as Identity edit save).
AvatarDefinition resolveDefinitionForLoad(
  Identity? identity, {
  required bool afterGenderChange,
}) {
  final gender = resolveAvatarGender(identity);
  final persisted = identity?.avatarDefinitionJson;
  if (persisted == null) {
    return defaultAvatarDefinitionForGender(gender);
  }
  final def = AvatarDefinition.fromJson(
    jsonDecode(persisted) as Map<String, dynamic>,
  );
  if (!afterGenderChange) return def;
  final bodyId = defaultBodyAssetId(gender);
  if (!isBodyAssetAvailable(bodyId)) return def;
  if (def.body == bodyId) return def;
  return def.copyWithSlot('body', bodyId);
}

/// Serializes avatar load/unload so overlapping gender saves cannot interleave
/// gate-pause, destroy, and loadGltf on the singleton viewer.
Future<void> _avatarLoadChain = Future<void>.value();

/// Awaits any in-flight [ensureAvatarLoaded] work (tests / diagnostics).
Future<void> waitForAvatarLoadIdle() => _avatarLoadChain;

/// Ensures the singleton [AvatarRenderer] has a loaded definition, loading
/// the persisted (or default) one if nothing is loaded yet.
///
/// Pass [forceReload: true] after [Identity.avatarGender] changes so a prior
/// unload/pause cycle cannot leave a stale [AvatarRenderer.current] or orphan
/// Filament assets when [current] is already null.
Future<AvatarLoadResult> ensureAvatarLoaded(
  WidgetRef ref, {
  bool forceReload = false,
}) {
  final completer = Completer<AvatarLoadResult>();
  _avatarLoadChain = _avatarLoadChain.then((_) async {
    try {
      completer.complete(
        await _ensureAvatarLoadedOnce(ref, forceReload: forceReload),
      );
    } catch (e, st) {
      completer.completeError(e, st);
    }
  });
  return completer.future;
}

Future<AvatarLoadResult> _ensureAvatarLoadedOnce(
  WidgetRef ref, {
  required bool forceReload,
}) async {
  final identity = await ref.read(currentIdentityProvider.future);
  final renderer = ref.read(avatarRendererProvider);

  if (!canRenderAvatarForIdentity(identity)) {
    await renderer.unload();
    _publishSceneDefinition(ref, null);
    return (
      definition: null,
      isFirstReveal: false,
      bodyAssetPending: true,
    );
  }

  if (forceReload) {
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
  final definition = resolveDefinitionForLoad(
    identity,
    afterGenderChange: forceReload,
  );

  await renderer.load(definition);
  _publishSceneDefinition(ref, definition);
  if (forceReload) {
    ref.read(genderReloadPresentFrameProvider.notifier).set(true);
  }
  await persistAvatarDefinition(ref, definition);
  return (
    definition: definition,
    isFirstReveal: identity?.avatarDefinitionJson == null,
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
