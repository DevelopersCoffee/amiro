import 'dart:convert';
import 'dart:typed_data';

import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

AmiroSharingPayload _payload({String name = 'Uday'}) => AmiroSharingPayload(
      remoteIdentityId: 'id_1',
      displayName: name,
      activeAvatarConfig: '{"id":"a"}',
      equippedCosmetics: const [],
      collectionCompletion: const [],
    );

final _link = encodeEncounterUri(_payload(),
    contact: const ContactCard(username: 'uday'));

NdefRecordData _text(String text, {String lang = 'en'}) => NdefRecordData(
    tnf: ndefTnfWellKnown,
    type: [0x54],
    payload: encodeNdefTextPayload(text, languageCode: lang));

NdefRecordData _uri(String uri, {int prefix = 0}) => NdefRecordData(
    tnf: ndefTnfWellKnown,
    type: [0x55],
    payload: [prefix, ...utf8.encode(uri)]);

NdefRecordData _androidAppRecord() => NdefRecordData(
      tnf: 0x04, // external type
      type: utf8.encode('android.com:pkg'),
      payload: utf8.encode('com.example.amiro'),
    );

void main() {
  group('ndefRecordText: text records', () {
    test('UTF-8 with a 2-byte language code', () {
      expect(ndefRecordText(_text('hello')), 'hello');
    });

    test('a zero-length language code', () {
      final record = NdefRecordData(
          tnf: ndefTnfWellKnown,
          type: const [0x54],
          payload: [0x00, ...utf8.encode('hi')]);

      expect(ndefRecordText(record), 'hi');
    });

    test('a longer language code', () {
      expect(ndefRecordText(_text('payload', lang: 'en-US')), 'payload');
    });

    test('non-ASCII text decodes as UTF-8, not Latin-1', () {
      expect(ndefRecordText(_text('Zoë ✨')), 'Zoë ✨');
    });

    test('UTF-16 big-endian text (status bit 7) decodes as UTF-16', () {
      final units = 'Zoë'.codeUnits;
      final record = NdefRecordData(
        tnf: ndefTnfWellKnown,
        type: const [0x54],
        payload: [
          0x82,
          ...'en'.codeUnits,
          for (final u in units) ...[u >> 8, u & 0xFF]
        ],
      );

      expect(ndefRecordText(record), 'Zoë');
    });

    test('UTF-16 with a little-endian byte-order mark', () {
      final units = 'hi'.codeUnits;
      final record = NdefRecordData(
        tnf: ndefTnfWellKnown,
        type: const [0x54],
        payload: [
          0x82,
          ...'en'.codeUnits,
          0xFF,
          0xFE,
          for (final u in units) ...[u & 0xFF, u >> 8]
        ],
      );

      expect(ndefRecordText(record), 'hi');
    });

    test('invalid UTF-8 is rejected, not repaired', () {
      final record = NdefRecordData(
          tnf: ndefTnfWellKnown,
          type: const [0x54],
          payload: [0x00, 0xFF, 0xFE, 0x41]);

      expect(ndefRecordText(record), isNull);
    });

    test('an odd number of UTF-16 bytes is rejected', () {
      final record = NdefRecordData(
          tnf: ndefTnfWellKnown,
          type: const [0x54],
          payload: [0x80, 0x00, 0x41, 0x00]);

      expect(ndefRecordText(record), isNull);
    });

    test('empty payload and an overflowing language length are rejected', () {
      expect(
          ndefRecordText(NdefRecordData(
              tnf: ndefTnfWellKnown, type: const [0x54], payload: const [])),
          isNull);
      expect(
        ndefRecordText(NdefRecordData(
            tnf: ndefTnfWellKnown,
            type: const [0x54],
            payload: const [0x3F, 0x41])),
        isNull,
      );
    });
  });

  group('ndefRecordText: URI records', () {
    test('an unabbreviated URI (prefix 0) is read as UTF-8', () {
      expect(ndefRecordText(_uri('amiro://encounter?d=x')),
          'amiro://encounter?d=x');
    });

    test('an abbreviated prefix is not one of ours and is skipped', () {
      expect(ndefRecordText(_uri('example.com', prefix: 0x04)), isNull);
    });
  });

  group('ndefRecordText: what is skipped', () {
    test('records that are not well-known text or URI', () {
      expect(ndefRecordText(_androidAppRecord()), isNull);
      expect(
          ndefRecordText(NdefRecordData(
              tnf: ndefTnfWellKnown,
              type: const [0x53, 0x70],
              payload: const [1])),
          isNull);
      expect(
          ndefRecordText(NdefRecordData(
              tnf: 0x02, type: const [0x54], payload: [0, 0x41])),
          isNull);
    });

    test('a record over the size cap', () {
      final big = NdefRecordData(
        tnf: ndefTnfWellKnown,
        type: const [0x54],
        payload: [0x00, ...List.filled(maxNdefRecordBytes, 0x41)],
      );

      expect(ndefRecordText(big), isNull);
    });
  });

  group('encodeNdefTextPayload', () {
    test('writes a status byte, the language code, then UTF-8 text', () {
      expect(encodeNdefTextPayload('hi'),
          Uint8List.fromList([0x02, ...'en'.codeUnits, ...'hi'.codeUnits]));
    });
  });

  group('amiroLinkTextFromNdef', () {
    test('finds an encounter link, a legacy share link, or nothing', () {
      expect(amiroLinkTextFromNdef([_text(_link)]), _link);
      expect(amiroLinkTextFromNdef([_text('amiro://share?d=abc')]), 'amiro://share?d=abc');
      expect(amiroLinkTextFromNdef([_text('hello')]), isNull);
      expect(amiroLinkTextFromNdef(const []), isNull);
    });

    test('skips other records and reads non-ASCII text properly', () {
      expect(amiroLinkTextFromNdef([_androidAppRecord(), _uri(_link)]), _link);
    });

    test('takes the first Amiro link on the tag', () {
      expect(amiroLinkTextFromNdef([_text('amiro://share?d=first'), _text(_link)]), 'amiro://share?d=first');
    });
  });
}
