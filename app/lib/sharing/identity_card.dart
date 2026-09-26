import 'package:flutter/material.dart';

import 'package:amiro_qr/amiro_qr.dart';
import 'package:sharing/sharing.dart';
import 'package:store/store.dart';

import '../store/rarity_label_style.dart';
import '../store/series_progress_row.dart';
import '../theme/amiro_theme.dart';
import 'own_encounter.dart';

const _maxStandouts = 3;

/// The artifact a user shows another person: avatar, name, what makes their
/// look distinctive, how far through each series they are, and a QR code.
///
/// Purely presentational. It draws the [payload] it is given and has no
/// provider, repository or discovery dependency; what you see on the card
/// is exactly what the payload carries.
class IdentityCard extends StatelessWidget {
  final AmiroSharingPayload payload;

  /// The 3D avatar view, supplied by the caller (the card doesn't own a renderer).
  final Widget avatar;
  final String qrData;

  const IdentityCard({
    super.key,
    required this.payload,
    required this.avatar,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final standouts = _standouts(payload.equippedCosmetics);
    final series = progressFromCompletion(
      payload.collectionCompletion,
    ).where((p) => p.owned > 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AmiroColors.surface,
        border: Border.all(color: AmiroColors.surfaceBorder),
        borderRadius: BorderRadius.circular(16),
        // A real offset shadow (DESIGN.md), never a glow.
        boxShadow: const [
          BoxShadow(
            color: Color(0xB3000000),
            offset: Offset(0, 24),
            blurRadius: 40,
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMIRO',
            style: textTheme.labelSmall?.copyWith(
              color: AmiroColors.textMuted,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 220, child: avatar),
          const SizedBox(height: 16),
          Text(payload.displayName, style: textTheme.headlineSmall),
          for (final (item, rarity) in standouts) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(item.name)),
                Text(rarity.label, style: rarityLabelStyle(context, rarity)),
              ],
            ),
          ],
          for (final progress in series) ...[
            const SizedBox(height: 8),
            SeriesProgressRow(progress),
          ],
          const SizedBox(height: 20),
          Center(key: const Key('shareQrCode'), child: buildQrWidget(qrData)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Tap or scan to discover',
              style: textTheme.labelMedium?.copyWith(
                color: AmiroColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Up to [_maxStandouts] equipped items above Common, rarest first. Items
/// whose rarity this app version does not know are left out.
List<(EquippedCosmeticInfo, CosmeticRarity)> _standouts(
  List<EquippedCosmeticInfo> equipped,
) {
  final known = [
    for (final item in equipped)
      if (CosmeticRarity.fromWireName(item.rarity) case final rarity?
          when rarity != CosmeticRarity.common)
        (item, rarity),
  ]..sort((a, b) => b.$2.index.compareTo(a.$2.index));
  return known.take(_maxStandouts).toList();
}
