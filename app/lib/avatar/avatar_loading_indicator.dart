import 'package:flutter/material.dart';

import '../theme/amiro_theme.dart';

/// The branded loading moment while the 3D avatar asset loads.
///
/// Per DESIGN.md: no glow/halo, depth only from real shadows — the shimmer
/// here is a plain opacity pulse on a silhouette, not a gradient sweep.
class AvatarLoadingIndicator extends StatefulWidget {
  const AvatarLoadingIndicator({super.key});

  @override
  State<AvatarLoadingIndicator> createState() => _AvatarLoadingIndicatorState();
}

class _AvatarLoadingIndicatorState extends State<AvatarLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AmiroColors.ground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _controller.drive(Tween(begin: 0.35, end: 0.85)),
              child: Container(
                width: 96,
                height: 160,
                decoration: BoxDecoration(
                  color: AmiroColors.surface,
                  border: Border.all(color: AmiroColors.surfaceBorder, width: 1.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(48),
                    bottom: Radius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waking up your Amiro…',
              style: TextStyle(color: Color(0xFF8C8474), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
