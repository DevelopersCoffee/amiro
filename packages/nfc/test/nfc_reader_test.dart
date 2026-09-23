import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nfc/src/nfc_reader.dart';

/// Tests for [decodeNdefTextPayload], the pure status-byte +
/// language-code-length parsing pulled out of [ManagerNfcReader] so it's
/// testable without real NFC hardware (design spec §8, same seam-and-fake
/// pattern as `ThermionFilamentSurface`).
void main() {
  test('empty payload returns null', () {
    expect(decodeNdefTextPayload(Uint8List(0)), isNull);
  });

  test('decodes text with a 2-byte language code (e.g. "en")', () {
    // Status byte: language code length = 2, UTF-8 encoding bit unset.
    final payload = Uint8List.fromList([
      0x02, // status byte: languageCodeLength = 2
      ...'en'.codeUnits,
      ...'hello'.codeUnits,
    ]);

    expect(decodeNdefTextPayload(payload), 'hello');
  });

  test('decodes text with a 0-byte language code', () {
    final payload = Uint8List.fromList([
      0x00, // status byte: languageCodeLength = 0
      ...'amiro://share?d=abc'.codeUnits,
    ]);

    expect(decodeNdefTextPayload(payload), 'amiro://share?d=abc');
  });

  test('decodes text with a longer (5-byte) language code', () {
    final payload = Uint8List.fromList([
      0x05, // status byte: languageCodeLength = 5
      ...'en-US'.codeUnits,
      ...'payload'.codeUnits,
    ]);

    expect(decodeNdefTextPayload(payload), 'payload');
  });

  test('status byte high bits (UTF-16 flag) are masked off and ignored', () {
    // 0x80 sets the UTF-16 flag (bit 7); low 6 bits still encode length 2.
    final payload = Uint8List.fromList([
      0x82,
      ...'en'.codeUnits,
      ...'hi'.codeUnits,
    ]);

    expect(decodeNdefTextPayload(payload), 'hi');
  });

  test('payload with only a status byte and no text returns empty string', () {
    final payload = Uint8List.fromList([0x00]);

    expect(decodeNdefTextPayload(payload), '');
  });

  test('malformed payload where language code length overflows the payload returns null', () {
    // statusByte says the language code is 10 bytes long, but only 2 bytes
    // follow the status byte — textStart (11) > payload.length (3).
    final payload = Uint8List.fromList([0x0A, 0x65, 0x6E]);

    expect(decodeNdefTextPayload(payload), isNull);
  });

  test('language code length exactly consuming the payload returns empty string', () {
    // textStart == payload.length is allowed (not an overflow) — sublist
    // on an empty range just yields no text.
    final payload = Uint8List.fromList([0x02, ...'en'.codeUnits]);

    expect(decodeNdefTextPayload(payload), '');
  });
}
