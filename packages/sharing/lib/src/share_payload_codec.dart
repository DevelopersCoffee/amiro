import 'dart:convert';

import 'package:identity_core/identity_core.dart';

import 'shared_profile.dart';

const _kScheme = 'amiro';
const _kHost = 'share';
const _kPayloadVersion = 1;

/// Upper bound on cosmetic ids in a card, on both send and receive, so a QR
/// code stays scannable and a hostile payload can't bloat the profile.
const maxSharedCosmeticIds = 32;

/// Builds the share URI for [identity]: only fields flagged public via
/// [Identity.publicFields] are included. `avatarDefinitionJson` is always
/// included when present — the avatar itself isn't privacy-sensitive the
/// way contact fields are.
String buildShareUri(Identity identity,
    {Set<String> ownedCosmeticIds = const {}}) {
  final public = identity.publicFields();
  final payload = <String, dynamic>{
    'v': _kPayloadVersion,
    'id': identity.id,
    'displayName': identity.displayName,
    'username': identity.username,
    if (public.containsKey('bio')) 'bio': public['bio'],
    if (public.containsKey('email')) 'email': public['email'],
    if (public.containsKey('mobile')) 'mobile': public['mobile'],
    if (public.containsKey('xHandle')) 'xHandle': public['xHandle'],
    if (public.containsKey('instagramHandle'))
      'instagramHandle': public['instagramHandle'],
    if (public.containsKey('website')) 'website': public['website'],
    if (identity.avatarDefinitionJson != null)
      'avatarDefinitionJson': identity.avatarDefinitionJson,
    if (ownedCosmeticIds.isNotEmpty)
      'owned': (ownedCosmeticIds.toList()..sort())
          .take(maxSharedCosmeticIds)
          .toList(),
  };

  final encoded = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$_kScheme://$_kHost?d=$encoded';
}

/// Parses a share URI back into a [SharedProfile]. Returns `null` for any
/// URI that isn't a well-formed `amiro://share` link — callers should
/// treat `null` as "not one of ours", not throw.
SharedProfile? parseShareUri(String uri) {
  final Uri parsed;
  try {
    parsed = Uri.parse(uri);
  } on FormatException {
    return null;
  }

  if (parsed.scheme != _kScheme || parsed.host != _kHost) return null;

  final encoded = parsed.queryParameters['d'];
  if (encoded == null) return null;

  // All field extraction/casting happens inside this try so a malformed
  // payload (e.g. a non-string `id`, or any other field with an
  // unexpected JSON type) fails closed — returns `null` — instead of
  // throwing a `_TypeError` that escapes `parseShareUri` and crashes the
  // caller (a scanned QR/NFC payload is untrusted input).
  try {
    final decodedBytes = base64Url.decode(encoded);
    final json = jsonDecode(utf8.decode(decodedBytes)) as Map<String, dynamic>;

    // Reject anything that isn't a recognized v1 payload — a future
    // `v: 2` shape (different field semantics) must not be silently
    // misparsed as v1 just because the field names happen to overlap.
    if (json['v'] != _kPayloadVersion) return null;

    final id = json['id'] as String?;
    final displayName = json['displayName'] as String?;
    final username = json['username'] as String?;
    if (id == null || displayName == null || username == null) return null;

    return SharedProfile(
      id: id,
      displayName: displayName,
      username: username,
      bio: json['bio'] as String?,
      avatarDefinitionJson: json['avatarDefinitionJson'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      xHandle: json['xHandle'] as String?,
      instagramHandle: json['instagramHandle'] as String?,
      website: json['website'] as String?,
      ownedCosmeticIds: _parseOwned(json['owned']),
    );
  } catch (_) {
    // Catches FormatException (bad base64/JSON), TypeError (a field
    // present with the wrong JSON type, e.g. `"id": 1`), and anything
    // else malformed input could throw — all fail closed to `null`.
    return null;
  }
}

/// A malformed `owned` field is dropped rather than rejecting the whole
/// profile: the collection is decoration, the identity is what matters.
List<String> _parseOwned(Object? raw) {
  if (raw is! List || raw.any((e) => e is! String)) return const [];
  return raw.cast<String>().take(maxSharedCosmeticIds).toList();
}
