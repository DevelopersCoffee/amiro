// PLACEHOLDER — not an automated restore proof. Real device steps:
// `docs/qa/restore-purchases-device.md` and
//   AMIRO_DEVICE_RESTORE_TEST=1 flutter test integration_test -d <device>
//
// This file exists only so `integration_test` is wired in pubspec; it does not
// pump the Amiro app or call RevenueCat.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('placeholder documents manual restore path', () {
    expect(
      true,
      isTrue,
      reason: 'See docs/qa/restore-purchases-device.md for Pixel restore proof.',
    );
  });
}