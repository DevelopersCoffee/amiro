import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When false, Avatar / Store screens render a same-size placeholder instead of
/// [ThermionWidget] so the native surface can detach before tab changes or
/// [AvatarRenderer.unload].
final avatarThermionAttachedProvider =
    NotifierProvider<AvatarThermionAttachedNotifier, bool>(
      AvatarThermionAttachedNotifier.new,
    );

class AvatarThermionAttachedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  Future<void> detachForEngineMutation() async {
    if (!state) {
      await _waitForNativeSurfaceIdle();
      return;
    }
    state = false;
    await _waitForNativeSurfaceIdle();
  }

  void attach() {
    state = true;
  }

  Future<void> _waitForNativeSurfaceIdle() async {
    await SchedulerBinding.instance.endOfFrame;
    // One extra frame — Filament on Android finishes tearing down the GL
    // surface after the placeholder swap.
    await SchedulerBinding.instance.endOfFrame;
  }
}
