import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

void main() {
  group('buildShareUri', () {
    test('includes only fields flagged public', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        bio: 'Software Engineer',
        email: 'coffee.devloper@gmail.com',
        privacy: const {
          'bio': PrivacyFlag(true),
          'email': PrivacyFlag(false),
        },
      );

      final uri = buildShareUri(identity);
      final parsed = parseShareUri(uri)!;

      expect(parsed.id, 'id-1');
      expect(parsed.displayName, 'Uday');
      expect(parsed.username, 'uday');
      expect(parsed.bio, 'Software Engineer');
      expect(parsed.email, isNull);
    });

    test('always includes avatarDefinitionJson when present, regardless of privacy flags', () {
      final identity = Identity(
        id: 'id-1',
        displayName: 'Uday',
        username: 'uday',
        avatarDefinitionJson: '{"id":"default","body":"body_superhero_male"}',
      );

      final uri = buildShareUri(identity);
      final parsed = parseShareUri(uri)!;

      expect(parsed.avatarDefinitionJson, '{"id":"default","body":"body_superhero_male"}');
    });

    test('produces a URI with the amiro://share scheme', () {
      final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');
      final uri = buildShareUri(identity);

      expect(uri, startsWith('amiro://share?d='));
    });
  });

  group('parseShareUri', () {
    test('round-trips displayName, username, bio and avatarDefinitionJson', () {
      final identity = Identity(
        id: 'id-2',
        displayName: 'Ada',
        username: 'ada',
        bio: 'Engineer',
        avatarDefinitionJson: '{"id":"x"}',
        privacy: const {'bio': PrivacyFlag(true)},
      );

      final parsed = parseShareUri(buildShareUri(identity))!;

      expect(parsed.id, 'id-2');
      expect(parsed.displayName, 'Ada');
      expect(parsed.username, 'ada');
      expect(parsed.bio, 'Engineer');
      expect(parsed.avatarDefinitionJson, '{"id":"x"}');
    });

    test('returns null for a non-amiro URI', () {
      expect(parseShareUri('https://example.com/foo'), isNull);
    });

    test('returns null for a malformed amiro URI (bad base64)', () {
      expect(parseShareUri('amiro://share?d=not-valid-base64!!!'), isNull);
    });

    test('returns null when the d query parameter is missing', () {
      expect(parseShareUri('amiro://share'), isNull);
    });
  });
}
