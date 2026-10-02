import 'package:isar_community/isar.dart';

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
  /// `AvatarGender.wireName` (`male` / `female`), or null until the user chooses.
  ///
  /// After editing this schema, regenerate `identity_isar_schema.g.dart` per
  /// the note in `packages/identity_core/pubspec.yaml` (manual patch in this PR).
  String? avatarGender;
  /// JSON-encoded `AvatarDefinition`, or null before the user's first render.
  String? avatarDefinitionJson;

  /// JSON-encoded `Map<String, bool>` of field name -> isPublic.
  late String privacyJson;
}
