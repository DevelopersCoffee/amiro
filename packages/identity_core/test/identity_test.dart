import 'package:identity_core/identity_core.dart';
import 'package:test/test.dart';

void main() {
  group('Identity', () {
    test('constructs with required fields and defaults', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
      );

      expect(identity.displayName, 'Uday');
      expect(identity.username, 'uday');
      expect(identity.bio, isNull);
      expect(identity.privacy, isEmpty);
    });

    test('copyWith overrides only given fields', () {
      final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
      final updated = identity.copyWith(bio: 'Software Engineer');

      expect(updated.bio, 'Software Engineer');
      expect(updated.displayName, 'Uday');
      expect(updated.id, 'id-1');
    });

    test('toJson/fromJson round trip preserves all fields and privacy map', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'Software Engineer',
        email: 'coffee.devloper@gmail.com',
        privacy: const {
          'email': PrivacyFlag(false),
          'bio': PrivacyFlag(true),
        },
      );

      final restored = Identity.fromJson(identity.toJson());

      expect(restored.id, identity.id);
      expect(restored.displayName, identity.displayName);
      expect(restored.bio, identity.bio);
      expect(restored.email, identity.email);
      expect(restored.privacy['email']!.isPublic, false);
      expect(restored.privacy['bio']!.isPublic, true);
    });

    test('publicFields returns only fields flagged public', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'Software Engineer',
        email: 'coffee.devloper@gmail.com',
        privacy: const {
          'email': PrivacyFlag(false),
          'bio': PrivacyFlag(true),
        },
      );

      final publicFields = identity.publicFields();

      expect(publicFields.containsKey('bio'), isTrue);
      expect(publicFields.containsKey('email'), isFalse);
    });

    test('publicFields excludes every contact field marked private, not just email', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'Software Engineer',
        email: 'coffee.devloper@gmail.com',
        mobile: '+1 555 0100',
        xHandle: '@uday',
        instagramHandle: '@uday.gram',
        website: 'https://uday.example',
        privacy: const {
          'bio': PrivacyFlag(true),
          'email': PrivacyFlag(false),
          'mobile': PrivacyFlag(false),
          'xHandle': PrivacyFlag(false),
          'instagramHandle': PrivacyFlag(false),
          'website': PrivacyFlag(false),
        },
      );

      final publicFields = identity.publicFields();

      expect(publicFields.containsKey('bio'), isTrue);
      expect(publicFields.containsKey('email'), isFalse);
      expect(publicFields.containsKey('mobile'), isFalse);
      expect(publicFields.containsKey('xHandle'), isFalse);
      expect(publicFields.containsKey('instagramHandle'), isFalse);
      expect(publicFields.containsKey('website'), isFalse);
    });
  });
}
