import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:sharing/sharing.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/sharing/qr_scan_screen.dart';
import 'package:amiro_app/sharing/scan_result.dart';

import '../discovery/support.dart';

// `MobileScanner`'s actual camera view isn't meaningfully testable in a
// widget test environment (no real camera) — see the Task 9 device spike
// for that. What *is* testable without a camera is the pure decode step:
// given a `BarcodeCapture` (a plain data object, constructible without any
// platform channel), does it resolve the scanned value to the right kind of
// card? That logic lives in `scanResultFromCapture` so it can be exercised
// here.
void main() {
  BarcodeCapture capture(String? raw) =>
      BarcodeCapture(barcodes: [Barcode(rawValue: raw)]);

  group('scanResultFromCapture', () {
    test('resolves an encounter link to an EncounterLink', () {
      final uri = encodeEncounterUri(payloadFor());

      final result = scanResultFromCapture(capture(uri));

      expect(result, isA<EncounterLink>());
      expect((result as EncounterLink).encounter.payload.displayName, 'Ada');
    });

    test('still resolves a legacy share link to a profile', () {
      const identity = Identity(
        id: 'id-1',
        displayName: 'Ada',
        username: 'ada',
      );

      final result = scanResultFromCapture(capture(buildShareUri(identity)));

      expect(result, isA<LegacyProfileLink>());
      final profile = (result as LegacyProfileLink).profile;
      expect(profile.displayName, 'Ada');
      expect(profile.username, 'ada');
    });

    test('returns null when no barcode was detected', () {
      expect(scanResultFromCapture(const BarcodeCapture(barcodes: [])), isNull);
    });

    test('returns null when the barcode has no rawValue', () {
      expect(scanResultFromCapture(capture(null)), isNull);
    });

    test('a foreign QR code resolves to NotAmiroLink, never a card', () {
      expect(
        scanResultFromCapture(capture('https://example.com')),
        isA<NotAmiroLink>(),
      );
    });
  });
}
