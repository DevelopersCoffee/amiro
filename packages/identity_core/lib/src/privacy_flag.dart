/// Whether a single identity field is visible in the public profile.
class PrivacyFlag {
  final bool isPublic;

  const PrivacyFlag(this.isPublic);

  factory PrivacyFlag.fromJson(bool json) => PrivacyFlag(json);

  bool toJson() => isPublic;
}
