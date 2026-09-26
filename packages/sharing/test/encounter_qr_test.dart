import 'dart:convert';

import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

AmiroSharingPayload _payload({
  String displayName = 'Uday',
  String avatar = '{"id":"default","body":"body_superhero_male"}',
  List<EquippedCosmeticInfo>? cosmetics,
}) {
  return AmiroSharingPayload(
    remoteIdentityId: 'id_1',
    displayName: displayName,
    activeAvatarConfig: avatar,
    equippedCosmetics: cosmetics ??
        const [
          EquippedCosmeticInfo(
              id: 'riviera_optics',
              name: 'Riviera Optics',
              seriesId: 'series_1',
              rarity: 'RARE'),
        ],
    collectionCompletion: const [
      SeriesCompletion(seriesId: 'series_1', currentCount: 2, totalCount: 3),
    ],
  );
}

const _contact = ContactCard(
    username: 'uday', bio: 'Engineer', website: 'https://example.com');

String _b64(Object json) =>
    base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

void _expectKind(String uri, PayloadErrorKind kind) {
  expect(
    () => decodeEncounterUri(uri),
    throwsA(isA<SharingPayloadException>().having((e) => e.kind, 'kind', kind)),
  );
}

void main() {
  group('round trip', () {
    test('payload alone survives QR encode and decode', () {
      final original = _payload();

      final decoded = decodeEncounterUri(encodeEncounterUri(original));

      expect(decoded.payload, original);
      expect(decoded.contact, isNull);
    });

    test('payload and contact card survive together', () {
      final decoded =
          decodeEncounterUri(encodeEncounterUri(_payload(), contact: _contact));

      expect(decoded.payload, _payload());
      expect(decoded.contact, _contact);
    });

    test('is deterministic', () {
      expect(encodeEncounterUri(_payload(), contact: _contact),
          encodeEncounterUri(_payload(), contact: _contact));
    });

    test('is an amiro://encounter URI with only URL-safe, unpadded characters',
        () {
      final uri = encodeEncounterUri(_payload(), contact: _contact);

      expect(uri, startsWith('amiro://encounter?d='));
      final query = Uri.parse(uri).queryParameters;
      expect(query['d'], matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      expect(query['c'], matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    });

    test('survives every base64 padding length', () {
      for (var i = 1; i <= 6; i++) {
        final original = _payload(displayName: 'n' * i);

        expect(
            decodeEncounterUri(encodeEncounterUri(original)).payload, original,
            reason: '$i');
      }
    });

    test('a padded base64 payload is still accepted', () {
      final padded = base64Url.encode(utf8.encode(_payload().encode()));

      expect(decodeEncounterUri('amiro://encounter?d=$padded').payload,
          _payload());
    });

    test('a realistic card (7 equipped items, 3 series) fits in a QR code', () {
      final cosmetics = [
        for (var i = 0; i < 7; i++)
          EquippedCosmeticInfo(
              id: 'cosmetic_item_$i',
              name: 'Cosmetic Item $i',
              seriesId: 'series_1',
              rarity: 'UNCOMMON'),
      ];
      final payload = AmiroSharingPayload(
        remoteIdentityId: 'id_01h7yxz9m4q2kv7b5rwx182100',
        displayName: 'Uday Chauhan',
        activeAvatarConfig:
            '{"id":"default","body":"body_superhero_male","glasses":"glasses_realistic",'
            '"top":"top_placeholder","hair":"hair_long","facialHair":"beard_full"}',
        equippedCosmetics: cosmetics,
        collectionCompletion: const [
          SeriesCompletion(
              seriesId: 'series_1', currentCount: 2, totalCount: 3),
          SeriesCompletion(
              seriesId: 'series_2', currentCount: 1, totalCount: 5),
          SeriesCompletion(
              seriesId: 'series_3', currentCount: 0, totalCount: 4),
        ],
      );

      final uri = encodeEncounterUri(payload, contact: _contact);

      expect(uri.length, lessThanOrEqualTo(maxEncounterUriLength));
      expect(decodeEncounterUri(uri).payload, payload);
    });
  });

  group('rejection', () {
    test('another scheme, host or a legacy share link is not an encounter', () {
      _expectKind('https://encounter?d=x', PayloadErrorKind.malformed);
      _expectKind('amiro://other?d=x', PayloadErrorKind.malformed);
      _expectKind(
          'amiro://share?d=${_b64({'v': 1})}', PayloadErrorKind.malformed);
    });

    test('text that is not a URI at all is rejected', () {
      _expectKind('not a uri at all %%%', PayloadErrorKind.malformed);
      _expectKind('', PayloadErrorKind.malformed);
    });

    test('a missing payload parameter is rejected', () {
      _expectKind('amiro://encounter', PayloadErrorKind.malformed);
      _expectKind(
          'amiro://encounter?c=${_b64({})}', PayloadErrorKind.malformed);
    });

    test('a payload that is not valid base64 is rejected', () {
      _expectKind('amiro://encounter?d=***', PayloadErrorKind.malformed);
    });

    test('base64 that does not decode to JSON is rejected', () {
      _expectKind(
          'amiro://encounter?d=${base64Url.encode(utf8.encode('hello'))}',
          PayloadErrorKind.malformed);
    });

    test('an unsupported schema version surfaces as such', () {
      _expectKind('amiro://encounter?d=${_b64({'schemaVersion': 2})}',
          PayloadErrorKind.unsupportedVersion);
    });

    test('a structurally invalid payload is rejected with the payload error',
        () {
      final wire = _payload().toJson()..['remoteIdentityId'] = '';

      _expectKind(
          'amiro://encounter?d=${_b64(wire)}', PayloadErrorKind.invalid);
    });

    test('an oversized URI is rejected before it is decoded', () {
      _expectKind('amiro://encounter?d=${'A' * (maxEncounterUriLength + 1)}',
          PayloadErrorKind.tooLarge);
    });

    test('encode refuses a card too large for a QR code', () {
      final big = _payload(avatar: '{"pad":"${'x' * 2000}"}');

      expect(
        () => encodeEncounterUri(big),
        throwsA(isA<SharingPayloadException>()
            .having((e) => e.kind, 'kind', PayloadErrorKind.tooLarge)),
      );
    });

    test('encode refuses an invalid payload', () {
      expect(
        () => encodeEncounterUri(_payload(displayName: '')),
        throwsA(isA<SharingPayloadException>()),
      );
    });

    test(
        'a contact card that pushes the URI over the limit is rejected, not silently dropped',
        () {
      final fat = ContactCard(
          bio: 'b' * 256,
          website: 'w' * 256,
          email: 'e' * 256,
          mobile: 'm' * 256);
      final nearlyFull = _payload(avatar: '{"pad":"${'x' * 900}"}');

      expect(
        () => encodeEncounterUri(nearlyFull, contact: fat),
        throwsA(isA<SharingPayloadException>()
            .having((e) => e.kind, 'kind', PayloadErrorKind.tooLarge)),
      );
    });
  });

  group('contact card is optional decoration', () {
    test('a malformed contact card is dropped without rejecting the payload',
        () {
      for (final bad in <Object>[
        'nope',
        5,
        [],
        {'bio': 5},
        {'bio': ''},
        {'bio': 'x' * 300}
      ]) {
        final decoded = decodeEncounterUri(
            'amiro://encounter?d=${_b64(_payload().toJson())}&c=${_b64(bad)}');

        expect(decoded.payload, _payload(), reason: '$bad');
        expect(decoded.contact, isNull, reason: '$bad');
      }
    });

    test('undecodable base64 in the contact parameter is dropped too', () {
      final decoded = decodeEncounterUri(
          'amiro://encounter?d=${_b64(_payload().toJson())}&c=***');

      expect(decoded.payload, _payload());
      expect(decoded.contact, isNull);
    });

    test('an empty contact card is not emitted', () {
      final uri = encodeEncounterUri(_payload(), contact: const ContactCard());

      expect(Uri.parse(uri).queryParameters.containsKey('c'), isFalse);
    });

    test('unknown contact fields from a newer sender are ignored', () {
      final decoded = decodeEncounterUri(
        'amiro://encounter?d=${_b64(_payload().toJson())}&c=${_b64({
              'username': 'uday',
              'pronouns': 'x'
            })}',
      );

      expect(decoded.contact, const ContactCard(username: 'uday'));
    });
  });

  group('ContactCard.fromIdentity', () {
    final identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      bio: 'Engineer',
      email: 'private@example.com',
      mobile: '555-0100',
      xHandle: '@uday',
      privacy: const {
        'username': PrivacyFlag(true),
        'bio': PrivacyFlag(true),
        'email': PrivacyFlag(false),
        'xHandle': PrivacyFlag(true),
        // mobile has no flag: private by default
      },
    );

    test('includes only fields flagged public', () {
      final card = ContactCard.fromIdentity(identity);

      expect(card.username, 'uday');
      expect(card.bio, 'Engineer');
      expect(card.xHandle, '@uday');
    });

    test('leaves out private and unflagged fields', () {
      final card = ContactCard.fromIdentity(identity);

      expect(card.email, isNull);
      expect(card.mobile, isNull);
    });

    test('an identity that shares nothing produces an empty card', () {
      final card = ContactCard.fromIdentity(
          Identity(id: 'i', displayName: 'U', username: 'u'));

      expect(card.isEmpty, isTrue);
    });

    test(
        'is never larger than a field cap: over-long values are cut, not sent whole',
        () {
      final long = Identity(
        id: 'i',
        displayName: 'U',
        username: 'u',
        bio: 'b' * 1000,
        privacy: const {'bio': PrivacyFlag(true)},
      );

      expect(ContactCard.fromIdentity(long).bio!.length,
          lessThanOrEqualTo(maxContactFieldLength));
    });
  });
}
