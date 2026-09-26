import 'dart:math';

import 'package:discovery/discovery.dart';
import 'package:test/test.dart';

void main() {
  test('is 26 Crockford base32 characters', () {
    expect(newLocalRecordId(), matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')));
  });

  test('is unique across many calls in the same millisecond', () {
    final now = DateTime.utc(2026, 9, 26);
    final ids = {for (var i = 0; i < 1000; i++) newLocalRecordId(now: now)};

    expect(ids, hasLength(1000));
  });

  test('sorts by creation time', () {
    final earlier = newLocalRecordId(now: DateTime.utc(2026, 9, 26, 10));
    final later = newLocalRecordId(now: DateTime.utc(2026, 9, 26, 10, 0, 1));

    expect(earlier.compareTo(later), lessThan(0));
  });

  test('is deterministic for a fixed clock and random source', () {
    final now = DateTime.utc(2026, 9, 26);

    expect(
      newLocalRecordId(now: now, random: Random(7)),
      newLocalRecordId(now: now, random: Random(7)),
    );
  });
}
