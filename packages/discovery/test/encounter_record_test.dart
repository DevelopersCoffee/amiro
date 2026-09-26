import 'dart:convert';

import 'package:discovery/discovery.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('EncounterRecord', () {
    test('round-trips through JSON to an equal record', () {
      final original = record(
        encounterCount: 3,
        lastEncountered: t0.add(const Duration(days: 2)),
      );

      final restored = EncounterRecord.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );

      expect(restored, original);
    });

    test('keeps localRecordId and remoteIdentityId as separate fields', () {
      final r = record(localRecordId: 'L', remoteIdentityId: 'R');

      expect(r.toJson()['localRecordId'], 'L');
      expect(r.toJson()['remoteIdentityId'], 'R');
    });

    test('copyWith changes only what it is given', () {
      final original = record();

      final updated = original.copyWith(
        encounterCount: 2,
        displayName: 'Ada L.',
      );

      expect(updated.encounterCount, 2);
      expect(updated.displayName, 'Ada L.');
      expect(updated.localRecordId, original.localRecordId);
      expect(updated.firstEncountered, original.firstEncountered);
    });

    test('equal records have equal hash codes; different ones differ', () {
      expect(record().hashCode, record().hashCode);
      expect(record(displayName: 'Bea'), isNot(record()));
    });

    test('exposes immutable lists', () {
      final r = record();

      expect(
        () => r.observedCosmetics.add(r.observedCosmetics.first),
        throwsUnsupportedError,
      );
      expect(() => r.observedCollections.clear(), throwsUnsupportedError);
    });

    test('a record with an empty id or name is rejected at construction', () {
      expect(() => record(localRecordId: ''), throwsArgumentError);
      expect(() => record(remoteIdentityId: ''), throwsArgumentError);
      expect(() => record(displayName: ''), throwsArgumentError);
    });

    test('an encounter count below 1 is rejected', () {
      expect(() => record(encounterCount: 0), throwsArgumentError);
    });

    test('lastEncountered before firstEncountered is rejected', () {
      expect(
        () => record(lastEncountered: t0.subtract(const Duration(seconds: 1))),
        throwsArgumentError,
      );
    });

    group('fromJson', () {
      Map<String, dynamic> wire() => record().toJson();

      test('rejects a non-object', () {
        expect(() => EncounterRecord.fromJson('x'), throwsFormatException);
        expect(() => EncounterRecord.fromJson(null), throwsFormatException);
      });

      test('rejects a missing or wrongly typed field', () {
        for (final field in [
          'localRecordId',
          'remoteIdentityId',
          'displayName',
          'firstEncountered',
          'lastEncountered',
          'encounterCount',
          'latestAvatarConfig',
          'observedCosmetics',
          'observedCollections',
        ]) {
          expect(
            () => EncounterRecord.fromJson(wire()..remove(field)),
            throwsFormatException,
            reason: field,
          );
          expect(
            () => EncounterRecord.fromJson(wire()..[field] = 12.5),
            throwsFormatException,
            reason: field,
          );
        }
      });

      test('rejects an unparseable date', () {
        expect(
          () => EncounterRecord.fromJson(
            wire()..['firstEncountered'] = 'yesterday',
          ),
          throwsFormatException,
        );
      });

      test('rejects a count below 1 and reversed dates as format errors', () {
        expect(
          () => EncounterRecord.fromJson(wire()..['encounterCount'] = 0),
          throwsFormatException,
        );
        expect(
          () => EncounterRecord.fromJson(
            wire()
              ..['lastEncountered'] = t0
                  .subtract(const Duration(days: 1))
                  .toIso8601String(),
          ),
          throwsFormatException,
        );
      });

      test('rejects an invalid nested cosmetic or collection', () {
        expect(
          () => EncounterRecord.fromJson(
            wire()
              ..['observedCosmetics'] = [
                {'id': ''},
              ],
          ),
          throwsFormatException,
        );
        expect(
          () =>
              EncounterRecord.fromJson(wire()..['observedCollections'] = ['x']),
          throwsFormatException,
        );
      });
    });
  });
}
