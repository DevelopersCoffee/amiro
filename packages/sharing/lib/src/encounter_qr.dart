import 'dart:convert';

import 'amiro_sharing_payload.dart';
import 'contact_card.dart';

const _kScheme = 'amiro';
const _kHost = 'encounter';

/// Longest encounter URI that will be put in, or accepted from, a QR code.
/// Above this a QR code needs a dense version that cameras struggle to read.
const maxEncounterUriLength = 2000;

/// What a scanned encounter QR code carries.
class EncounterQr {
  final AmiroSharingPayload payload;

  /// Null when the sender shared no contact details, or when the card they
  /// sent was malformed (it is decoration, never a reason to reject the
  /// identity).
  final ContactCard? contact;

  const EncounterQr(this.payload, this.contact);
}

/// The text for an encounter QR code (or, later, an NFC record):
/// `amiro://encounter?d=<payload>[&c=<contact card>]`, both base64url
/// without padding. Throws [SharingPayloadException] for an invalid payload
/// or a result over [maxEncounterUriLength]; it never silently drops the
/// contact card to make things fit.
String encodeEncounterUri(AmiroSharingPayload payload, {ContactCard? contact}) {
  final buffer =
      StringBuffer('$_kScheme://$_kHost?d=${_encode(payload.encode())}');
  if (contact != null && !contact.isEmpty) {
    buffer.write('&c=${_encode(jsonEncode(contact.toJson()))}');
  }

  final uri = buffer.toString();
  if (uri.length > maxEncounterUriLength) {
    throw SharingPayloadException(
      PayloadErrorKind.tooLarge,
      'encounter link is ${uri.length} characters, over the $maxEncounterUriLength limit for a QR code',
    );
  }
  return uri;
}

/// Parses scanned text. Throws [SharingPayloadException] unless it is an
/// `amiro://encounter` link carrying a valid payload, so only validated data
/// can reach discovery. Legacy `amiro://share` links are not encounters.
EncounterQr decodeEncounterUri(String uri) {
  if (uri.length > maxEncounterUriLength) {
    throw const SharingPayloadException(
        PayloadErrorKind.tooLarge, 'encounter link is too long');
  }

  final Uri parsed;
  try {
    parsed = Uri.parse(uri);
  } on FormatException {
    throw const SharingPayloadException(
        PayloadErrorKind.malformed, 'not a valid link');
  }
  if (parsed.scheme != _kScheme || parsed.host != _kHost) {
    throw const SharingPayloadException(
        PayloadErrorKind.malformed, 'not an amiro://encounter link');
  }

  final encodedPayload = parsed.queryParameters['d'];
  if (encodedPayload == null) {
    throw const SharingPayloadException(
        PayloadErrorKind.malformed, 'the link has no payload');
  }

  final String payloadJson;
  try {
    payloadJson = _decode(encodedPayload);
  } on FormatException {
    throw const SharingPayloadException(
        PayloadErrorKind.malformed, 'the payload is not valid base64');
  }

  return EncounterQr(AmiroSharingPayload.decode(payloadJson),
      _contactFrom(parsed.queryParameters['c']));
}

ContactCard? _contactFrom(String? encoded) {
  if (encoded == null) return null;
  try {
    return ContactCard.fromJson(jsonDecode(_decode(encoded)));
  } on FormatException {
    return null;
  }
}

String _encode(String json) =>
    base64Url.encode(utf8.encode(json)).replaceAll('=', '');

String _decode(String encoded) =>
    utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
