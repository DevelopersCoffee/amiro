import 'package:flutter/material.dart';

import 'amiro_theme.dart';

/// A screen with nothing in it yet, explained rather than left blank
/// (DESIGN.md: Share and Passport should say what they will show, not just
/// sit empty). [actionLabel] and [onAction] must both be given for the
/// button to appear, or neither.
class EmptyState extends StatelessWidget {
  final String title;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.hint,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AmiroSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AmiroSpacing.sm),
            Text(
              hint,
              style: textTheme.bodyMedium?.copyWith(
                color: AmiroColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AmiroSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
