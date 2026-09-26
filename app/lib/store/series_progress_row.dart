import 'package:flutter/material.dart';
import 'package:store/store.dart';

import '../theme/amiro_theme.dart';

/// "Series #1 · Founders ........ 1 / 3" — brass "Complete" once done.
/// Shared by the store list and a received identity card.
class SeriesProgressRow extends StatelessWidget {
  final CollectionProgress progress;

  const SeriesProgressRow(this.progress, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            progress.series.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text(
          progress.isComplete
              ? 'Complete'
              : '${progress.owned} / ${progress.total}',
          style: amiroMono(context).copyWith(
            color: progress.isComplete
                ? AmiroColors.primary
                : AmiroColors.textMuted,
          ),
        ),
      ],
    );
  }
}
