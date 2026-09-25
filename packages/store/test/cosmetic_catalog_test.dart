import 'package:store/store.dart';
import 'package:test/test.dart';

void main() {
  test('catalog has exactly 7 free items and 3 priced items', () {
    final free = cosmeticCatalog.where((c) => c.isFree).toList();
    final priced = cosmeticCatalog.where((c) => !c.isFree).toList();

    expect(free, hasLength(7));
    expect(priced, hasLength(3));
  });

  test('every catalog item resolves to a real asset id for its slot', () {
    for (final item in cosmeticCatalog) {
      expect(item.assetId, isNotEmpty);
      expect(item.slot, isNotEmpty);
    }
  });

  test('catalog item ids are unique', () {
    final ids = cosmeticCatalog.map((c) => c.id).toSet();
    expect(ids, hasLength(cosmeticCatalog.length));
  });
}
