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

  /// The name the completion engine exposes to the visual layer.
  bool get isSetComplete => isComplete;
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

/// The series [ownedIds] has finished, ordered by series number. This is the
/// whole completion engine: what a user has completed is derived from the
/// catalog and their entitlements, never stored, so it cannot drift from them
/// and needs no remote validation. Rewards are local visual treatments (see
/// the identity card's collector's frame).
List<CosmeticSeries> completedSeries(List<CosmeticListing> catalog, Set<String> ownedIds) {
  return [
    for (final progress in collectionProgress(catalog, ownedIds))
      if (progress.isSetComplete) progress.series,
  ];
}
