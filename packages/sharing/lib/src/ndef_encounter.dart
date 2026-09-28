import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'amiro_sharing_payload.dart';
import 'encounter_qr.dart';

/// NDEF type-name-format for well-known records (text `T`, URI `U`).
const ndefTnfWellKnown = 0x01;

/// Largest NDEF record payload considered, in bytes. Encounter links are
/// capped well below this; anything bigger is not an Amiro card.
const maxNdefRecordBytes = 4096;

const _kEncounterPrefix = 'amiro://encounter';

/// One NDEF record as raw bytes, independent of any NFC plugin. The `nfc`
/// package converts its platform records into this; nothing here knows how
/// they were read.
class NdefRecordData {
  final int tnf;
  final List<int> type;
  final List<int> payload;

  const NdefRecordData(
      {required this.tnf, required this.type, required this.payload});
}

/// The payload of an NDEF well-known text record: status byte (UTF-8, language
/// code length), the language code, then UTF-8 text. What an emulated tag
/// should carry for [text].
Uint8List encodeNdefTextPayload(String text, {String languageCode = 'en'}) {
  assert(languageCode.length <= 0x3F,
      'language code too long for the status byte');
  return Uint8List.fromList(
      [languageCode.length, ...languageCode.codeUnits, ...utf8.encode(text)]);
}

/// The text a well-known text (`T`) or URI (`U`) record carries, or null if
/// it is neither, is oversized, or is malformed (invalid UTF-8/UTF-16, a
/// language code longer than the payload). Never throws on bad bytes.
///
/// URI records with an abbreviation prefix (`https://`, `tel:` ...) are
/// skipped: an Amiro link is always written unabbreviated.
String? ndefRecordText(NdefRecordData record) {
  if (record.tnf != ndefTnfWellKnown || record.type.length != 1) return null;
  final payload = record.payload;
  if (payload.isEmpty || payload.length > maxNdefRecordBytes) return null;

  try {
    switch (record.type[0]) {
      case 0x54: // 'T'
        final status = payload[0];
        final textStart = 1 + (status & 0x3F);
        if (textStart > payload.length) return null;
        final body = payload.sublist(textStart);
        return status & 0x80 != 0 ? _utf16(body) : utf8.decode(body);
      case 0x55: // 'U'
        return payload[0] == 0 ? utf8.decode(payload.sublist(1)) : null;
      default:
        return null;
    }
  } on FormatException {
    return null;
  }
}

String _utf16(List<int> bytes) {
  var start = 0;
  var littleEndian = false;
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    littleEndian = true;
    start = 2;
  } else if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    start = 2;
  }
  if ((bytes.length - start).isOdd) {
    throw const FormatException('odd number of UTF-16 bytes');
  }

  return String.fromCharCodes([
    for (var i = start; i < bytes.length; i += 2)
      littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1],
  ]);
}

/// The first record that carries an `amiro://encounter` link, skipping
/// anything else on the tag (an Android Application Record, say). The first
/// such record decides: a bad one is not papered over by a later good one.
/// Throws [SharingPayloadException] (malformed) if there is none.
String encounterTextFromNdef(List<NdefRecordData> records) {
  for (final record in records) {
    final text = ndefRecordText(record);
    if (text != null && text.startsWith(_kEncounterPrefix)) return text;
  }
  throw const SharingPayloadException(
      PayloadErrorKind.malformed, 'no Amiro encounter record on the tag');
}

/// The first record on the tag whose text is any `amiro://` link, encounter
/// or legacy share, or null. For callers that hand the text on to a resolver
/// that understands both formats.
String? amiroLinkTextFromNdef(List<NdefRecordData> records) {
  for (final record in records) {
    final text = ndefRecordText(record);
    if (text != null && text.startsWith('amiro://')) return text;
  }
  return null;
}

/// NFC boundary: tag records in, validated encounter out. Throws
/// [SharingPayloadException] for anything that isn't a valid card.
EncounterQr decodeEncounterFromNdef(List<NdefRecordData> records) {
  return decodeEncounterUri(encounterTextFromNdef(records));
}

/// What a tag read turned into. Downstream code sees only these two: never
/// raw bytes, partial data or an exception.
sealed class NfcRead {
  const NfcRead();
}

final class NfcEncounterRead extends NfcRead {
  final EncounterQr encounter;

  const NfcEncounterRead(this.encounter);
}

final class NfcReadRejected extends NfcRead {
  final SharingPayloadException error;

  const NfcReadRejected(this.error);
}

/// Adapts a stream of raw tag reads into [NfcRead]s.
///
/// - Every read is validated; invalid ones become [NfcReadRejected].
/// - A hardware dropout (an error on [source]) becomes a rejection and the
///   stream keeps going, so a flaky connection can't crash or wedge callers.
/// - A tag held against the phone reads many times; an identical read
///   inside [duplicateWindow] of the previous one is dropped. Continuous
///   contact keeps refreshing the window, so it is reported once.
Stream<NfcRead> ingestNfcReads(
  Stream<List<NdefRecordData>> source, {
  DateTime Function()? clock,
  Duration duplicateWindow = const Duration(seconds: 3),
}) {
  final now = clock ?? DateTime.now;
  final lastSeen = <String, DateTime>{};

  void emit(EventSink<NfcRead> sink, String key, NfcRead read) {
    final at = now();
    lastSeen
        .removeWhere((_, seenAt) => at.difference(seenAt) >= duplicateWindow);
    final previous = lastSeen[key];
    lastSeen[key] = at;
    if (previous == null) sink.add(read);
  }

  return source.transform(
    StreamTransformer<List<NdefRecordData>, NfcRead>.fromHandlers(
      handleData: (records, sink) {
        String? key;
        try {
          final text = encounterTextFromNdef(records);
          key = 'link:$text';
          emit(sink, key, NfcEncounterRead(decodeEncounterUri(text)));
        } on SharingPayloadException catch (e) {
          emit(sink, key ?? 'rejected:${e.message}', NfcReadRejected(e));
        } catch (_) {
          emit(
            sink,
            'rejected:unreadable',
            const NfcReadRejected(SharingPayloadException(
                PayloadErrorKind.malformed, 'the tag could not be read')),
          );
        }
      },
      handleError: (error, stackTrace, sink) {
        emit(
          sink,
          'dropout',
          const NfcReadRejected(SharingPayloadException(
              PayloadErrorKind.malformed, 'the NFC read was interrupted')),
        );
      },
    ),
  );
}
