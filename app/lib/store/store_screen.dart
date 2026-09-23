import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

import '../avatar/avatar_loader.dart';
import '../avatar/avatar_providers.dart';
import 'store_providers.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: Column(
        children: [
          SizedBox(height: 220, child: renderer.buildView()),
          Expanded(
            child: ListView.builder(
              itemCount: cosmeticCatalog.length,
              itemBuilder: (context, index) {
                final item = cosmeticCatalog[index];
                final isOwned = item.isFree || owned.contains(item.id);
                final isEquipped = renderer.current?.toJson()[item.slot] == item.assetId;

                return ListTile(
                  onTap: () => _preview(item),
                  leading: Icon(isEquipped ? Icons.check_circle : Icons.remove_red_eye_outlined),
                  title: Text(item.name),
                  subtitle: Text(item.slot),
                  trailing: isOwned
                      ? (item.isFree ? const Text('FREE') : const Text('OWNED'))
                      : FilledButton(
                          onPressed: () =>
                              ref.read(ownedCosmeticsProvider.notifier).purchase(item.id),
                          child: Text('Buy \$${(item.priceCents / 100).toStringAsFixed(2)}'),
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
