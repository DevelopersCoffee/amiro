import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';

import 'package:identity_core/identity_core.dart';

import '../identity/identity_providers.dart';
import 'avatar_defaults.dart';
import 'avatar_providers.dart';

/// App-lifetime host for the singleton [ThermionWidget].
///
/// The [ThermionWidget] child is created once and never [Offstage]d — hiding
/// uses opacity/pointer only so Android keeps one valid SwapChain.
///
/// Tab switches do **not** pause Filament presentation: rapid Avatar↔Identity
/// stress was tearing the SwapChain when pause/resume raced the frame pump
/// (see Filament `endFrame` / SwapChain validity). Presentation pauses only
/// via [ThermionViewDetachGate] before asset unload; [AvatarRenderer.load]
/// resumes and (after gate-pause reloads) draws a frame — not from this overlay.
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
  var _startedPresentation = false;

  static const _avatarTabIndex = 1;
  static const _storeTabIndex = 2;
  static const _storePreviewHeight = 220.0;
  static const _avatarEquipChromeBottom = 76.0;

  bool get _onThermionTab =>
      widget.activeTabIndex == _avatarTabIndex ||
      widget.activeTabIndex == _storeTabIndex;

  bool _shouldPresentScene({
    required AvatarDefinition? scene,
    required Identity? identity,
  }) {
    return _onThermionTab &&
        canRenderAvatarForIdentity(identity) &&
        scene != null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startPresentationOnce());
    });
  }

  Future<void> _startPresentationOnce() async {
    if (!mounted || _startedPresentation) return;
    _startedPresentation = true;
    await ref.read(avatarRendererProvider).resumePresentation();
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(avatarSceneDefinitionProvider);
    final identity = ref.watch(currentIdentityProvider).value;
    final showScene = _shouldPresentScene(scene: scene, identity: identity);

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
