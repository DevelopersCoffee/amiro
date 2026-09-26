import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:sharing/sharing.dart';
import 'package:store/store.dart';

import '../avatar/avatar_providers.dart';
import '../store/rarity_label_style.dart';
import '../store/series_progress_row.dart';

/// Read-only view of someone else's shared identity — reached via QR scan
/// or NFC tap.
///
/// Renders their avatar through a fresh, screen-scoped [AvatarRenderer]
/// obtained from [avatarRendererFactoryProvider] — deliberately *not* the
/// app-lifetime singleton behind [avatarRendererProvider] that backs the
/// user's own `AvatarScreen`. That renderer's `load()` is additive (it
/// doesn't clear previously-loaded slots first), so loading a stranger's
/// definition into it would bleed their meshes into the user's own live
/// scene and overwrite the singleton's `current`, corrupting
/// `AvatarScreen`'s re-entry guard on the way back. This screen owns its
/// renderer for its own lifetime and disposes it when it goes away.
class SharedProfileScreen extends ConsumerStatefulWidget {
  final SharedProfile profile;

  const SharedProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<SharedProfileScreen> createState() => _SharedProfileScreenState();
}

class _SharedProfileScreenState extends ConsumerState<SharedProfileScreen> {
  bool _initStarted = false;
  AvatarRenderer? _renderer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initStarted) return;
    _initStarted = true;
    _init();
  }

  Future<void> _init() async {
    final json = widget.profile.avatarDefinitionJson;
    if (json == null) return;

    // Declared outside the `try` so the `catch` block can dispose it if
    // the factory succeeded but `load()` (fed by untrusted, scanned data)
    // then failed — otherwise the already-constructed Filament engine
    // instance would leak on every such failure.
    AvatarRenderer? renderer;
    try {
      final createRenderer = ref.read(avatarRendererFactoryProvider);
      renderer = await createRenderer();
      final definition = AvatarDefinition.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      await renderer.load(definition);

      if (!mounted) {
        await renderer.dispose();
        return;
      }
      setState(() => _renderer = renderer);
    } catch (error) {
      // Best-effort preview — a scanned/malformed avatar definition or a
      // renderer-construction/load failure shouldn't crash the screen or
      // leave an unhandled future exception; the rest of the profile
      // (name, username, bio, contact fields) still renders fine without
      // it. Dispose whatever got constructed so it doesn't leak.
      await renderer?.dispose();
      debugPrint('SharedProfileScreen: failed to load shared avatar: $error');
    }
  }

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final renderer = _renderer;

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Amiro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (profile.avatarDefinitionJson != null)
            SizedBox(
              height: 240,
              child: renderer != null
                  ? renderer.buildView()
                  : const Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          Text(profile.displayName, style: Theme.of(context).textTheme.headlineSmall),
          Text('@${profile.username}'),
          if (profile.bio != null) ...[
            const SizedBox(height: 8),
            Text(profile.bio!),
          ],
          _CollectionSection(profile.ownedCosmeticIds),
          const SizedBox(height: 24),
          if (profile.email != null) Text('Email: ${profile.email}'),
          if (profile.mobile != null) Text('Mobile: ${profile.mobile}'),
          if (profile.xHandle != null) Text('X: ${profile.xHandle}'),
          if (profile.instagramHandle != null) Text('Instagram: ${profile.instagramHandle}'),
          if (profile.website != null) Text('Website: ${profile.website}'),
        ],
      ),
    );
  }
}

/// The collectible half of an identity card: rarest item and series
/// progress. Built only from ids this app version knows; the sender's list is
/// self-reported, so it is decoration, never proof of ownership.
class _CollectionSection extends StatelessWidget {
  final List<String> ownedCosmeticIds;

  const _CollectionSection(this.ownedCosmeticIds);

  @override
  Widget build(BuildContext context) {
    final collected = ownedCosmeticIds.toSet();
    final rarest = rarestCosmetic(cosmeticCatalog, collected);
    if (rarest == null) return const SizedBox.shrink();

    final series = collectionProgress(cosmeticCatalog, collected)
        .where((p) => p.owned > 0)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Collection', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(rarest.name),
              const SizedBox(width: 8),
              Text(rarest.rarity.label, style: rarityLabelStyle(context, rarest.rarity)),
            ],
          ),
          for (final progress in series) ...[
            const SizedBox(height: 8),
            SeriesProgressRow(progress),
          ],
        ],
      ),
    );
  }
}
