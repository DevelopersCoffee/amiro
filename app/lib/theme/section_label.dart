import 'package:flutter/material.dart';

import 'amiro_theme.dart';

/// The muted, wide-tracked uppercase caption used above a card's content
/// section (COLLECTIONS, STANDOUTS, CONTACT, DISCOVERED, ...).
TextStyle sectionLabelStyle(BuildContext context) {
  return Theme.of(context).textTheme.labelSmall!.copyWith(
    color: AmiroColors.textMuted,
    letterSpacing: 2.4,
  );
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: sectionLabelStyle(context));
}
