import 'package:flutter/material.dart';

import '../theme/amiro_theme.dart';

/// Ground-colored slot where the persistent [PersistentThermionOverlay] draws
/// the live Filament view. Screens must not embed a second [ThermionWidget].
class AvatarViewportPlaceholder extends StatelessWidget {
  const AvatarViewportPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AmiroColors.ground,
      child: SizedBox.expand(),
    );
  }
}
