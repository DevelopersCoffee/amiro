import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';
import 'package:sharing/sharing.dart';

import '../avatar/avatar_providers.dart';

/// Read-only view of someone else's shared identity — reached via QR scan
/// or NFC tap.
///
/// Renders their avatar through a fresh, screen-scoped [AvatarRenderer]
/// obtained from [avatarRendererFactoryProvider] — deliberately *not* the
/// app-lifetime singleton behind [avatarRendererProvider] that backs the
/// user's own `AvatarScreen`. That renderer's `load()` is additive (it
/// doesn't clear previously-loaded slots first), so loading a stranger's
/// definition into it would bleed their meshes into the user's own live
/// scene and overwrite the singleton's `current`, corrupting
/// `AvatarScreen`'s re-entry guard on the way back. This screen owns its
/// renderer for its own lifetime and disposes it when it goes away.
class SharedProfileScreen extends ConsumerStatefulWidget {
  final SharedProfile profile;

  const SharedProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<SharedProfileScreen> createState() => _SharedProfileScreenState();
}

class _SharedProfileScreenState extends ConsumerState<SharedProfileScreen> {
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
    final json = widget.profile.avatarDefinitionJson;
    if (json == null) return;

    try {
      final createRenderer = ref.read(avatarRendererFactoryProvider);
      final renderer = await createRenderer();
      final definition = AvatarDefinition.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      await renderer.load(definition);

      if (!mounted) {
        await renderer.dispose();
        return;
      }
      setState(() => _renderer = renderer);
    } catch (error) {
      // Best-effort preview — a scanned/malformed avatar definition or a
      // renderer-construction failure shouldn't crash the screen or leave
      // an unhandled future exception; the rest of the profile (name,
      // username, bio, contact fields) still renders fine without it.
      debugPrint('SharedProfileScreen: failed to load shared avatar: $error');
    }
  }

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final renderer = _renderer;

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Amiro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (profile.avatarDefinitionJson != null)
            SizedBox(
              height: 240,
              child: renderer != null
                  ? renderer.buildView()
                  : const Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 16),
          Text(profile.displayName, style: Theme.of(context).textTheme.headlineSmall),
          Text('@${profile.username}'),
          if (profile.bio != null) ...[
            const SizedBox(height: 8),
            Text(profile.bio!),
          ],
          const SizedBox(height: 24),
          if (profile.email != null) Text('Email: ${profile.email}'),
          if (profile.mobile != null) Text('Mobile: ${profile.mobile}'),
          if (profile.xHandle != null) Text('X: ${profile.xHandle}'),
          if (profile.instagramHandle != null) Text('Instagram: ${profile.instagramHandle}'),
          if (profile.website != null) Text('Website: ${profile.website}'),
        ],
      ),
    );
  }
}
