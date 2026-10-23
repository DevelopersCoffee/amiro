import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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