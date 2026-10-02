import 'package:avatar_core/avatar_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

import '../avatar/avatar_defaults.dart';
import '../avatar/avatar_loader.dart';
import '../avatar/avatar_providers.dart';
import '../avatar/avatar_viewport_placeholder.dart';
import '../identity/identity_providers.dart';
import '../theme/amiro_theme.dart';
import 'rarity_label_style.dart';
import 'series_progress_row.dart';
import 'store_providers.dart';

/// Unseriesed items first, then each numbered series in order, each series
/// preceded by its [CollectionProgress] header. Returns [CollectionProgress]
/// for headers and [CosmeticListing] for items.
/// Hides slot items that do not apply to [gender] yet (see avatar_gender.dart).
bool cosmeticListingVisibleForGender(
  CosmeticListing listing,
  AvatarGender gender,
) {
  if (gender == AvatarGender.female && listing.slot == 'facialHair') {
    // TODO(catalog): female facial-hair variants when assets exist.
    return false;
  }
  return true;
}

List<Object> _storeRows(
  List<CosmeticListing> catalog,
  Set<String> owned,
  AvatarGender gender,
) {
  final visible = catalog
      .where((c) => cosmeticListingVisibleForGender(c, gender))
      .toList();
  final rows = <Object>[...visible.where((c) => c.series == null)];
  for (final progress in collectionProgress(visible, owned)) {
    rows.add(progress);
    rows.addAll(
      visible.where((c) => c.series?.number == progress.series.number),
    );
  }
  return rows;
}

String _slotCategoryLabel(String slot) {
  switch (slot) {
    case 'facialHair':
      return 'Facial hair';
    case 'goldChain':
      return 'Chain';
    default:
      if (slot.isEmpty) return slot;
      return slot[0].toUpperCase() + slot.substring(1);
  }
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

/// The small brass "EQUIPPED" badge — primary fill, on-primary text.
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

/// Boutique store row — minimal surface, hierarchy-first, gold only when equipped.
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
    final metaStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AmiroColors.textMuted);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPreview,
        borderRadius: BorderRadius.circular(AmiroRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: AmiroColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AmiroRadius.md),
            border: Border.all(
              color: AmiroColors.surfaceBorder.withValues(alpha: 0.65),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AmiroRadius.md),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isEquipped)
                    const ColoredBox(
                      color: AmiroColors.primary,
                      child: SizedBox(width: 3),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AmiroSpacing.md,
                        AmiroSpacing.md,
                        AmiroSpacing.sm,
                        AmiroSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: AmiroColors.textMuted.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: AmiroSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: item.rarity.label,
                                        style: rarityLabelStyle(
                                          context,
                                          item.rarity,
                                        ),
                                      ),
                                      TextSpan(text: ' · ', style: metaStyle),
                                      TextSpan(
                                        text: _slotCategoryLabel(item.slot),
                                        style: metaStyle,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isEquipped) ...[
                                  const SizedBox(height: 6),
                                  const _EquippedBadge(),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: AmiroSpacing.sm),
                          if (isOwned && !item.isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AmiroSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AmiroColors.surfaceBorder.withValues(
                                  alpha: 0.45,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AmiroRadius.sm,
                                ),
                              ),
                              child: Text(
                                'OWNED',
                                style: amiroMono(
                                  context,
                                ).copyWith(color: AmiroColors.textMuted),
                              ),
                            )
                          else if (!isOwned)
                            FilledButton(
                              onPressed: onBuy,
                              child: Text(
                                item.isFree
                                    ? 'Get'
                                    : 'Buy \$${(item.priceCents / 100).toStringAsFixed(2)}',
                                style: amiroMono(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  // Play Billing's own sheet shows the price and asks for confirmation —
  // tapping Buy goes straight to the real purchase flow instead of
  // duplicating that confirmation in-app.
  Future<void> _buy(CosmeticListing item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(ownedCosmeticsProvider.notifier).purchase(item.id);
    } on PurchaseCancelledException {
      // User backed out of the native sheet — nothing to report.
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    }
  }

  Future<void> _restore() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(ownedCosmeticsProvider.notifier).restore();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Purchases restored')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final renderer = ref.watch(avatarRendererProvider);
    final owned = ref.watch(ownedCosmeticsProvider).value ?? const <String>{};
    final gender = resolveAvatarGender(
      ref.watch(currentIdentityProvider).value,
    );
    final rows = _storeRows(cosmeticCatalog, owned, gender);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          TextButton(
            onPressed: _restore,
            child: const Text('Restore purchases'),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 280, child: AvatarViewportPlaceholder()),
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
