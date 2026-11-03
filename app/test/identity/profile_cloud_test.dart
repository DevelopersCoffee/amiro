import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

void main() {
  test('cloud payload omits private contact fields', () {
    final identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      email: 'secret@example.com',
      bio: 'hidden',
      mobile: '555',
      xHandle: '@x',
      instagramHandle: '@ig',
      website: 'https://public.example',
      privacy: {
        'email': const PrivacyFlag(false),
        'bio': const PrivacyFlag(false),
        'mobile': const PrivacyFlag(false),
        'xHandle': const PrivacyFlag(false),
        'instagramHandle': const PrivacyFlag(false),
        'website': const PrivacyFlag(true),
      },
    );
    final payload = identityToCloudPayload(identity);
    expect(payload.containsKey('email'), isFalse);
    expect(payload.containsKey('bio'), isFalse);
    expect(payload.containsKey('mobile'), isFalse);
    expect(payload.containsKey('xHandle'), isFalse);
    expect(payload.containsKey('instagramHandle'), isFalse);
    expect(payload['website'], 'https://public.example');
  });

  test('identity payload decodes and an empty claim does not', () {
    expect(identityFromCloudPayload(null), isNull);
    expect(
      identityFromCloudPayload({
        'id': 'abc',
        'displayName': 'Uday',
        'username': 'uday',
        'bio': null,
        'mobile': null,
        'email': null,
        'xHandle': null,
        'instagramHandle': null,
        'website': null,
        'avatarGender': 'male',
        'avatarDefinitionJson': null,
        'privacy': {'email': false},
      })!.displayName,
      'Uday',
    );
  });
}