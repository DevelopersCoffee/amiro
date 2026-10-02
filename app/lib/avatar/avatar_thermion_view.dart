import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_renderer/avatar_renderer.dart';

import '../theme/amiro_theme.dart';
import 'avatar_providers.dart';
import 'avatar_thermion_attach.dart';

/// Singleton-renderer viewport: swaps [ThermionWidget] for a placeholder when
/// [avatarThermionAttachedProvider] is false so Filament can idle safely.
class AvatarThermionView extends ConsumerWidget {
  const AvatarThermionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attached = ref.watch(avatarThermionAttachedProvider);
    final renderer = ref.watch(avatarRendererProvider);

    if (!attached) {
      return const ColoredBox(
        color: AmiroColors.ground,
        child: SizedBox.expand(),
      );
    }

    return renderer.buildView();
  }
}
