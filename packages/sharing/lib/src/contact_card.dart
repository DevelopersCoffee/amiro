import 'package:identity_core/identity_core.dart';

/// Longest a single contact field may be, on send and receive.
const maxContactFieldLength = 256;

/// The optional contact half of an identity card: what the user chose to
/// make public, kept apart from [AmiroSharingPayload] so the discovery
/// ledger never stores contact details it doesn't need.
///
/// Every field is optional and follows [Identity.publicFields]: nothing is
/// included unless the user flagged it public.
class ContactCard {
  final String? username;
  final String? bio;
  final String? mobile;
  final String? email;
  final String? xHandle;
  final String? instagramHandle;
  final String? website;

  const ContactCard({
    this.username,
    this.bio,
    this.mobile,
    this.email,
    this.xHandle,
    this.instagramHandle,
    this.website,
  });

  /// The public fields of [identity]. Over-long values are cut to
  /// [maxContactFieldLength] so a QR code can't be blown up by a huge bio.
  factory ContactCard.fromIdentity(Identity identity) {
    final public = identity.publicFields();
    String? field(String key) {
      final value = public[key];
      if (value == null || value.isEmpty) return null;
      return value.length > maxContactFieldLength
          ? value.substring(0, maxContactFieldLength)
          : value;
    }

    return ContactCard(
      username: field('username'),
      bio: field('bio'),
      mobile: field('mobile'),
      email: field('email'),
      xHandle: field('xHandle'),
      instagramHandle: field('instagramHandle'),
      website: field('website'),
    );
  }

  /// Reads a decoded card. Anything malformed is a [FormatException]; unknown
  /// fields from a newer sender are ignored.
  factory ContactCard.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('a contact card must be a JSON object');
    }
    String? field(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String ||
          value.isEmpty ||
          value.length > maxContactFieldLength) {
        throw FormatException(
            'contact field $key must be a non-empty string of at most '
            '$maxContactFieldLength characters');
      }
      return value;
    }

    return ContactCard(
      username: field('username'),
      bio: field('bio'),
      mobile: field('mobile'),
      email: field('email'),
      xHandle: field('xHandle'),
      instagramHandle: field('instagramHandle'),
      website: field('website'),
    );
  }

  bool get isEmpty =>
      username == null &&
      bio == null &&
      mobile == null &&
      email == null &&
      xHandle == null &&
      instagramHandle == null &&
      website == null;

  Map<String, dynamic> toJson() => {
        if (username != null) 'username': username,
        if (bio != null) 'bio': bio,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        if (xHandle != null) 'xHandle': xHandle,
        if (instagramHandle != null) 'instagramHandle': instagramHandle,
        if (website != null) 'website': website,
      };

  @override
  bool operator ==(Object other) =>
      other is ContactCard &&
      other.username == username &&
      other.bio == bio &&
      other.mobile == mobile &&
      other.email == email &&
      other.xHandle == xHandle &&
      other.instagramHandle == instagramHandle &&
      other.website == website;

  @override
  int get hashCode => Object.hash(
      username, bio, mobile, email, xHandle, instagramHandle, website);
}
