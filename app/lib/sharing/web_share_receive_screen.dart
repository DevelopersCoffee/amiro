import 'package:flutter/material.dart';
import 'package:sharing/sharing.dart';

import '../identity/supabase_public.dart';
import '../theme/amiro_theme.dart';

/// Opened when the in-app scanner sees an https web share token.
class WebShareReceiveScreen extends StatelessWidget {
  const WebShareReceiveScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final uri = buildWebShareUri(token, host: webSharePublicHost);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Web profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This card lives on the web',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Install Amiro to save this person to your passport, or open '
              'the link in a browser to see their public profile.',
              style: textTheme.bodyMedium?.copyWith(color: AmiroColors.textMuted),
            ),
            const SizedBox(height: 24),
            SelectableText(uri, style: textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}