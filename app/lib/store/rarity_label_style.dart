import 'package:flutter/material.dart';
import 'package:store/store.dart';

import '../theme/amiro_theme.dart';

/// Rarity label style: brass from Rare up, muted below (DESIGN.md tokens only).
TextStyle rarityLabelStyle(BuildContext context, CosmeticRarity rarity) {
  final isStandout = rarity.index >= CosmeticRarity.rare.index;
  return Theme.of(context).textTheme.labelSmall!.copyWith(
    color: isStandout ? AmiroColors.primary : AmiroColors.textMuted,
    letterSpacing: 0.48,
  );
}
