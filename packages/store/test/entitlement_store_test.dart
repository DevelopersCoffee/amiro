import 'package:store/store.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryEntitlementStore', () {
    test('starts with no owned cosmetics', () async {
      final store = InMemoryEntitlementStore();
      expect(await store.ownedCosmeticIds(), isEmpty);
    });

    test('granting a cosmetic makes it owned', () async {
      final store = InMemoryEntitlementStore();
      await store.grant('riviera_optics');
      expect(await store.ownedCosmeticIds(), {'riviera_optics'});
    });

    test('granting the same cosmetic twice does not duplicate it', () async {
      final store = InMemoryEntitlementStore();
      await store.grant('riviera_optics');
      await store.grant('riviera_optics');
      expect(await store.ownedCosmeticIds(), {'riviera_optics'});
    });
  });
}
