import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovery/discovery.dart';

import '../sharing/own_encounter.dart';
import '../sharing/remote_avatar_view.dart';
import '../sharing/standouts.dart';
import '../store/rarity_label_style.dart';
import '../store/series_progress_row.dart';
import '../theme/amiro_theme.dart';
import 'date_format.dart';
import 'discovery_providers.dart';

/// One passport entry in full: their latest known look, standout items and
/// series progress, when you first and last met, and a way to remove them.
class PassportEntryScreen extends ConsumerWidget {
  final String remoteIdentityId;

  const PassportEntryScreen({super.key, required this.remoteIdentityId});

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    EncounterRecord record,
  ) async {
    final navigator = Navigator.of(context);
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Remove ${record.displayName}?'),
        content: const Text(
          'They leave your passport. If you meet again they will count as a new discovery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            key: const Key('confirmRemoveButton'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (remove != true) return;

    await ref.read(discoveryRepositoryProvider).delete(record.localRecordId);
    ref.invalidate(encounterRecordsProvider);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(encounterRecordsProvider).value;
    final record = records
        ?.where((r) => r.remoteIdentityId == remoteIdentityId)
        .firstOrNull;
    final textTheme = Theme.of(context).textTheme;

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Passport')),
        body: records == null
            ? const Center(child: CircularProgressIndicator())
            : const SizedBox.shrink(),
      );
    }

    final label = textTheme.labelSmall?.copyWith(
      color: AmiroColors.textMuted,
      letterSpacing: 2.4,
    );
    final standouts = standoutCosmetics(record.observedCosmetics);
    final series = progressFromCompletion(
      record.observedCollections,
    ).where((p) => p.owned > 0);

    return Scaffold(
      appBar: AppBar(title: Text(record.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          RemoteAvatarView(avatarConfigJson: record.latestAvatarConfig),
          const SizedBox(height: 16),
          Text(record.displayName, style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'First met ${formatShortDate(record.firstEncountered)}',
            style: textTheme.labelMedium?.copyWith(
              color: AmiroColors.textMuted,
            ),
          ),
          Row(
            children: [
              Text(
                'Last seen ${formatShortDate(record.lastEncountered)}',
                style: textTheme.labelMedium?.copyWith(
                  color: AmiroColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${record.encounterCount}×',
                style: amiroMono(
                  context,
                ).copyWith(color: AmiroColors.textMuted),
              ),
            ],
          ),
          if (standouts.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('STANDOUTS', style: label),
            for (final (item, rarity) in standouts) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(item.name)),
                  Text(rarity.label, style: rarityLabelStyle(context, rarity)),
                ],
              ),
            ],
          ],
          if (series.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('COLLECTIONS', style: label),
            for (final progress in series) ...[
              const SizedBox(height: 8),
              SeriesProgressRow(progress),
            ],
          ],
          const SizedBox(height: 32),
          OutlinedButton(
            key: const Key('removeFromPassportButton'),
            onPressed: () => _confirmRemove(context, ref, record),
            child: const Text('Remove from passport'),
          ),
        ],
      ),
    );
  }
}
