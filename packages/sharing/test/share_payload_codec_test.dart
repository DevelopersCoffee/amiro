import 'dart:convert';

import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

/// Builds a raw `amiro://share?d=...` URI from an arbitrary JSON map,
/// bypassing [buildShareUri] entirely — used to construct malformed
/// payloads that a legitimate sender could never produce, to exercise
/// [parseShareUri]'s fail-closed behavior.
String _rawShareUri(Map<String, dynamic> json) {
  final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));
  return 'amiro://share?d=$encoded';
}

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

    test('returns null (fails closed) when a field has the wrong JSON type', () {
      // A non-string `id` would previously throw a _TypeError from the
      // `as String?` cast instead of returning null.
      final uri = _rawShareUri({
        'v': 1,
        'id': 1,
        'displayName': 'Uday',
        'username': 'uday',
      });

      expect(parseShareUri(uri), isNull);
    });

    test('returns null when the version field is missing', () {
      final uri = _rawShareUri({
        'id': 'id-1',
        'displayName': 'Uday',
        'username': 'uday',
      });

      expect(parseShareUri(uri), isNull);
    });

    test('returns null for an unsupported future payload version', () {
      final uri = _rawShareUri({
        'v': 2,
        'id': 'id-1',
        'displayName': 'Uday',
        'username': 'uday',
      });

      expect(parseShareUri(uri), isNull);
    });
  });
}
