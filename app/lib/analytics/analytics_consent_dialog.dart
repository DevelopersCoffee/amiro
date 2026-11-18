import 'package:flutter/material.dart';

import '../theme/amiro_theme.dart';

/// Opt-in copy for minimal product analytics (DESIGN.md voice).
Future<bool?> showAnalyticsConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AmiroColors.surface,
        title: const Text('Help us improve Amiro?'),
        content: const Text(
          'If you turn this on, the app sends a few anonymous counts — like '
          'whether setup finished or you shared once. No names, contacts, or '
          'encounter details. You can turn it off anytime here.',
        ),
        actions: [
          TextButton(
            key: const Key('analyticsConsentDecline'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const Key('analyticsConsentAccept'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Share counts'),
          ),
        ],
      );
    },
  );
}