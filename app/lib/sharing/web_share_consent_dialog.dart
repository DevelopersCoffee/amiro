import 'package:flutter/material.dart';

import '../theme/amiro_theme.dart';

Future<bool?> showWebShareConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AmiroColors.surface,
      title: const Text('Publish web profile?'),
      content: const Text(
        'A stranger with your link can open your name, avatar image, and the '
        'fields you marked public in a browser — no Amiro account needed. '
        'You can revoke this anytime. Nothing is published until you confirm.',
      ),
      actions: [
        TextButton(
          key: const Key('webShareConsentDecline'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          key: const Key('webShareConsentAccept'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Publish'),
        ),
      ],
    ),
  );
}