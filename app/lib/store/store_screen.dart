import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

import '../avatar/avatar_loader.dart';
import '../avatar/avatar_providers.dart';
import '../theme/amiro_card.dart';
import '../theme/amiro_theme.dart';
import 'rarity_label_style.dart';
import 'series_progress_row.dart';
import 'store_providers.dart';

/// Unseriesed items first, then each numbered series in order, each series
/// preceded by its [CollectionProgress] header. Returns [CollectionProgress]
/// for headers and [CosmeticListing] for items.
List<Object> _storeRows(List<CosmeticListing> catalog, Set<String> owned) {
  final rows = <Object>[...catalog.where((c) => c.series == null)];
  for (final progress in collectionProgress(catalog, owned)) {
    rows.add(progress);
    rows.addAll(
      catalog.where((c) => c.series?.number == progress.series.number),
    );
  }
  return rows;
}

class _SeriesHeader extends StatelessWidget {
  final CollectionProgress progress;

  const _SeriesHeader(this.progress);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AmiroSpacing.md,
        AmiroSpacing.lg,
        AmiroSpacing.md,
        AmiroSpacing.sm,
      ),
      child: SeriesProgressRow(progress),
    );
  }
}

/// The small brass "EQUIPPED" badge DESIGN.md's cosmetic-item-card spec
/// defines: on-primary text on a primary fill.
class _EquippedBadge extends StatelessWidget {
  const _EquippedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AmiroSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AmiroColors.primary,
        borderRadius: BorderRadius.circular(AmiroRadius.sm),
      ),
      child: Text(
        'EQUIPPED',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AmiroColors.onPrimary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// One catalog row, styled to DESIGN.md's cosmetic-item-card spec: default =
/// surface + hairline border; equipped = 2px brass border + EQUIPPED badge;
/// purchased-but-unequipped = default, no badge (tap to equip). The whole
/// card previews the item on the avatar — including unowned items, which is
/// the deliberate try-before-you-buy behaviour (see TODOS.md #6) — so a
/// locked item is decorated, not disabled.
class _CosmeticCard extends StatelessWidget {
  final CosmeticListing item;
  final bool isOwned;
  final bool isEquipped;
  final VoidCallback onPreview;
  final VoidCallback onBuy;

  const _CosmeticCard({
    required this.item,
    required this.isOwned,
    required this.isEquipped,
    required this.onPreview,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return AmiroCard(
      onTap: onPreview,
      border: isEquipped
          ? Border.all(color: AmiroColors.primary, width: 2)
          : null,
      child: Row(
        children: [
          Icon(
            isEquipped ? Icons.check_circle : Icons.remove_red_eye_outlined,
            color: isEquipped ? AmiroColors.primary : AmiroColors.textMuted,
          ),
          const SizedBox(width: AmiroSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (isEquipped) ...[
                      const SizedBox(width: AmiroSpacing.sm),
                      const _EquippedBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.slot,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AmiroColors.textMuted,
                      ),
                    ),
                    const Text(' · '),
                    Text(
                      item.rarity.label,
                      style: rarityLabelStyle(context, item.rarity),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AmiroSpacing.md),
          if (isOwned)
            Text(
              item.isFree ? 'FREE' : 'OWNED',
              style: amiroMono(context).copyWith(color: AmiroColors.textMuted),
            )
          else
            FilledButton(
              onPressed: onBuy,
              child: Text(
                'Buy \$${(item.priceCents / 100).toStringAsFixed(2)}',
                style: amiroMono(context),
              ),
            ),
        ],
      ),
    );
  }
}

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    ensureAvatarLoaded(ref);
  }

  Future<void> _preview(CosmeticListing item) async {
    final renderer = ref.read(avatarRendererProvider);
    await renderer.updateSlot(item.slot, item.assetId);
    final updated = renderer.current;
    if (updated != null) {
      await persistAvatarDefinition(ref, updated);
    }
    if (mounted) setState(() {});
  }

  // No payment processor is wired up yet (see EntitlementStore's own doc
  // comment) — this dialog stands in for a real purchase sheet so the flow
  // reads as an actual purchase, not a silent instant-grant, and is clearly
  // labeled as a demo so nobody mistakes it for a real charge.
  Future<void> _buy(CosmeticListing item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Text(
          'Buy for \$${(item.priceCents / 100).toStringAsFixed(2)}?\n\n'
          'This is a demo purchase — no payment processor is connected yet, '
          'so nothing will actually be charged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm (demo)'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(ownedCosmeticsProvider.notifier).purchase(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final renderer = ref.watch(avatarRendererProvider);
    final owned = ref.watch(ownedCosmeticsProvider).value ?? const <String>{};
    final rows = _storeRows(cosmeticCatalog, owned);

    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: Column(
        children: [
          SizedBox(height: 220, child: renderer.buildView()),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AmiroSpacing.md),
              itemCount: rows.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AmiroSpacing.sm),
              itemBuilder: (context, index) {
                final row = rows[index];
                if (row is CollectionProgress) return _SeriesHeader(row);
                final item = row as CosmeticListing;
                final isOwned = item.isFree || owned.contains(item.id);
                final isEquipped =
                    renderer.current?.toJson()[item.slot] == item.assetId;

                return _CosmeticCard(
                  item: item,
                  isOwned: isOwned,
                  isEquipped: isEquipped,
                  onPreview: () => _preview(item),
                  onBuy: () => _buy(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
