import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

import '../avatar/avatar_loader.dart';
import '../avatar/avatar_providers.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: SeriesProgressRow(progress),
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
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                if (row is CollectionProgress) return _SeriesHeader(row);
                final item = row as CosmeticListing;
                final isOwned = item.isFree || owned.contains(item.id);
                final isEquipped =
                    renderer.current?.toJson()[item.slot] == item.assetId;

                return ListTile(
                  onTap: () => _preview(item),
                  leading: Icon(
                    isEquipped
                        ? Icons.check_circle
                        : Icons.remove_red_eye_outlined,
                  ),
                  title: Text(item.name),
                  subtitle: Row(
                    children: [
                      Text(item.slot),
                      const Text(' \u00b7 '),
                      Text(
                        item.rarity.label,
                        style: rarityLabelStyle(context, item.rarity),
                      ),
                    ],
                  ),
                  trailing: isOwned
                      ? (item.isFree ? const Text('FREE') : const Text('OWNED'))
                      : FilledButton(
                          onPressed: () => _buy(item),
                          child: Text(
                            'Buy \$${(item.priceCents / 100).toStringAsFixed(2)}',
                            style: amiroMono(context),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
