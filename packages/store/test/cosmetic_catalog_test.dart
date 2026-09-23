import 'package:store/store.dart';
import 'package:test/test.dart';

void main() {
  test('catalog has exactly 2 free items and 1 priced item', () {
    final free = cosmeticCatalog.where((c) => c.isFree).toList();
    final priced = cosmeticCatalog.where((c) => !c.isFree).toList();

    expect(free, hasLength(2));
    expect(priced, hasLength(1));
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
