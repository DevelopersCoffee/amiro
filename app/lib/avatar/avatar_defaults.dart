import 'package:avatar_core/avatar_core.dart';
import 'package:identity_core/identity_core.dart';

/// Resolves the user's chosen gender, defaulting legacy identities to male.
AvatarGender resolveAvatarGender(Identity? identity) {
  return AvatarGender.fromWireName(identity?.avatarGender) ??
      AvatarGender.male;
}

/// Default equipped look for [gender] using assets that exist today.
AvatarDefinition defaultAvatarDefinitionForGender(AvatarGender gender) {
  final bodyId = defaultBodyAssetId(gender);
  if (!isBodyAssetAvailable(bodyId)) {
    // Female selection is persisted; body mesh lands in a later asset pass.
    return defaultAvatarDefinitionForGender(AvatarGender.male);
  }
  return AvatarDefinition(
    id: 'default',
    body: bodyId,
    hair: 'hair_simple_parted',
    top: 'top_peasant_shirt',
    bottom: 'bottom_peasant_trousers',
    shoes: 'shoes_peasant_boots',
  );
}

/// Whether the 3D renderer can load a body for this identity right now.
bool canRenderAvatarForIdentity(Identity? identity) {
  final gender = resolveAvatarGender(identity);
  return isBodyAssetAvailable(defaultBodyAssetId(gender));
}
