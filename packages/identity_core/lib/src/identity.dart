import 'privacy_flag.dart';

/// A user's Amiro identity: display info, contact fields, and per-field
/// privacy flags controlling what appears on the public profile.
class Identity {
  final String id;
  final String displayName;
  final String username;
  final String? bio;
  final String? mobile;
  final String? email;
  final String? xHandle;
  final String? instagramHandle;
  final String? website;

  /// The user's `AvatarDefinition`, stored as its JSON encoding.
  ///
  /// `identity_core` deliberately does not depend on `avatar_core`: the
  /// definition travels through this layer as opaque JSON, exactly the way
  /// [privacy] does, and is decoded by whoever owns the avatar (the app).
  /// `null` until the user has rendered an avatar for the first time.
  final String? avatarDefinitionJson;

  final Map<String, PrivacyFlag> privacy;

  const Identity({
    required this.id,
    required this.displayName,
    required this.username,
    this.bio,
    this.mobile,
    this.email,
    this.xHandle,
    this.instagramHandle,
    this.website,
    this.avatarDefinitionJson,
    this.privacy = const {},
  });

  Identity copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? mobile,
    String? email,
    String? xHandle,
    String? instagramHandle,
    String? website,
    String? avatarDefinitionJson,
    Map<String, PrivacyFlag>? privacy,
  }) {
    return Identity(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      xHandle: xHandle ?? this.xHandle,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      website: website ?? this.website,
      avatarDefinitionJson: avatarDefinitionJson ?? this.avatarDefinitionJson,
      privacy: privacy ?? this.privacy,
    );
  }

  /// Returns only the string fields whose privacy flag is public.
  Map<String, String> publicFields() {
    final all = <String, String?>{
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'mobile': mobile,
      'email': email,
      'xHandle': xHandle,
      'instagramHandle': instagramHandle,
      'website': website,
    };

    final result = <String, String>{};
    all.forEach((key, value) {
      if (value == null) return;
      final flag = privacy[key];
      // Fields with no explicit flag default to private.
      if (flag != null && flag.isPublic) {
        result[key] = value;
      }
    });
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'bio': bio,
      'mobile': mobile,
      'email': email,
      'xHandle': xHandle,
      'instagramHandle': instagramHandle,
      'website': website,
      'avatarDefinitionJson': avatarDefinitionJson,
      'privacy': privacy.map((key, flag) => MapEntry(key, flag.toJson())),
    };
  }

  factory Identity.fromJson(Map<String, dynamic> json) {
    final privacyJson = (json['privacy'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Identity(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      mobile: json['mobile'] as String?,
      email: json['email'] as String?,
      xHandle: json['xHandle'] as String?,
      instagramHandle: json['instagramHandle'] as String?,
      website: json['website'] as String?,
      avatarDefinitionJson: json['avatarDefinitionJson'] as String?,
      privacy: privacyJson.map(
        (key, value) => MapEntry(key, PrivacyFlag.fromJson(value as bool)),
      ),
    );
  }
}
