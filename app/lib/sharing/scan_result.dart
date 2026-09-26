import 'package:sharing/sharing.dart';

/// What scanned or received text turned out to be. Every receive path (QR,
/// NFC, deep link) resolves through [resolveScannedText] so they behave
/// identically.
sealed class ScanResult {
  const ScanResult();
}

/// A valid `amiro://encounter` card: goes to the comparison screen and can
/// be saved to the passport.
final class EncounterLink extends ScanResult {
  final EncounterQr encounter;

  const EncounterLink(this.encounter);
}

/// A legacy `amiro://share` link from an older build: shown as a profile
/// only. It carries no collection, so it can't become a passport entry.
final class LegacyProfileLink extends ScanResult {
  final SharedProfile profile;

  const LegacyProfileLink(this.profile);
}

/// An `amiro://` link that isn't usable (corrupt, too new, too large).
final class InvalidAmiroLink extends ScanResult {
  final SharingPayloadException error;

  const InvalidAmiroLink(this.error);
}

/// Not an Amiro link at all.
final class NotAmiroLink extends ScanResult {
  const NotAmiroLink();
}

ScanResult resolveScannedText(String raw) {
  if (!raw.startsWith('amiro://')) return const NotAmiroLink();

  if (raw.startsWith('amiro://encounter')) {
    try {
      return EncounterLink(decodeEncounterUri(raw));
    } on SharingPayloadException catch (e) {
      return InvalidAmiroLink(e);
    }
  }

  final profile = parseShareUri(raw);
  if (profile != null) return LegacyProfileLink(profile);
  return const InvalidAmiroLink(
    SharingPayloadException(
      PayloadErrorKind.malformed,
      'not a recognised Amiro link',
    ),
  );
}
