import 'package:flutter/material.dart';
import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';

import '../theme/amiro_card.dart';
import '../theme/amiro_theme.dart';
import '../theme/section_label.dart';

/// What a stranger sees on the web profile (public fields only).
class WebShareStrangerPreview extends StatelessWidget {
  const WebShareStrangerPreview({
    super.key,
    required this.identity,
    required this.displayName,
  });

  final Identity identity;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final public = ContactCard.fromIdentity(identity);
    final fields = <(String, String?)>[
      ('Name', displayName.isEmpty ? 'Your Amiro' : displayName),
      ('Username', public.username),
      ('Bio', public.bio),
      ('Phone', public.mobile),
      ('Email', public.email),
      ('Website', public.website),
    ];

    return AmiroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('STRANGER PREVIEW'),
          const SizedBox(height: 8),
          Text(
            'This is what someone sees in a browser.',
            style: textTheme.labelMedium?.copyWith(color: AmiroColors.textMuted),
          ),
          const SizedBox(height: 12),
          for (final (label, value) in fields)
            if (value != null && value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(
                        label,
                        style: textTheme.labelSmall?.copyWith(
                          color: AmiroColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(child: Text(value)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}