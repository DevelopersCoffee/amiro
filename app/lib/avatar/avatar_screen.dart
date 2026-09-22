import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';

import '../identity/identity_providers.dart';
import 'avatar_providers.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

const _defaultDefinition = AvatarDefinition(
  id: 'default',
  body: 'body_placeholder',
  top: 'top_placeholder',
);

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  bool _didInit = false;
  bool _glassesOn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _init();
  }

  Future<void> _init() async {
    // The renderer is an app-lifetime singleton, but this State is recreated
    // every time the user switches back to the Avatar tab. Reloading here
    // would queue a duplicate set of Filament asset loads and reset the UI's
    // idea of what is equipped. Once loaded, it stays loaded.
    final renderer = ref.read(avatarRendererProvider);
    final loaded = renderer.current;
    if (loaded != null) {
      if (!mounted) return;
      setState(() => _glassesOn = loaded.glasses != null);
      return;
    }

    final identity = await ref.read(currentIdentityProvider.future);
    final persisted = identity?.avatarDefinitionJson;
    final definition = persisted == null
        ? _defaultDefinition
        : AvatarDefinition.fromJson(jsonDecode(persisted) as Map<String, dynamic>);

    await renderer.load(definition);
    await _persist(definition);

    if (!mounted) return;
    setState(() => _glassesOn = definition.glasses != null);
  }

  /// Stores the definition on the current [Identity], closing the spec's
  /// "definition JSON -> render -> swap -> persist" pipeline. No-op when the
  /// user hasn't created an identity yet — there's nothing to attach it to.
  Future<void> _persist(AvatarDefinition definition) async {
    final identity = ref.read(currentIdentityProvider).value;
    if (identity == null) return;
    await ref.read(currentIdentityProvider.notifier).save(
          identity.copyWith(
            avatarDefinitionJson: jsonEncode(definition.toJson()),
          ),
        );
  }

  Future<void> _toggleGlasses() async {
    final renderer = ref.read(avatarRendererProvider);
    final next = !_glassesOn;
    await renderer.updateSlot('glasses', next ? 'glasses_placeholder' : null);
    final updated = renderer.current;
    if (updated != null) {
      await _persist(updated);
    }
    if (!mounted) return;
    setState(() => _glassesOn = next);
  }

  @override
  Widget build(BuildContext context) {
    final renderer = ref.watch(avatarRendererProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Avatar')),
      body: Column(
        children: [
          Expanded(child: renderer.buildView()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              key: const Key('toggleGlassesButton'),
              onPressed: _toggleGlasses,
              child: Text(_glassesOn ? 'Remove glasses' : 'Add glasses'),
            ),
          ),
        ],
      ),
    );
  }
}
