import 'package:avatar_core/avatar_core.dart';
import 'package:store/store.dart';
import 'package:test/test.dart';

void main() {
  group('avatarValuationCents', () {
    test('is zero when no equipped slot has a catalog price', () {
      const definition = AvatarDefinition(
        id: 'default',
        body: 'body_superhero_male',
        glasses: 'glasses_placeholder', // free item
      );

      expect(avatarValuationCents(definition, cosmeticCatalog), 0);
    });

    test('sums the price of every equipped priced item', () {
      const definition = AvatarDefinition(
        id: 'default',
        body: 'body_superhero_male',
        glasses: 'glasses_realistic', // riviera_optics, 299c
        top: 'top_placeholder', // free item
      );

      expect(avatarValuationCents(definition, cosmeticCatalog), 299);
    });

    test('ignores an equipped asset id that is not in the catalog', () {
      const definition = AvatarDefinition(
        id: 'default',
        body: 'body_superhero_male',
        glasses: 'some_future_unlisted_glasses',
      );

      expect(avatarValuationCents(definition, cosmeticCatalog), 0);
    });
  });
}
