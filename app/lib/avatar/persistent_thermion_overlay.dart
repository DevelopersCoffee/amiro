import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_renderer/avatar_renderer.dart';

import '../identity/identity_providers.dart';
import 'avatar_defaults.dart';
import 'avatar_providers.dart';

/// App-lifetime host for the singleton [ThermionWidget].
///
/// The [ThermionWidget] child is created once and never [Offstage]d — hiding
/// uses opacity/pointer only so Android keeps one valid SwapChain. Filament
/// assets load/unload on the existing viewer when gender changes.
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
    final scene = ref.read(avatarSceneDefinitionProvider);
    if (_onThermionTab && scene != null) {
      await renderer.resumePresentation();
    } else {
      await renderer.pausePresentation();
    }
  }

  Future<void> _maybeResumeAfterSceneLoad() async {
    if (!mounted || !_onThermionTab) return;
    final scene = ref.read(avatarSceneDefinitionProvider);
    if (scene == null) return;
    await ref.read(avatarRendererProvider).resumePresentation();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(avatarSceneDefinitionProvider, (previous, next) {
      if (previous == next || next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeResumeAfterSceneLoad();
      });
    });

    final scene = ref.watch(avatarSceneDefinitionProvider);
    final identity = ref.watch(currentIdentityProvider).value;
    final showScene = _onThermionTab &&
        canRenderAvatarForIdentity(identity) &&
        scene != null;

    final renderer = ref.read(avatarRendererProvider);
    _thermionView ??= renderer.buildView();

    final mediaQuery = MediaQuery.of(context);
    final top = mediaQuery.padding.top + kToolbarHeight;

    final host = _host(_thermionView!, visible: showScene);

    if (widget.activeTabIndex == _storeTabIndex) {
      return Positioned(
        top: top,
        left: 0,
        right: 0,
        height: _storePreviewHeight,
        child: host,
      );
    }

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      bottom: _avatarEquipChromeBottom,
      child: host,
    );
  }

  Widget _host(Widget thermionView, {required bool visible}) {
    return IgnorePointer(
      ignoring: !visible,
      child: Opacity(
        opacity: visible ? 1 : 0,
        alwaysIncludeSemantics: false,
        child: thermionView,
      ),
    );
  }
}
