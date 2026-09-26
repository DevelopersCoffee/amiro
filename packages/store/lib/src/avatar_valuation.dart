import 'package:avatar_core/avatar_core.dart';

import 'cosmetic_listing.dart';

/// Sums the catalog price (in cents) of every equipped slot on
/// [definition] that matches a listing in [catalog]. Equipped assets
/// with no matching listing (e.g. `body`, or a future unlisted item)
/// contribute nothing.
int avatarValuationCents(AvatarDefinition definition, List<CosmeticListing> catalog) {
  final byAssetId = {for (final item in catalog) item.assetId: item};

  var total = 0;
  for (final slot in AvatarDefinition.slots) {
    final equippedAssetId = definition.toJson()[slot] as String?;
    if (equippedAssetId == null) continue;
    final listing = byAssetId[equippedAssetId];
    if (listing != null) {
      total += listing.priceCents;
    }
  }
  return total;
}

/// Rarity summary of what an avatar has equipped.
class AvatarRarityScore {
  /// Rarest equipped listed tier, or null when no listed item is equipped.
  final CosmeticRarity? highest;

  /// Equipped listed items per tier; tiers with none are absent.
  final Map<CosmeticRarity, int> counts;

  const AvatarRarityScore({required this.highest, required this.counts});
}

/// Tallies the rarity of every equipped slot on [definition] that matches a
/// listing in [catalog]. Unlisted assets contribute nothing, mirroring
/// [avatarValuationCents].
AvatarRarityScore avatarRarityScore(AvatarDefinition definition, List<CosmeticListing> catalog) {
  final byAssetId = {for (final item in catalog) item.assetId: item};
  final json = definition.toJson();

  final counts = <CosmeticRarity, int>{};
  for (final slot in AvatarDefinition.slots) {
    final listing = byAssetId[json[slot] as String?];
    if (listing == null) continue;
    counts.update(listing.rarity, (n) => n + 1, ifAbsent: () => 1);
  }

  CosmeticRarity? highest;
  for (final rarity in counts.keys) {
    if (highest == null || rarity.index > highest.index) highest = rarity;
  }
  return AvatarRarityScore(highest: highest, counts: counts);
}
