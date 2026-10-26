import 'package:avatar_core/avatar_core.dart';
import 'package:identity_core/identity_core.dart';

/// Resolves the user's chosen gender, defaulting legacy identities to male.
AvatarGender resolveAvatarGender(Identity? identity) {
  return AvatarGender.fromWireName(identity?.avatarGender) ??
      AvatarGender.male;
}

/// Male-fitted cuts. They sit on the male head and float on the female body.
const maleFittedHairAssetIds = {'hair_simple_parted', 'hair_buzzed'};

/// Female-fitted cuts. They sit on the female head and sink on the male body.
const femaleFittedHairAssetIds = {'hair_buns'};

/// Default hair for [gender]. [hair_long] stays equipped either way; it was
/// fitted to the male head and is a paid style.
String defaultHairAssetId(AvatarGender gender) {
  return gender == AvatarGender.female ? 'hair_buns' : 'hair_simple_parted';
}

/// Default equipped look for [gender] using assets that exist today.
AvatarDefinition defaultAvatarDefinitionForGender(AvatarGender gender) {
  final bodyId = defaultBodyAssetId(gender);
  if (!isBodyAssetAvailable(bodyId)) {
    return defaultAvatarDefinitionForGender(AvatarGender.male);
  }
  return AvatarDefinition(
    id: 'default',
    body: bodyId,
    hair: defaultHairAssetId(gender),
    top: 'top_peasant_shirt',
    bottom: 'bottom_peasant_trousers',
    shoes: 'shoes_peasant_boots',
  );
}

/// Body, hair, and beard slots that have to change when [gender] changes.
AvatarDefinition alignAvatarToGender(
  AvatarDefinition definition,
  AvatarGender gender,
) {
  var next = definition;
  final bodyId = defaultBodyAssetId(gender);
  if (isBodyAssetAvailable(bodyId) && next.body != bodyId) {
    next = next.copyWithSlot('body', bodyId);
  }
  final hair = next.hair;
  final hairFits = gender == AvatarGender.female
      ? hair != null && !maleFittedHairAssetIds.contains(hair)
      : hair != null && !femaleFittedHairAssetIds.contains(hair);
  if (!hairFits) {
    next = next.copyWithSlot('hair', defaultHairAssetId(gender));
  }
  if (gender == AvatarGender.female && next.facialHair != null) {
    next = next.copyWithSlot('facialHair', null);
  }
  return next;
}

/// Whether the 3D renderer can load a body for this identity right now.
bool canRenderAvatarForIdentity(Identity? identity) {
  final gender = resolveAvatarGender(identity);
  return isBodyAssetAvailable(defaultBodyAssetId(gender));
}
