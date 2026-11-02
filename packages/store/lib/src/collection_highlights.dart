import 'cosmetic_listing.dart';

/// The rarest listing among [collectedIds] (ties go to the higher price), or
/// null when none of them are in [catalog]. Ids not in [catalog] are ignored,
/// so a card from a newer app version can't break an older one.
CosmeticListing? rarestCosmetic(
  List<CosmeticListing> catalog,
  Set<String> collectedIds,
) {
  CosmeticListing? best;
  for (final item in catalog) {
    if (!collectedIds.contains(item.id)) continue;
    if (best == null ||
        item.rarity.index > best.rarity.index ||
        (item.rarity == best.rarity && item.priceCents > best.priceCents)) {
      best = item;
    }
  }
  return best;
}
