import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../identity/identity_providers.dart';
import 'avatar_loader.dart';

/// Keeps the singleton renderer aligned with [Identity.avatarGender] while tabs
/// stay alive in an [IndexedStack] (AvatarScreen init does not re-run).
class AvatarIdentitySyncListener extends ConsumerWidget {
  final Widget child;

  const AvatarIdentitySyncListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentIdentityProvider, (previous, next) {
      final prevGender = previous?.value?.avatarGender;
      final nextGender = next.value?.avatarGender;
      if (prevGender != nextGender) {
        unawaited(ensureAvatarLoaded(ref));
      }
    });
    return child;
  }
}
