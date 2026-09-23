import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:store/store.dart';

import 'avatar_loader.dart';
import 'avatar_loading_indicator.dart';
import 'avatar_providers.dart';

class AvatarScreen extends ConsumerStatefulWidget {
  const AvatarScreen({super.key});

  @override
  ConsumerState<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends ConsumerState<AvatarScreen> {
  bool _didInit = false;
  bool _loading = true;
  bool _glassesOn = false;

  // The reveal ceremony (avatar materializes before chrome appears) plays
  // only on first-ever avatar creation — see DESIGN.md's Motion section.
  // `_revealing` gates the equip button/app bar chrome until it finishes;
  // a returning user has nothing to reveal, so chrome shows immediately.
  bool _revealing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _init();
  }

  Future<void> _init() async {
    final result = await ensureAvatarLoaded(ref);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _revealing = result.isFirstReveal;
      _glassesOn = result.definition.glasses != null;
    });
  }

  Future<void> _toggleGlasses() async {
    final renderer = ref.read(avatarRendererProvider);
    final next = !_glassesOn;
    await renderer.updateSlot('glasses', next ? 'glasses_realistic' : null);
    final updated = renderer.current;
    if (updated != null) {
      await persistAvatarDefinition(ref, updated);
    }
    if (!mounted) return;
    setState(() => _glassesOn = next);
  }

  @override
  Widget build(BuildContext context) {
    final renderer = ref.watch(avatarRendererProvider);
    final current = renderer.current;
    // Sums whatever's equipped against the store catalog's prices — not
    // gated on ownership, since equipping today (the debug toggle button)
    // bypasses the store's buy flow entirely (see TODOS.md #5/#6).
    final valuationCents =
        current == null ? 0 : avatarValuationCents(current, cosmeticCatalog);

    final showChrome = !_loading && !_revealing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Avatar'),
        actions: [
          if (showChrome)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('\$${(valuationCents / 100).toStringAsFixed(2)}'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const AvatarLoadingIndicator()
                : _revealing
                    ? _AvatarReveal(
                        onRevealed: () => setState(() => _revealing = false),
                        child: renderer.buildView(),
                      )
                    : renderer.buildView(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: showChrome
                ? Semantics(
                    button: true,
                    label: _glassesOn ? 'Remove glasses' : 'Add glasses',
                    child: FilledButton(
                      key: const Key('toggleGlassesButton'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: _toggleGlasses,
                      child: Text(_glassesOn ? 'Remove glasses' : 'Add glasses'),
                    ),
                  )
                : const SizedBox(height: 44),
          ),
        ],
      ),
    );
  }
}

/// The one authored motion moment (DESIGN.md): the avatar fades and scales
/// in on first-ever creation, ease-out, before [onRevealed] fires and the
/// screen's chrome (equip button, valuation) appears.
class _AvatarReveal extends StatefulWidget {
  final Widget child;
  final VoidCallback onRevealed;

  const _AvatarReveal({required this.child, required this.onRevealed});

  @override
  State<_AvatarReveal> createState() => _AvatarRevealState();
}

class _AvatarRevealState extends State<_AvatarReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward().whenComplete(widget.onRevealed);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.0).animate(curved),
        child: widget.child,
      ),
    );
  }
}
