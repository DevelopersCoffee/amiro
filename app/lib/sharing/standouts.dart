import 'package:sharing/sharing.dart';
import 'package:store/store.dart';

/// Up to [limit] equipped items above Common, rarest first, with their
/// parsed rarity. Items whose rarity this app version does not know are left
/// out rather than guessed at.
List<(EquippedCosmeticInfo, CosmeticRarity)> standoutCosmetics(
  List<EquippedCosmeticInfo> equipped, {
  int limit = 3,
}) {
  final known = [
    for (final item in equipped)
      if (CosmeticRarity.fromWireName(item.rarity) case final rarity?
          when rarity != CosmeticRarity.common)
        (item, rarity),
  ]..sort((a, b) => b.$2.index.compareTo(a.$2.index));
  return known.take(limit).toList();
}
