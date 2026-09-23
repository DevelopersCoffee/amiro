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
