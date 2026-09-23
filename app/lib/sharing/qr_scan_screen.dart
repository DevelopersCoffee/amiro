import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:sharing/sharing.dart';

import 'shared_profile_screen.dart';

/// Extracts a [SharedProfile] from a detected [BarcodeCapture], or `null`
/// if nothing usable was found — no barcode, no raw value, or a raw value
/// that isn't a valid `amiro://share` link. Pulled out of
/// [_QrScanScreenState._onDetect] so the decode step can be unit tested
/// without a real camera (see `test/sharing/qr_scan_screen_test.dart`);
/// `MobileScanner`'s camera view itself isn't meaningfully testable in a
/// widget test environment and is covered by the Task 9 device spike
/// instead.
SharedProfile? profileFromCapture(BarcodeCapture capture) {
  final raw = capture.barcodes.firstOrNull?.rawValue;
  if (raw == null) return null;
  return parseShareUri(raw);
}

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    final profile = profileFromCapture(capture);
    if (profile == null) return;

    _handled = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => SharedProfileScreen(profile: profile)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Amiro QR')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
