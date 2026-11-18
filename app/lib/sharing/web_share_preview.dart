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

  static const _contactLabels = <String, String>{
    'username': 'Username',
    'bio': 'Bio',
    'mobile': 'Phone',
    'email': 'Email',
    'website': 'Website',
    'xHandle': 'X',
    'instagramHandle': 'Instagram',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final contact = filterWebSharePublicContact(
      ContactCard.fromIdentity(identity).toJson(),
    );

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
          _PreviewRow(label: 'Name', value: displayName.isEmpty ? 'Your Amiro' : displayName),
          for (final key in kWebSharePublicContactKeys)
            if (contact[key] is String)
              _PreviewRow(
                label: _contactLabels[key] ?? key,
                value: contact[key] as String,
              ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: textTheme.labelSmall?.copyWith(color: AmiroColors.textMuted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}