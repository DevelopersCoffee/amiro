import 'package:flutter/material.dart';

import 'package:avatar_core/avatar_core.dart';
import 'package:avatar_renderer/avatar_renderer.dart';

class FakeAvatarRenderer implements AvatarRenderer {
  AvatarDefinition? _current;
  final List<String> calls = [];

  @override
  AvatarDefinition? get current => _current;

  @override
  Future<void> load(AvatarDefinition definition) async {
    calls.add('load:${definition.id}');
    _current = definition;
  }

  @override
  Widget buildView() => const ColoredBox(color: Colors.grey, child: SizedBox(height: 200));

  @override
  Future<void> updateSlot(String slot, String? assetId) async {
    calls.add('updateSlot:$slot:$assetId');
    _current = _current!.copyWithSlot(slot, assetId);
  }

  @override
  Future<void> dispose() async {}
}
