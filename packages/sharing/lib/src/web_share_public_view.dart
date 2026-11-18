/// Public fields shown on the web profile — keep in sync with
/// `workers/web-profile/src/public_profile.ts`.
const kWebSharePublicContactKeys = <String>[
  'username',
  'bio',
  'mobile',
  'email',
  'website',
  'xHandle',
  'instagramHandle',
];

const kWebShareCardExtraKeys = <String>[
  'equippedCosmetics',
  'collectionCompletion',
];

Map<String, dynamic> filterWebSharePublicContact(Map<String, dynamic> raw) {
  final out = <String, dynamic>{};
  for (final key in kWebSharePublicContactKeys) {
    final value = raw[key];
    if (value is String && value.isNotEmpty) {
      out[key] = value;
    }
  }
  return out;
}

Map<String, dynamic> filterWebShareCardExtras(Map<String, dynamic> raw) {
  final out = <String, dynamic>{};
  for (final key in kWebShareCardExtraKeys) {
    final value = raw[key];
    if (value != null) {
      out[key] = value;
    }
  }
  return out;
}