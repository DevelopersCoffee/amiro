import 'dart:convert';

import 'package:identity_core/identity_core.dart';

import 'shared_profile.dart';

const _kScheme = 'amiro';
const _kHost = 'share';
const _kPayloadVersion = 1;

/// Builds the share URI for [identity]: only fields flagged public via
/// [Identity.publicFields] are included. `avatarDefinitionJson` is always
/// included when present — the avatar itself isn't privacy-sensitive the
/// way contact fields are.
String buildShareUri(Identity identity) {
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

  final Map<String, dynamic> json;
  try {
    final decodedBytes = base64Url.decode(encoded);
    json = jsonDecode(utf8.decode(decodedBytes)) as Map<String, dynamic>;
  } on FormatException {
    return null;
  } catch (_) {
    return null;
  }

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
  );
}
