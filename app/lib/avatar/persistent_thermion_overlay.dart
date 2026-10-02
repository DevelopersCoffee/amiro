import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_renderer/avatar_renderer.dart';

import '../identity/identity_providers.dart';
import 'avatar_defaults.dart';
import 'avatar_providers.dart';

/// App-lifetime host for the singleton [ThermionWidget].
///
/// Stays in the tree across tab changes ( [Offstage] when hidden) so Android
/// never destroys the GL texture while Filament still animates skinned meshes.
/// Only tab indices 1 (Avatar) and 2 (Store preview) show and accept input.
class PersistentThermionOverlay extends ConsumerStatefulWidget {
  final int activeTabIndex;

  const PersistentThermionOverlay({super.key, required this.activeTabIndex});

  @override
  ConsumerState<PersistentThermionOverlay> createState() =>
      _PersistentThermionOverlayState();
}

class _PersistentThermionOverlayState
    extends ConsumerState<PersistentThermionOverlay> {
  Widget? _thermionView;
  int? _lastSyncedTab;

  static const _avatarTabIndex = 1;
  static const _storeTabIndex = 2;
  static const _storePreviewHeight = 220.0;
  static const _avatarEquipChromeBottom = 76.0;

  bool get _onThermionTab =>
      widget.activeTabIndex == _avatarTabIndex ||
      widget.activeTabIndex == _storeTabIndex;

  @override
  void didUpdateWidget(covariant PersistentThermionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTabIndex != widget.activeTabIndex) {
      _schedulePresentationSync();
    }
  }

  @override
  void initState() {
    super.initState();
    _schedulePresentationSync();
    _scheduleSceneAvailabilitySync();
  }

  void _schedulePresentationSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncPresentation();
    });
  }

  Future<void> _syncPresentation() async {
    if (!mounted) return;
    final tab = widget.activeTabIndex;
    if (_lastSyncedTab == tab) return;
    _lastSyncedTab = tab;

    final renderer = ref.read(avatarRendererProvider);
    if (_onThermionTab) {
      await _resumeIfSceneReady(renderer);
    } else {
      await renderer.pausePresentation();
    }
  }

  void _scheduleSceneAvailabilitySync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncSceneAvailability();
    });
  }

  Future<void> _syncSceneAvailability() async {
    if (!mounted) return;
    final renderer = ref.read(avatarRendererProvider);
    final identity = ref.read(currentIdentityProvider).value;
    final shouldShow = _onThermionTab &&
        canRenderAvatarForIdentity(identity) &&
        renderer.current != null;
    if (shouldShow) {
      await _resumeIfSceneReady(renderer);
    }
  }

  Future<void> _resumeIfSceneReady(AvatarRenderer renderer) async {
    if (renderer.current == null) return;
    await renderer.resumePresentation();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(avatarSceneRevisionProvider, (previous, next) {
      if (previous != next) {
        _scheduleSceneAvailabilitySync();
      }
    });

    ref.watch(avatarSceneRevisionProvider);
    final renderer = ref.watch(avatarRendererProvider);
    final identity = ref.watch(currentIdentityProvider).value;
    final showScene = _onThermionTab &&
        canRenderAvatarForIdentity(identity) &&
        renderer.current != null;

    _thermionView ??= renderer.buildView();

    final mediaQuery = MediaQuery.of(context);
    final top = mediaQuery.padding.top + kToolbarHeight;

    if (widget.activeTabIndex == _storeTabIndex) {
      return Positioned(
        top: top,
        left: 0,
        right: 0,
        height: _storePreviewHeight,
        child: _host(_thermionView!, visible: showScene),
      );
    }

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      bottom: _avatarEquipChromeBottom,
      child: _host(_thermionView!, visible: showScene),
    );
  }

  Widget _host(Widget thermionView, {required bool visible}) {
    return Offstage(
      offstage: !visible,
      child: IgnorePointer(
        ignoring: !visible,
        child: thermionView,
      ),
    );
  }
}
