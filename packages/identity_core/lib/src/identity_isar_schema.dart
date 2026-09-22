import 'package:isar/isar.dart';

part 'identity_isar_schema.g.dart';

@collection
class IdentityRecord {
  Id isarId = 0; // fixed id: single-row table for the device's one identity

  late String id;
  late String displayName;
  late String username;
  String? bio;
  String? mobile;
  String? email;
  String? xHandle;
  String? instagramHandle;
  String? website;
  /// JSON-encoded `AvatarDefinition`, or null before the user's first render.
  String? avatarDefinitionJson;

  /// JSON-encoded `Map<String, bool>` of field name -> isPublic.
  late String privacyJson;
}
