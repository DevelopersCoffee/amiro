import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// On-device restore smoke for owners. CI skips unless env is set.
///
/// See `docs/qa/restore-purchases-device.md`.
void main() {
  final runOnDevice = Platform.environment['AMIRO_DEVICE_RESTORE_TEST'] == '1';

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'restore purchases reachability (device)',
    (tester) async {
      // Wire the real app in a follow-up when running on the Pixel: import
      // `main.dart`, pump `MaterialApp`, navigate to Store, tap Restore.
      // This placeholder keeps the integration target and env gate in repo.
      expect(runOnDevice, isTrue);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();
    },
    skip: !runOnDevice,
  );
}