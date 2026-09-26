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
      id: 'f1',
      slot: 'hair',
      name: 'F1',
      assetId: 'f1',
      priceCents: 100,
      series: founders,
    ),
    CosmeticListing(
      id: 'f2',
      slot: 'hair',
      name: 'F2',
      assetId: 'f2',
      priceCents: 200,
      series: founders,
    ),
    CosmeticListing(
      id: 'f3',
      slot: 'hair',
      name: 'F3',
      assetId: 'f3',
      priceCents: 0,
      series: founders,
    ),
  ];

  test('has one entry per series, ignoring items outside any series', () {
    final progress = collectionProgress(catalog, const {});

    expect(progress, hasLength(1));
    expect(progress.single.series, founders);
    expect(progress.single.total, 3);
  });

  test('counts owned items, and free items in a series count as owned', () {
    final progress = collectionProgress(catalog, const {'f1'}).single;

    expect(progress.owned, 2); // f1 owned + f3 free
    expect(progress.isComplete, isFalse);
  });

  test('is complete once every item in the series is owned', () {
    final progress = collectionProgress(catalog, const {'f1', 'f2'}).single;

    expect(progress.owned, 3);
    expect(progress.isComplete, isTrue);
  });

  test('ignores owned ids that are not in the catalog', () {
    final progress = collectionProgress(catalog, const {'ghost'}).single;

    expect(progress.owned, 1);
  });

  test('orders collections by series number', () {
    const second = CosmeticSeries(2, 'Travel');
    final progress = collectionProgress([
      const CosmeticListing(
        id: 's2',
        slot: 'top',
        name: 'S2',
        assetId: 's2',
        priceCents: 100,
        series: second,
      ),
      ...catalog,
    ], const {});

    expect(progress.map((p) => p.series.number), [1, 2]);
  });

  test('real catalog: every series is reachable and no series is empty', () {
    for (final p in collectionProgress(cosmeticCatalog, const {})) {
      expect(p.total, greaterThan(0), reason: p.series.label);
    }
  });

  group('set completion', () {
    test('isSetComplete matches isComplete', () {
      final partial = collectionProgress(catalog, const {'f1'}).single;
      final full = collectionProgress(catalog, const {'f1', 'f2'}).single;

      expect(partial.isSetComplete, isFalse);
      expect(full.isSetComplete, isTrue);
    });

    test('completedSeries lists only finished series, in order', () {
      const second = CosmeticSeries(2, 'Travel');
      final both = [
        ...catalog,
        const CosmeticListing(
            id: 's2a', slot: 'top', name: 'S2A', assetId: 's2a', priceCents: 100, series: second),
        const CosmeticListing(
            id: 's2b', slot: 'top', name: 'S2B', assetId: 's2b', priceCents: 100, series: second),
      ];

      expect(completedSeries(both, const {'f1', 'f2'}).map((s) => s.number), [1]);
      expect(completedSeries(both, const {'f1', 'f2', 's2a', 's2b'}).map((s) => s.number), [1, 2]);
      expect(completedSeries(both, const {}), isEmpty);
    });

    test('a series of only free items is complete from the start', () {
      const basics = CosmeticSeries(1, 'Basics');
      final freeSeries = [
        const CosmeticListing(
            id: 'x', slot: 'top', name: 'X', assetId: 'x', priceCents: 0, series: basics),
      ];

      expect(completedSeries(freeSeries, const {}), [basics]);
    });
  });
}
