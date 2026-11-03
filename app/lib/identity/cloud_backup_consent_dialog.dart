import 'package:flutter/material.dart';

import '../theme/amiro_theme.dart';

/// Consent dialog before turning on cloud backup. Returns `true` when the user
/// accepts, `false` for "Not now", or null if dismissed another way.
Future<bool?> showCloudBackupConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => CloudBackupConsentDialog(
      onDecline: () => Navigator.of(dialogContext).pop(false),
      onAccept: () => Navigator.of(dialogContext).pop(true),
    ),
  );
}

class CloudBackupConsentDialog extends StatelessWidget {
  const CloudBackupConsentDialog({
    super.key,
    required this.onDecline,
    required this.onAccept,
  });

  final VoidCallback onDecline;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AmiroColors.surface,
      title: const Text('Back up to the cloud?'),
      content: const Text(
        'When enabled, Amiro copies your profile and avatar to our '
        'encrypted backup service so you can restore on another phone. '
        'Private contact fields stay on this device unless you mark '
        'them public. Turning backup off deletes that server copy.',
      ),
      actions: [
        TextButton(
          key: const Key('cloudBackupConsentDecline'),
          onPressed: onDecline,
          child: const Text('Not now'),
        ),
        FilledButton(
          key: const Key('cloudBackupConsentAccept'),
          onPressed: onAccept,
          child: const Text('Enable backup'),
        ),
      ],
    );
  }
}
