import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';

import 'package:identity_core/identity_core.dart';

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
  bool _lastShouldPresent = false;

  /// Serializes pause/resume/frame so rapid tab switches cannot overlap Filament
  /// presentation calls (SwapChain must stay valid through endFrame).
  Future<void> _presentationChain = Future<void>.value();

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
  void didUpdateWidget(covariant PersistentThermionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTabIndex != widget.activeTabIndex) {
      _schedulePresentationReconcile();
    }
  }

  @override
  void initState() {
    super.initState();
    _schedulePresentationReconcile();
  }

  void _schedulePresentationReconcile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_reconcilePresentation());
    });
  }

  Future<void> _enqueuePresentation(Future<void> Function() action) {
    final next = _presentationChain.then((_) async {
      if (!mounted) return;
      await action();
    });
    _presentationChain = next.catchError((_) {});
    return next;
  }

  Future<void> _resumeWithOptionalFrame(
    AvatarRenderer renderer, {
    required bool drawFrame,
  }) async {
    await renderer.resumePresentation();
    if (drawFrame) {
      await renderer.requestPresentationFrame();
    }
  }

  Future<void> _reconcilePresentation() async {
    await _enqueuePresentation(() async {
      final scene = ref.read(avatarSceneDefinitionProvider);
      final identity = ref.read(currentIdentityProvider).value;
      final shouldPresent =
          _shouldPresentScene(scene: scene, identity: identity);
      if (_lastShouldPresent == shouldPresent) return;

      final wasPresenting = _lastShouldPresent;
      _lastShouldPresent = shouldPresent;

      final renderer = ref.read(avatarRendererProvider);
      if (shouldPresent) {
        await _resumeWithOptionalFrame(
          renderer,
          drawFrame: !wasPresenting,
        );
      } else {
        await renderer.pausePresentation();
      }
    });
  }

  Future<void> _pokeAfterSceneReload() async {
    await _enqueuePresentation(() async {
      final scene = ref.read(avatarSceneDefinitionProvider);
      final identity = ref.read(currentIdentityProvider).value;
      if (!_shouldPresentScene(scene: scene, identity: identity)) return;

      _lastShouldPresent = true;
      await _resumeWithOptionalFrame(
        ref.read(avatarRendererProvider),
        drawFrame: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(avatarSceneDefinitionProvider, (previous, next) {
      if (previous == next || next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_pokeAfterSceneReload());
      });
    });
    ref.listen(currentIdentityProvider, (_, __) {
      _schedulePresentationReconcile();
    });

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
