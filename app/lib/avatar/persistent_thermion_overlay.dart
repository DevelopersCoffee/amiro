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
/// Tab switches do **not** pause Filament presentation. One [requestPresentationFrame]
/// runs only after a gender [forceReload] while hidden, deferred until the
/// thermion tab is visible (two post-frame delays — not on cold first Avatar).
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
  var _genderPresentScheduled = false;

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

  void _scheduleGenderReloadPresentFrame() {
    if (_genderPresentScheduled) return;
    _genderPresentScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _genderPresentScheduled = false;
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_presentGenderReloadFrame());
      });
    });
  }

  Future<void> _presentGenderReloadFrame() async {
    _genderPresentScheduled = false;
    if (!mounted) return;
    if (!ref.read(genderReloadPresentFrameProvider)) return;

    final scene = ref.read(avatarSceneDefinitionProvider);
    final identity = ref.read(currentIdentityProvider).value;
    if (!_shouldPresentScene(scene: scene, identity: identity)) return;

    ref.read(genderReloadPresentFrameProvider.notifier).set(false);
    final renderer = ref.read(avatarRendererProvider);
    await renderer.resumePresentation();
    await renderer.requestPresentationFrame();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(genderReloadPresentFrameProvider, (previous, pending) {
      if (pending) {
        _scheduleGenderReloadPresentFrame();
      }
    });

    final scene = ref.watch(avatarSceneDefinitionProvider);
    final identity = ref.watch(currentIdentityProvider).value;
    final showScene = _shouldPresentScene(scene: scene, identity: identity);
    final pendingGenderPresent = ref.watch(genderReloadPresentFrameProvider);

    if (showScene && pendingGenderPresent) {
      _scheduleGenderReloadPresentFrame();
    }

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
