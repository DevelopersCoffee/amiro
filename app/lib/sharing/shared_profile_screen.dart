import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:sharing/sharing.dart';

import '../avatar/avatar_providers.dart';

/// Read-only view of someone else's shared identity — reached via QR scan
/// or NFC tap. Renders their avatar through the same [AvatarRenderer] the
/// app already uses for the owner's own avatar; it's just handed a
/// different [AvatarDefinition].
class SharedProfileScreen extends ConsumerStatefulWidget {
  final SharedProfile profile;

  const SharedProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<SharedProfileScreen> createState() => _SharedProfileScreenState();
}

class _SharedProfileScreenState extends ConsumerState<SharedProfileScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final json = widget.profile.avatarDefinitionJson;
    if (json != null) {
      final definition = AvatarDefinition.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
      ref.read(avatarRendererProvider).load(definition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final renderer = ref.watch(avatarRendererProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Amiro')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (profile.avatarDefinitionJson != null)
            SizedBox(height: 240, child: renderer.buildView()),
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
