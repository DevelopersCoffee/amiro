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
