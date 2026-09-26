/// A received, self-contained share payload — everything needed to render
/// someone else's profile without a network call. See
/// docs/superpowers/specs/2026-09-23-nfc-sharing-design.md §4.
class SharedProfile {
  final String id;
  final String displayName;
  final String username;
  final String? bio;
  final String? avatarDefinitionJson;
  final String? email;
  final String? mobile;
  final String? xHandle;
  final String? instagramHandle;
  final String? website;

  /// Cosmetic ids the sender says they've collected. Self-reported, not
  /// verified — the card is a show-off surface, not proof of ownership.
  final List<String> ownedCosmeticIds;

  const SharedProfile({
    required this.id,
    required this.displayName,
    required this.username,
    this.bio,
    this.avatarDefinitionJson,
    this.email,
    this.mobile,
    this.xHandle,
    this.instagramHandle,
    this.website,
    this.ownedCosmeticIds = const [],
  });
}
