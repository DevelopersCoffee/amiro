import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovery/discovery.dart';

import '../sharing/collector_frame.dart';
import '../sharing/own_encounter.dart';
import '../sharing/standouts.dart';
import '../store/rarity_label_style.dart';
import '../store/series_progress_row.dart';
import '../theme/amiro_card.dart';
import '../theme/amiro_theme.dart';
import '../theme/empty_state.dart';
import '../theme/section_label.dart';
import 'date_format.dart';
import 'discovery_providers.dart';
import 'passport_entry_screen.dart';

/// The Discovery Passport: everyone the user has met, most recent first, as
/// an editorial lookbook rather than a contact list. Only what a card showed
/// is kept: name, look, standout items, series progress.
class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(encounterRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Passport')),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          title: "Your passport couldn't be opened",
          hint: 'Restart the app to try again.',
        ),
        data: (all) {
          if (all.isEmpty) {
            return const EmptyState(
              title: 'No one discovered yet',
              hint:
                  'Scan or tap another Amiro from the Share tab to start your passport.',
            );
          }
          final recent = [...all]
            ..sort((a, b) => b.lastEncountered.compareTo(a.lastEncountered));
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _Header(count: all.length),
              for (final record in recent) ...[
                const SizedBox(height: 16),
                _EntryCard(record: record),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;

  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SectionLabel('DISCOVERED'),
        const SizedBox(width: 12),
        Text(
          '${count.toString().padLeft(2, '0')} ${count == 1 ? 'identity' : 'identities'}',
          key: const Key('passportCount'),
          style: amiroMono(context).copyWith(color: AmiroColors.textMuted),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final EncounterRecord record;

  const _EntryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final standouts = standoutCosmetics(record.observedCosmetics, limit: 2);
    final series = progressFromCompletion(
      record.observedCollections,
    ).where((p) => p.owned > 0);

    return AmiroCard(
      key: Key('passportEntry-${record.remoteIdentityId}'),
      border: cardBorder(record.observedCollections),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PassportEntryScreen(remoteIdentityId: record.remoteIdentityId),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(record.displayName, style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'First met ${formatShortDate(record.firstEncountered)}',
                style: textTheme.labelMedium?.copyWith(
                  color: AmiroColors.textMuted,
                ),
              ),
              if (record.encounterCount > 1) ...[
                const SizedBox(width: 8),
                Text(
                  '${record.encounterCount}×',
                  style: amiroMono(
                    context,
                  ).copyWith(color: AmiroColors.textMuted),
                ),
              ],
            ],
          ),
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
        ],
      ),
    );
  }
}
