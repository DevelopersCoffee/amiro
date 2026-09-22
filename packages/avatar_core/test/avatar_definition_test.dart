import 'package:avatar_core/avatar_core.dart';
import 'package:test/test.dart';

void main() {
  group('AvatarDefinition', () {
    test('slots contains all 18 PRD-defined slots', () {
      expect(AvatarDefinition.slots, [
        'body',
        'face',
        'skin',
        'hair',
        'eyes',
        'eyebrows',
        'facialHair',
        'top',
        'bottom',
        'shoes',
        'glasses',
        'earrings',
        'necklace',
        'goldChain',
        'watch',
        'hat',
        'background',
        'effects',
      ]);
    });

    test('constructs with only the slots this pass populates', () {
      const def = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder');

      expect(def.body, 'body_placeholder');
      expect(def.top, isNull);
      expect(def.glasses, isNull);
    });

    test('copyWithSlot updates exactly one slot and leaves others untouched', () {
      const def = AvatarDefinition(id: 'avatar-1', body: 'body_placeholder', top: 'top_01');

      final updated = def.copyWithSlot('glasses', 'glasses_01');

      expect(updated.glasses, 'glasses_01');
      expect(updated.top, 'top_01');
      expect(updated.body, 'body_placeholder');
    });

    test('copyWithSlot rejects an unknown slot name', () {
      const def = AvatarDefinition(id: 'avatar-1');
      expect(() => def.copyWithSlot('cape', 'cape_01'), throwsArgumentError);
    });

    test('toJson/fromJson round trip', () {
      const def = AvatarDefinition(
        id: 'avatar-1',
        body: 'body_placeholder',
        top: 'top_01',
        glasses: 'glasses_01',
      );

      final restored = AvatarDefinition.fromJson(def.toJson());

      expect(restored.id, def.id);
      expect(restored.body, def.body);
      expect(restored.top, def.top);
      expect(restored.glasses, def.glasses);
      expect(restored.hat, isNull);
    });
  });
}
