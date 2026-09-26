import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

import '../avatar/avatar_loader.dart';
import '../avatar/avatar_providers.dart';
import '../theme/amiro_theme.dart';
import 'rarity_label_style.dart';
import 'store_providers.dart';

/// Unseriesed items first, then each numbered series in order, each series
/// preceded by a header. Returns [CosmeticSeries] for headers and
/// [CosmeticListing] for items.
List<Object> _storeRows(List<CosmeticListing> catalog) {
  final rows = <Object>[...catalog.where((c) => c.series == null)];
  final seriesNumbers = {
    for (final c in catalog)
      if (c.series != null) c.series!.number: c.series!,
  };
  for (final number in seriesNumbers.keys.toList()..sort()) {
    rows.add(seriesNumbers[number]!);
    rows.addAll(catalog.where((c) => c.series?.number == number));
  }
  return rows;
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

  @override
  Widget build(BuildContext context) {
    final renderer = ref.watch(avatarRendererProvider);
    final owned = ref.watch(ownedCosmeticsProvider).value ?? const <String>{};
    final rows = _storeRows(cosmeticCatalog);

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
                if (row is CosmeticSeries) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      row.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
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
                          onPressed: () => ref
                              .read(ownedCosmeticsProvider.notifier)
                              .purchase(item.id),
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
