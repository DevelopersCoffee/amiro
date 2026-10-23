import 'dart:convert';
import 'dart:typed_data';

/// NDEF type-name-format for well-known records (text `T`, URI `U`).
const ndefTnfWellKnown = 0x01;

/// Largest NDEF record payload considered, in bytes. Encounter links are
/// capped well below this; anything bigger is not an Amiro card.
const maxNdefRecordBytes = 4096;

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
