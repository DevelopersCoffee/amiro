import 'package:store/store.dart';
import 'package:test/test.dart';

void main() {
  const founders = CosmeticSeries(1, 'Founders');
  const catalog = [
    CosmeticListing(
      id: 'free_a',
      slot: 'top',
      name: 'A',
      assetId: 'a',
      priceCents: 0,
    ),
    CosmeticListing(
      id: 'u1',
      slot: 'hair',
      name: 'U1',
      assetId: 'u1',
      priceCents: 100,
      rarity: CosmeticRarity.uncommon,
      series: founders,
    ),
    CosmeticListing(
      id: 'r1',
      slot: 'glasses',
      name: 'R1',
      assetId: 'r1',
      priceCents: 300,
      rarity: CosmeticRarity.rare,
      series: founders,
    ),
    CosmeticListing(
      id: 'r2',
      slot: 'glasses',
      name: 'R2',
      assetId: 'r2',
      priceCents: 500,
      rarity: CosmeticRarity.rare,
      series: founders,
    ),
  ];

  group('collectedCosmeticIds', () {
    test('is every free item plus the owned ids that exist in the catalog', () {
      expect(collectedCosmeticIds(catalog, const {'u1', 'ghost'}), {
        'free_a',
        'u1',
      });
    });
  });

  group('rarestCosmetic', () {
    test('is null when nothing is collected', () {
      expect(rarestCosmetic(catalog, const {}), isNull);
    });

    test('picks the highest rarity among collected ids', () {
      expect(rarestCosmetic(catalog, const {'free_a', 'u1', 'r1'})!.id, 'r1');
    });

    test('breaks a rarity tie by higher price', () {
      expect(rarestCosmetic(catalog, const {'r1', 'r2'})!.id, 'r2');
    });

    test('ignores ids that are not in the catalog', () {
      expect(rarestCosmetic(catalog, const {'ghost'}), isNull);
    });
  });
}
