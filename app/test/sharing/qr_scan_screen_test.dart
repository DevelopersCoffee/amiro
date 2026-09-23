import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:sharing/sharing.dart';
import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/sharing/qr_scan_screen.dart';

// `MobileScanner`'s actual camera view isn't meaningfully testable in a
// widget test environment (no real camera) — see the Task 9 device spike
// for that. What *is* testable without a camera is the pure decode step:
// given a `BarcodeCapture` (a plain data object, constructible without any
// platform channel), does it correctly extract and parse the scanned
// value into a `SharedProfile`? That logic is extracted to
// `profileFromCapture` specifically so it can be exercised here.
void main() {
  group('profileFromCapture', () {
    test('parses a valid amiro share link into a SharedProfile', () {
      const identity = Identity(id: 'id-1', displayName: 'Ada', username: 'ada');
      final uri = buildShareUri(identity);
      final capture = BarcodeCapture(barcodes: [Barcode(rawValue: uri)]);

      final profile = profileFromCapture(capture);

      expect(profile, isNotNull);
      expect(profile!.displayName, 'Ada');
      expect(profile.username, 'ada');
    });

    test('returns null when no barcode was detected', () {
      const capture = BarcodeCapture(barcodes: []);

      expect(profileFromCapture(capture), isNull);
    });

    test('returns null when the barcode value has no rawValue', () {
      final capture = BarcodeCapture(barcodes: [const Barcode(rawValue: null)]);

      expect(profileFromCapture(capture), isNull);
    });

    test('returns null when the scanned string is not a valid amiro share link', () {
      final capture = BarcodeCapture(barcodes: [const Barcode(rawValue: 'https://example.com')]);

      expect(profileFromCapture(capture), isNull);
    });
  });
}
