import 'dart:async';
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

  group('decodeEncounterFromNdef', () {
    test('a text record round-trips payload and contact card', () {
      final decoded = decodeEncounterFromNdef([_text(_link)]);

      expect(decoded.payload, _payload());
      expect(decoded.contact, const ContactCard(username: 'uday'));
    });

    test('a URI record round-trips too', () {
      expect(decodeEncounterFromNdef([_uri(_link)]).payload, _payload());
    });

    test('finds the encounter behind an Android Application Record', () {
      expect(
          decodeEncounterFromNdef([_androidAppRecord(), _text(_link)]).payload,
          _payload());
    });

    test('no records, or none that is an encounter, is malformed', () {
      for (final records in [
        <NdefRecordData>[],
        [_androidAppRecord()],
        [_text('just some text')],
        [
          _text('amiro://share?d=abc')
        ], // a legacy share link is not an encounter
      ]) {
        expect(
          () => decodeEncounterFromNdef(records),
          throwsA(isA<SharingPayloadException>()
              .having((e) => e.kind, 'kind', PayloadErrorKind.malformed)),
        );
      }
    });

    test(
        'an encounter record with a bad payload is rejected with the payload error',
        () {
      final future =
          'amiro://encounter?d=${base64Url.encode(utf8.encode('{"schemaVersion":2}')).replaceAll('=', '')}';

      expect(
        () => decodeEncounterFromNdef([_text(future)]),
        throwsA(isA<SharingPayloadException>().having(
            (e) => e.kind, 'kind', PayloadErrorKind.unsupportedVersion)),
      );
    });

    test('an invalid encounter record is not papered over by a later valid one',
        () {
      final bad = 'amiro://encounter?d=***';

      expect(() => decodeEncounterFromNdef([_text(bad), _text(_link)]),
          throwsA(isA<SharingPayloadException>()));
    });
  });

  group('encodeNdefTextPayload', () {
    test('writes a status byte, the language code, then UTF-8 text', () {
      expect(encodeNdefTextPayload('hi'),
          Uint8List.fromList([0x02, ...'en'.codeUnits, ...'hi'.codeUnits]));
    });
  });

  group('ingestNfcReads', () {
    late StreamController<List<NdefRecordData>> source;
    late DateTime now;
    late Stream<NfcRead> reads;
    late List<NfcRead> seen;

    setUp(() {
      source = StreamController<List<NdefRecordData>>();
      now = DateTime.utc(2026, 9, 26, 10);
      reads = ingestNfcReads(source.stream,
          clock: () => now, duplicateWindow: const Duration(seconds: 3));
      seen = [];
      reads.listen(seen.add);
    });

    tearDown(() => source.close());

    Future<void> tick() => Future<void>.delayed(Duration.zero);

    test('a valid tag becomes an NfcEncounterRead', () async {
      source.add([_text(_link)]);
      await tick();

      expect(seen.single, isA<NfcEncounterRead>());
      expect((seen.single as NfcEncounterRead).encounter.payload, _payload());
    });

    test('garbage becomes a rejection, never an exception', () async {
      source.add([_text('hello')]);
      await tick();

      expect(seen.single, isA<NfcReadRejected>());
    });

    test('a hardware dropout becomes a rejection and the stream keeps working',
        () async {
      source.addError(StateError('tag lost'));
      await tick();
      now = now.add(const Duration(seconds: 10));
      source.add([_text(_link)]);
      await tick();

      expect(seen.first, isA<NfcReadRejected>());
      expect(seen.last, isA<NfcEncounterRead>());
      expect(seen, hasLength(2));
    });

    test('the same tag read repeatedly inside the window is reported once',
        () async {
      for (var i = 0; i < 4; i++) {
        source.add([_text(_link)]);
        now = now.add(const Duration(milliseconds: 400));
        await tick();
      }

      expect(seen, hasLength(1));
    });

    test('the same tag again after the window is reported again', () async {
      source.add([_text(_link)]);
      await tick();
      now = now.add(const Duration(seconds: 4));
      source.add([_text(_link)]);
      await tick();

      expect(seen, hasLength(2));
    });

    test('two different tags close together are both reported', () async {
      source.add([_text(_link)]);
      source.add([_text(encodeEncounterUri(_payload(name: 'Ada')))]);
      await tick();

      expect(seen, hasLength(2));
    });

    test('repeated identical garbage inside the window is one rejection',
        () async {
      source.add([_text('hello')]);
      source.add([_text('hello')]);
      await tick();

      expect(seen, hasLength(1));
    });

    test('closing the source closes the stream', () async {
      final done = Completer<void>();
      ingestNfcReads(Stream<List<NdefRecordData>>.empty())
          .listen(null, onDone: done.complete);

      await done.future;
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
