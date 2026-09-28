import 'package:flutter/material.dart';

import 'package:sharing/sharing.dart';
import 'package:store/store.dart';

import '../sharing/own_encounter.dart';
import '../sharing/standouts.dart';
import '../store/rarity_label_style.dart';
import '../theme/amiro_theme.dart';

/// YOU beside THEM: standout items and series progress, side by side.
///
/// Purely presentational. [mine] is null until the user has an avatar; the
/// YOU column then stays empty rather than being invented.
class EncounterComparison extends StatelessWidget {
  final AmiroSharingPayload? mine;
  final AmiroSharingPayload theirs;

  const EncounterComparison({
    super.key,
    required this.mine,
    required this.theirs,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = textTheme.labelSmall?.copyWith(
      color: AmiroColors.textMuted,
      letterSpacing: 2.4,
    );

    final myProgress = {
      for (final p in progressFromCompletion(
        mine?.collectionCompletion ?? const [],
      ))
        p.series.number: p,
    };
    final theirProgress = {
      for (final p in progressFromCompletion(theirs.collectionCompletion))
        p.series.number: p,
    };
    final seriesNumbers = {
      for (final p in [...myProgress.values, ...theirProgress.values])
        if (p.owned > 0) p.series.number,
    }.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Column(
                heading: 'YOU',
                headingStyle: label,
                payload: mine,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Column(
                heading: 'THEM',
                headingStyle: label,
                payload: theirs,
              ),
            ),
          ],
        ),
        if (seriesNumbers.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('COLLECTIONS', style: label),
          for (final number in seriesNumbers) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    (myProgress[number] ?? theirProgress[number])!.series.label,
                    style: textTheme.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: _Count(myProgress[number], key: Key('mine$number')),
                ),
                SizedBox(
                  width: 72,
                  child: _Count(
                    theirProgress[number],
                    key: Key('theirs$number'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _Column extends StatelessWidget {
  final String heading;
  final TextStyle? headingStyle;
  final AmiroSharingPayload? payload;

  const _Column({
    required this.heading,
    required this.headingStyle,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    final standouts = payload == null
        ? const []
        : standoutCosmetics(payload!.equippedCosmetics);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: headingStyle),
        const SizedBox(height: 8),
        if (standouts.isEmpty)
          Text(
            'Nothing rare equipped',
            style: TextStyle(color: AmiroColors.textMuted),
          )
        else
          for (final (item, rarity) in standouts) ...[
            Text(item.name),
            Text(rarity.label, style: rarityLabelStyle(context, rarity)),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _Count extends StatelessWidget {
  final CollectionProgress? progress;

  const _Count(this.progress, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final text = p == null || p.owned == 0
        ? '–'
        : (p.isComplete ? 'Complete' : '${p.owned} / ${p.total}');
    final complete = p != null && p.isComplete;
    return Text(
      text,
      textAlign: TextAlign.end,
      style: amiroMono(
        context,
      ).copyWith(color: complete ? AmiroColors.primary : AmiroColors.textMuted),
    );
  }
}
