import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avatar_core/avatar_core.dart';

import 'avatar_providers.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  bool _loaded = false;
  bool _glassesOn = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      const definition = AvatarDefinition(
        id: 'default',
        body: 'body_placeholder',
        top: 'top_placeholder',
      );
      ref.read(avatarRendererProvider).load(definition).then((_) => setState(() {}));
    }
  }

  Future<void> _toggleGlasses() async {
    final renderer = ref.read(avatarRendererProvider);
    final next = !_glassesOn;
    await renderer.updateSlot('glasses', next ? 'glasses_placeholder' : null);
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
