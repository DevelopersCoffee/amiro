import 'package:flutter/material.dart';

import 'amiro_theme.dart';

/// The one elevated-surface treatment every card in the app uses: surface
/// fill, radius 16, a real offset shadow (DESIGN.md — never a glow), and a
/// neutral hairline border unless [border] overrides it (e.g. the
/// collector's frame via `cardBorder`). Extracted so the identity card, the
/// passport list and any future card don't each re-derive the same
/// BoxDecoration slightly differently.
class AmiroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Border? border;
  final VoidCallback? onTap;

  const AmiroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: AmiroColors.surface,
        border: border ?? Border.all(color: AmiroColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AmiroRadius.lg),
        boxShadow: amiroCardShadow,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AmiroRadius.lg),
      child: content,
    );
  }
}
