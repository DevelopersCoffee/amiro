import 'dart:math';

import 'package:identity_core/identity_core.dart';
import 'package:test/test.dart';

void main() {
  test('a new id is 32 lowercase hex characters', () {
    expect(newIdentityId(), matches(RegExp(r'^[0-9a-f]{32}$')));
  });

  test('two ids created together differ', () {
    final ids = {for (var i = 0; i < 50; i++) newIdentityId()};
    expect(ids, hasLength(50));
  });

  test('a seeded random source is deterministic', () {
    expect(
      newIdentityId(random: Random(7)),
      newIdentityId(random: Random(7)),
    );
  });
}
