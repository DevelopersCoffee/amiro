import 'dart:convert';

import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

AmiroSharingPayload _payload({
  String remoteIdentityId = 'id_01h7yxz9m4q2kv7b5rwx182100',
  String displayName = 'Uday',
  String activeAvatarConfig = '{"id":"default","body":"body_superhero_male"}',
  List<EquippedCosmeticInfo> equippedCosmetics = const [
    EquippedCosmeticInfo(
      id: 'riviera_optics',
      name: 'Riviera Optics',
      seriesId: 'series_1',
      rarity: 'RARE',
    ),
  ],
  List<SeriesCompletion> collectionCompletion = const [
    SeriesCompletion(seriesId: 'series_1', currentCount: 2, totalCount: 3),
  ],
}) {
  return AmiroSharingPayload(
    remoteIdentityId: remoteIdentityId,
    displayName: displayName,
    activeAvatarConfig: activeAvatarConfig,
    equippedCosmetics: equippedCosmetics,
    collectionCompletion: collectionCompletion,
  );
}

/// A wire map a legitimate sender would produce, for tests to break one
/// field at a time.
Map<String, dynamic> _wire() => {
      'schemaVersion': 1,
      'remoteIdentityId': 'id_1',
      'displayName': 'Uday',
      'activeAvatarConfig': '{}',
      'equippedCosmetics': <Object>[],
      'collectionCompletion': <Object>[],
    };

void _expectRejected(Map<String, dynamic> wire, PayloadErrorKind kind,
    {String? reason}) {
  expect(
    () => AmiroSharingPayload.decode(jsonEncode(wire)),
    throwsA(
      isA<SharingPayloadException>().having((e) => e.kind, 'kind', kind).having(
          (e) => e.message,
          'message',
          reason == null ? isNotEmpty : contains(reason)),
    ),
    reason: reason,
  );
}

void main() {
  group('valid payloads', () {
    test('a valid v1 payload round-trips to an equal object', () {
      final original = _payload();

      expect(AmiroSharingPayload.decode(original.encode()), original);
    });

    test('an empty cosmetic list and empty collections are valid', () {
      final original =
          _payload(equippedCosmetics: const [], collectionCompletion: const []);

      expect(AmiroSharingPayload.decode(original.encode()), original);
    });

    test('multiple cosmetics keep their order', () {
      final original = _payload(
        equippedCosmetics: const [
          EquippedCosmeticInfo(
              id: 'b', name: 'B', seriesId: null, rarity: 'COMMON'),
          EquippedCosmeticInfo(
              id: 'a', name: 'A', seriesId: 'series_1', rarity: 'RARE'),
        ],
      );

      final decoded = AmiroSharingPayload.decode(original.encode());

      expect(decoded.equippedCosmetics.map((c) => c.id), ['b', 'a']);
      expect(decoded, original);
    });

    test('a collection at 2/3 and a complete one at 3/3 are valid', () {
      final original = _payload(
        collectionCompletion: const [
          SeriesCompletion(
              seriesId: 'series_1', currentCount: 2, totalCount: 3),
          SeriesCompletion(
              seriesId: 'series_2', currentCount: 3, totalCount: 3),
        ],
      );

      expect(AmiroSharingPayload.decode(original.encode()), original);
    });

    test('encoding is deterministic', () {
      expect(_payload().encode(), _payload().encode());
    });

    test('carries the current schema version on the wire', () {
      final wire = jsonDecode(_payload().encode()) as Map<String, dynamic>;

      expect(wire['schemaVersion'], kAmiroSharingSchemaVersion);
    });

    test('unknown extra fields from a newer sender are ignored', () {
      final wire = _wire()..['somethingNew'] = {'x': 1};

      expect(AmiroSharingPayload.decode(jsonEncode(wire)).displayName, 'Uday');
    });

    test('equal payloads have equal hash codes, different ones are not equal',
        () {
      expect(_payload().hashCode, _payload().hashCode);
      expect(_payload(displayName: 'Ada'), isNot(_payload()));
    });
  });

  group('malformed input', () {
    test('malformed JSON is rejected', () {
      expect(
        () => AmiroSharingPayload.decode('{not json'),
        throwsA(isA<SharingPayloadException>()
            .having((e) => e.kind, 'kind', PayloadErrorKind.malformed)),
      );
    });

    test('JSON that is not an object is rejected', () {
      for (final raw in ['[]', '"x"', '5', 'null']) {
        expect(
          () => AmiroSharingPayload.decode(raw),
          throwsA(isA<SharingPayloadException>()
              .having((e) => e.kind, 'kind', PayloadErrorKind.malformed)),
          reason: raw,
        );
      }
    });

    test('a payload over the size limit is rejected before parsing', () {
      final wire = _wire()
        ..['activeAvatarConfig'] = 'x' * maxSharingPayloadBytes;

      _expectRejected(wire, PayloadErrorKind.tooLarge);
    });
  });

  group('schema version', () {
    test('missing schemaVersion is rejected', () {
      _expectRejected(
          _wire()..remove('schemaVersion'), PayloadErrorKind.malformed,
          reason: 'schemaVersion');
    });

    test('a non-integer schemaVersion is rejected', () {
      for (final bad in <Object?>['1', 1.5, null, true]) {
        _expectRejected(
            _wire()..['schemaVersion'] = bad, PayloadErrorKind.malformed);
      }
    });

    test('an unsupported future schemaVersion is rejected as such', () {
      _expectRejected(
          _wire()..['schemaVersion'] = 2, PayloadErrorKind.unsupportedVersion);
    });

    test('schemaVersion 0 and negatives are rejected', () {
      for (final v in [0, -1]) {
        _expectRejected(_wire()..['schemaVersion'] = v,
            PayloadErrorKind.unsupportedVersion);
      }
    });
  });

  group('required fields', () {
    for (final field in [
      'remoteIdentityId',
      'displayName',
      'activeAvatarConfig'
    ]) {
      test('missing $field is rejected', () {
        _expectRejected(_wire()..remove(field), PayloadErrorKind.invalid,
            reason: field);
      });

      test('an empty or non-string $field is rejected', () {
        for (final bad in <Object?>['', 5, null, []]) {
          _expectRejected(_wire()..[field] = bad, PayloadErrorKind.invalid,
              reason: field);
        }
      });
    }

    test('missing lists are rejected', () {
      _expectRejected(
          _wire()..remove('equippedCosmetics'), PayloadErrorKind.invalid);
      _expectRejected(
          _wire()..remove('collectionCompletion'), PayloadErrorKind.invalid);
    });

    test('a list of the wrong type is rejected', () {
      _expectRejected(
          _wire()..['equippedCosmetics'] = 'nope', PayloadErrorKind.invalid);
      _expectRejected(_wire()..['collectionCompletion'] = {'a': 1},
          PayloadErrorKind.invalid);
    });
  });

  group('cosmetics', () {
    Map<String, dynamic> cosmetic(
            {Object? id = 'a', Object? name = 'A', Object? rarity = 'RARE'}) =>
        {'id': id, 'name': name, 'seriesId': 'series_1', 'rarity': rarity};

    test('duplicate cosmetic ids are rejected', () {
      _expectRejected(
        _wire()..['equippedCosmetics'] = [cosmetic(), cosmetic()],
        PayloadErrorKind.invalid,
        reason: 'duplicate',
      );
    });

    test('a cosmetic missing id, name or rarity is rejected', () {
      for (final bad in [
        cosmetic(id: null),
        cosmetic(name: ''),
        cosmetic(rarity: 3)
      ]) {
        _expectRejected(
            _wire()..['equippedCosmetics'] = [bad], PayloadErrorKind.invalid);
      }
    });

    test('a non-object cosmetic entry is rejected', () {
      _expectRejected(
          _wire()..['equippedCosmetics'] = ['a'], PayloadErrorKind.invalid);
    });

    test('a cosmetic without a series (a free item) is valid', () {
      final wire = _wire()
        ..['equippedCosmetics'] = [
          {'id': 'a', 'name': 'A', 'rarity': 'COMMON'},
        ];

      expect(
          AmiroSharingPayload.decode(jsonEncode(wire))
              .equippedCosmetics
              .single
              .seriesId,
          isNull);
    });

    test('more than the maximum number of cosmetics is rejected', () {
      final many = [
        for (var i = 0; i < maxSharedListLength + 1; i++) cosmetic(id: 'c$i')
      ];

      _expectRejected(
          _wire()..['equippedCosmetics'] = many, PayloadErrorKind.invalid);
    });
  });

  group('collection completion', () {
    Map<String, dynamic> series(
            {Object? id = 's1', Object? current = 1, Object? total = 3}) =>
        {'seriesId': id, 'currentCount': current, 'totalCount': total};

    test('a negative count is rejected', () {
      _expectRejected(_wire()..['collectionCompletion'] = [series(current: -1)],
          PayloadErrorKind.invalid);
    });

    test('a total of zero is rejected', () {
      _expectRejected(
          _wire()..['collectionCompletion'] = [series(current: 0, total: 0)],
          PayloadErrorKind.invalid);
    });

    test('a current count above the total is rejected', () {
      _expectRejected(
          _wire()..['collectionCompletion'] = [series(current: 4, total: 3)],
          PayloadErrorKind.invalid);
    });

    test('non-integer counts are rejected', () {
      for (final bad in <Object?>['1', 1.5, null]) {
        _expectRejected(
            _wire()..['collectionCompletion'] = [series(current: bad)],
            PayloadErrorKind.invalid);
      }
    });

    test('duplicate series ids are rejected', () {
      _expectRejected(
        _wire()..['collectionCompletion'] = [series(), series()],
        PayloadErrorKind.invalid,
        reason: 'duplicate',
      );
    });

    test('a missing or empty series id is rejected', () {
      _expectRejected(_wire()..['collectionCompletion'] = [series(id: null)],
          PayloadErrorKind.invalid);
      _expectRejected(_wire()..['collectionCompletion'] = [series(id: '')],
          PayloadErrorKind.invalid);
    });
  });

  group('encode refuses to emit an invalid payload', () {
    test('duplicate cosmetic ids', () {
      const dup = EquippedCosmeticInfo(
          id: 'a', name: 'A', seriesId: null, rarity: 'COMMON');

      expect(
        () => _payload(equippedCosmetics: const [dup, dup]).encode(),
        throwsA(isA<SharingPayloadException>()),
      );
    });

    test('a completion above its total', () {
      expect(
        () => _payload(
          collectionCompletion: const [
            SeriesCompletion(seriesId: 's', currentCount: 5, totalCount: 3),
          ],
        ).encode(),
        throwsA(isA<SharingPayloadException>()),
      );
    });

    test('an oversized payload', () {
      expect(
        () =>
            _payload(activeAvatarConfig: 'x' * maxSharingPayloadBytes).encode(),
        throwsA(
          isA<SharingPayloadException>()
              .having((e) => e.kind, 'kind', PayloadErrorKind.tooLarge),
        ),
      );
    });
  });

  group('SeriesCompletion.isComplete', () {
    test('is true only when every item in the series is collected', () {
      expect(const SeriesCompletion(seriesId: 's', currentCount: 3, totalCount: 3).isComplete, isTrue);
      expect(const SeriesCompletion(seriesId: 's', currentCount: 2, totalCount: 3).isComplete, isFalse);
      expect(const SeriesCompletion(seriesId: 's', currentCount: 0, totalCount: 3).isComplete, isFalse);
    });
  });
}
