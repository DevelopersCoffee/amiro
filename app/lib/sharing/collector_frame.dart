import 'package:flutter/material.dart';

import 'package:sharing/sharing.dart';

import '../theme/amiro_theme.dart';

/// A card's border. Finishing any series earns the collector's frame: the
/// same 2px brass border DESIGN.md gives an equipped item. It is derived from
/// the completion data on the card itself, so the frame you see on someone
/// else's card is exactly what their collection says. No asset is involved,
/// which is why this is the v1 reward for completing a set.
Border cardBorder(Iterable<SeriesCompletion> completion) {
  final earned = completion.any((series) => series.isComplete);
  return Border.all(
    color: earned ? AmiroColors.primary : AmiroColors.surfaceBorder,
    width: earned ? 2 : 1,
  );
}
