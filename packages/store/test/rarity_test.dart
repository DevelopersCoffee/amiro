import 'package:avatar_core/avatar_core.dart';
import 'package:store/store.dart';
import 'package:test/test.dart';

void main() {
  group('CosmeticRarity', () {
    test('is ordered from common up to legendary', () {
      expect(CosmeticRarity.values, [
        CosmeticRarity.common,
        CosmeticRarity.uncommon,
        CosmeticRarity.rare,
        CosmeticRarity.epic,
        CosmeticRarity.legendary,
      ]);
    });

    test('has a human label per tier', () {
      expect(CosmeticRarity.common.label, 'Common');
      expect(CosmeticRarity.legendary.label, 'Legendary');
    });
  });

  group('catalog rarity and series invariants', () {
    test('every free item is common', () {
      for (final item in cosmeticCatalog.where((c) => c.isFree)) {
        expect(item.rarity, CosmeticRarity.common, reason: item.id);
      }
    });

    test('rarity never decreases as price increases', () {
      final byPrice = [...cosmeticCatalog]..sort((a, b) => a.priceCents.compareTo(b.priceCents));
      for (var i = 1; i < byPrice.length; i++) {
        expect(
          byPrice[i].rarity.index >= byPrice[i - 1].rarity.index ||
              byPrice[i].priceCents == byPrice[i - 1].priceCents,
          isTrue,
          reason: '${byPrice[i].id} vs ${byPrice[i - 1].id}',
        );
      }
    });

    test('series numbers are positive and every series has a name', () {
      for (final item in cosmeticCatalog.where((c) => c.series != null)) {
        expect(item.series!.number, greaterThan(0), reason: item.id);
        expect(item.series!.name, isNotEmpty, reason: item.id);
      }
    });

    test('items sharing a series number share its name', () {
      final names = <int, String>{};
      for (final s in cosmeticCatalog.map((c) => c.series).whereType<CosmeticSeries>()) {
        expect(names.putIfAbsent(s.number, () => s.name), s.name);
      }
    });

    test('series numbers are contiguous from 1', () {
      final numbers = cosmeticCatalog
          .map((c) => c.series?.number)
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();
      expect(numbers, [for (var i = 1; i <= numbers.length; i++) i]);
    });
  });

  group('avatarRarityScore', () {
    test('is null highest and empty counts when nothing listed is equipped', () {
      const definition = AvatarDefinition(id: 'default', body: 'body_superhero_male');

      final score = avatarRarityScore(definition, cosmeticCatalog);

      expect(score.highest, isNull);
      expect(score.counts, isEmpty);
    });

    test('reports the highest equipped tier and per-tier counts', () {
      const definition = AvatarDefinition(
        id: 'default',
        body: 'body_superhero_male',
        glasses: 'glasses_realistic', // rare
        top: 'top_placeholder', // common
      );

      final score = avatarRarityScore(definition, cosmeticCatalog);

      expect(score.highest, CosmeticRarity.rare);
      expect(score.counts, {CosmeticRarity.rare: 1, CosmeticRarity.common: 1});
    });

    test('ignores an equipped asset id that is not in the catalog', () {
      const definition = AvatarDefinition(
        id: 'default',
        body: 'body_superhero_male',
        glasses: 'some_future_unlisted_glasses',
      );

      expect(avatarRarityScore(definition, cosmeticCatalog).highest, isNull);
    });
  });

  group('wire names', () {
    test('rarity round-trips through its upper-case wire name', () {
      for (final r in CosmeticRarity.values) {
        expect(CosmeticRarity.fromWireName(r.wireName), r);
      }
      expect(CosmeticRarity.rare.wireName, 'RARE');
    });

    test('an unknown or differently-cased wire name is null, not a guess', () {
      expect(CosmeticRarity.fromWireName('MYTHIC'), isNull);
      expect(CosmeticRarity.fromWireName('rare'), isNull);
      expect(CosmeticRarity.fromWireName(''), isNull);
    });

    test('a series id is stable and derived from its number', () {
      expect(const CosmeticSeries(1, 'Founders').id, 'series_1');
      expect(const CosmeticSeries(12, 'X').id, 'series_12');
    });
  });
}
