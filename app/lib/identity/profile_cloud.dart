import 'package:identity_core/identity_core.dart';

/// Backup of the on-device identity. Local Isar is still what the app reads
/// on launch; this copy is what survives a reinstall or a second phone.
abstract class ProfileCloud {
  /// False for the no-network stand-in used by tests.
  bool get supportsRestore;

  Future<String?> recoveryCode();

  /// Writes [identity]. Returns whether the remote copy was accepted.
  Future<bool> push(Identity identity);

  /// The signed-in device's profile, if this install already has a session
  /// and a row. Null when there is nothing to restore.
  Future<Identity?> pull();

  /// Attaches this install to the profile that was issued [code].
  /// Null when the code matches nothing.
  Future<Identity?> claim(String code);
}

class NoopProfileCloud implements ProfileCloud {
  const NoopProfileCloud();

  @override
  bool get supportsRestore => false;

  @override
  Future<String?> recoveryCode() async => null;

  @override
  Future<bool> push(Identity identity) async => false;

  @override
  Future<Identity?> pull() async => null;

  @override
  Future<Identity?> claim(String code) async => null;
}

/// Fields written to Supabase when the user opts in to cloud backup.
///
/// Always: id, displayName, username, avatarGender, avatarDefinitionJson,
/// and privacy flags. Contact fields (bio, email, …) are included only when
/// their privacy flag is public — private values never leave the device.
Map<String, dynamic> identityToCloudPayload(Identity identity) {
  final json = <String, dynamic>{
    'id': identity.id,
    'displayName': identity.displayName,
    'username': identity.username,
    if (identity.avatarGender != null) 'avatarGender': identity.avatarGender,
    if (identity.avatarDefinitionJson != null)
      'avatarDefinitionJson': identity.avatarDefinitionJson,
    'privacy': identity.privacy.map((key, flag) => MapEntry(key, flag.toJson())),
  };
  for (final entry in identity.publicFields().entries) {
    final key = entry.key;
    if (key == 'displayName' || key == 'username') continue;
    json[key] = entry.value;
  }
  return json;
}

/// Decodes a profile payload from Supabase. Returns null for an empty
/// claim result (`null`) or a body that is not an identity.
Identity? identityFromCloudPayload(Object? payload) {
  if (payload is! Map) return null;
  final json = Map<String, dynamic>.from(payload);
  if (json['id'] is! String) return null;
  if (json['displayName'] is! String || json['username'] is! String) {
    return null;
  }
  return Identity.fromJson(json);
}
