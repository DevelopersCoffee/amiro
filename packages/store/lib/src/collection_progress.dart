import 'cosmetic_listing.dart';

/// How much of one numbered series a user has collected.
class CollectionProgress {
  final CosmeticSeries series;
  final int owned;
  final int total;

  const CollectionProgress({
    required this.series,
    required this.owned,
    required this.total,
  });

  bool get isComplete => owned == total;
}

/// Per-series collection progress for [catalog], ordered by series number.
/// Free items count as owned (as in the store); owned ids that are not in
/// [catalog] and items outside any series are ignored.
List<CollectionProgress> collectionProgress(
  List<CosmeticListing> catalog,
  Set<String> ownedIds,
) {
  final bySeries = <int, List<CosmeticListing>>{};
  for (final item in catalog) {
    final series = item.series;
    if (series != null) bySeries.putIfAbsent(series.number, () => []).add(item);
  }

  return [
    for (final number in bySeries.keys.toList()..sort())
      CollectionProgress(
        series: bySeries[number]!.first.series!,
        owned: bySeries[number]!
            .where((c) => c.isFree || ownedIds.contains(c.id))
            .length,
        total: bySeries[number]!.length,
      ),
  ];
}
