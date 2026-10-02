import 'package:avatar_core/avatar_core.dart';
import 'package:test/test.dart';

void main() {
  group('AvatarGender', () {
    test('round-trips wire names', () {
      expect(AvatarGender.fromWireName('male'), AvatarGender.male);
      expect(AvatarGender.fromWireName('female'), AvatarGender.female);
      expect(AvatarGender.fromWireName('other'), isNull);
    });

    test('default body ids and availability', () {
      expect(defaultBodyAssetId(AvatarGender.male), 'body_superhero_male');
      expect(isBodyAssetAvailable('body_superhero_male'), isTrue);
      expect(defaultBodyAssetId(AvatarGender.female), 'body_superhero_female');
      expect(isBodyAssetAvailable('body_superhero_female'), isFalse);
    });
  });
}
