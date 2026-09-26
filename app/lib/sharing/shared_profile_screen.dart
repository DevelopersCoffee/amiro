import 'package:flutter/material.dart';

import 'package:sharing/sharing.dart';
import 'package:store/store.dart';

import '../store/rarity_label_style.dart';
import '../store/series_progress_row.dart';
import 'remote_avatar_view.dart';

/// Read-only view of someone else's shared identity, from a legacy
/// `amiro://share` link. Their avatar is rendered by [RemoteAvatarView],
/// which owns its own screen-scoped renderer (see its doc for why that must
/// never be the app-lifetime singleton).
class SharedProfileScreen extends StatelessWidget {
  final SharedProfile profile;

  const SharedProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final avatarJson = profile.avatarDefinitionJson;

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Amiro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (avatarJson != null)
            RemoteAvatarView(avatarConfigJson: avatarJson),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (profile.username.isNotEmpty) Text('@${profile.username}'),
          if (profile.bio != null) ...[
            const SizedBox(height: 8),
            Text(profile.bio!),
          ],
          _CollectionSection(profile.ownedCosmeticIds),
          const SizedBox(height: 24),
          if (profile.email != null) Text('Email: ${profile.email}'),
          if (profile.mobile != null) Text('Mobile: ${profile.mobile}'),
          if (profile.xHandle != null) Text('X: ${profile.xHandle}'),
          if (profile.instagramHandle != null)
            Text('Instagram: ${profile.instagramHandle}'),
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

    final series = collectionProgress(
      cosmeticCatalog,
      collected,
    ).where((p) => p.owned > 0).toList();

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
              Text(
                rarest.rarity.label,
                style: rarityLabelStyle(context, rarest.rarity),
              ),
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
