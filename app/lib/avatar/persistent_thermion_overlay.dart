import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  static const _storePreviewHeight = 280.0;
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
      await renderer.resumePresentation();
    } else {
      await renderer.pausePresentation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final renderer = ref.watch(avatarRendererProvider);
    _thermionView ??= renderer.buildView();

    final mediaQuery = MediaQuery.of(context);
    final top = mediaQuery.padding.top + kToolbarHeight;

    if (widget.activeTabIndex == _storeTabIndex) {
      return Positioned(
        top: top,
        left: 0,
        right: 0,
        height: _storePreviewHeight,
        child: _host(_thermionView!),
      );
    }

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      bottom: _avatarEquipChromeBottom,
      child: _host(_thermionView!),
    );
  }

  Widget _host(Widget thermionView) {
    return Offstage(
      offstage: !_onThermionTab,
      child: IgnorePointer(
        ignoring: !_onThermionTab,
        child: thermionView,
      ),
    );
  }
}
