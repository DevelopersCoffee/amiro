import 'package:flutter/widgets.dart';

import 'package:avatar_core/avatar_core.dart';

/// Engine-agnostic avatar rendering boundary. Nothing outside this
/// package may import `thermion_flutter` (or any future engine)
/// directly — swap the concrete implementation here without touching
/// callers.
abstract class AvatarRenderer {
  /// The definition currently loaded, or `null` before the first [load].
  AvatarDefinition? get current;

  /// Loads a definition, rendering all populated slots.
  Future<void> load(AvatarDefinition definition);

  /// Returns the widget that displays the live render. Must be called
  /// after [load].
  Widget buildView();

  /// Swaps a single slot on the currently loaded definition and
  /// re-renders. Throws [StateError] if called before [load].
  Future<void> updateSlot(String slot, String? assetId);

  /// Releases engine resources. Must be called when the view is
  /// removed from the tree.
  Future<void> dispose();
}
