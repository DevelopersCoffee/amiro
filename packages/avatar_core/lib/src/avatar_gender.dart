/// Which humanoid base mesh the user is building toward.
///
/// Stored on [Identity.avatarGender] (identity_core) — not duplicated on
/// [AvatarDefinition], which only holds equipped asset ids for the active body.
enum AvatarGender {
  male,
  female;

  String get wireName => name;

  static AvatarGender? fromWireName(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final gender in values) {
      if (gender.wireName == value) return gender;
    }
    return null;
  }
}

/// Default body asset id for [gender]. Female mesh is not shipped yet — callers
/// must use [isBodyAssetAvailable] before loading.
String defaultBodyAssetId(AvatarGender gender) {
  switch (gender) {
    case AvatarGender.male:
      return 'body_superhero_male';
    case AvatarGender.female:
      return 'body_superhero_female';
  }
}

/// Whether the renderer package ships a glb for [bodyAssetId].
bool isBodyAssetAvailable(String bodyAssetId) {
  switch (bodyAssetId) {
    case 'body_superhero_male':
      return true;
    case 'body_superhero_female':
      // TODO(asset): ship body_superhero_female.glb and list it in avatar_renderer pubspec.
      return false;
    default:
      return false;
  }
}
