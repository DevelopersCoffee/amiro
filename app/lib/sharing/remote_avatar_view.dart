import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';

import '../avatar/avatar_providers.dart';

/// Someone else's avatar, rendered by a fresh renderer this widget owns.
///
/// Deliberately *not* the app-lifetime singleton behind
/// [avatarRendererProvider]: that renderer's `load()` is additive, so
/// loading a stranger's definition into it would bleed their meshes into the
/// user's own live scene and corrupt `AvatarScreen`'s re-entry guard. This
/// widget builds its own via [avatarRendererFactoryProvider] and disposes it
/// with itself.
///
/// The definition comes from a scanned or stored card, so it is untrusted:
/// any failure to parse or load leaves the placeholder instead of throwing.
class RemoteAvatarView extends ConsumerStatefulWidget {
  /// The avatar definition JSON from the other person's card.
  final String avatarConfigJson;
  final double height;

  const RemoteAvatarView({
    super.key,
    required this.avatarConfigJson,
    this.height = 240,
  });

  @override
  ConsumerState<RemoteAvatarView> createState() => _RemoteAvatarViewState();
}

class _RemoteAvatarViewState extends ConsumerState<RemoteAvatarView> {
  bool _initStarted = false;
  AvatarRenderer? _renderer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initStarted) return;
    _initStarted = true;
    _init();
  }

  Future<void> _init() async {
    // Declared outside the `try` so the `catch` can dispose it if the factory
    // succeeded but `load()` (fed by untrusted data) then failed; otherwise
    // the already-constructed engine instance would leak.
    AvatarRenderer? renderer;
    try {
      final createRenderer = ref.read(avatarRendererFactoryProvider);
      renderer = await createRenderer();
      final definition = AvatarDefinition.fromJson(
        jsonDecode(widget.avatarConfigJson) as Map<String, dynamic>,
      );
      await renderer.load(definition);

      if (!mounted) {
        await renderer.dispose();
        return;
      }
      setState(() => _renderer = renderer);
    } catch (error) {
      await renderer?.dispose();
      debugPrint('RemoteAvatarView: failed to load avatar: $error');
    }
  }

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderer = _renderer;
    return SizedBox(
      height: widget.height,
      child: renderer != null
          ? renderer.buildView()
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
