import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'scan_navigation.dart';
import 'scan_result.dart';

/// Resolves a detected [BarcodeCapture] to what it carries, or `null` if no
/// barcode with a raw value was found. Pulled out of
/// [_QrScanScreenState._onDetect] so the decode step can be unit tested
/// without a real camera (see `test/sharing/qr_scan_screen_test.dart`);
/// `MobileScanner`'s camera view itself isn't meaningfully testable in a
/// widget test environment and is covered by the Task 9 device spike
/// instead.
ScanResult? scanResultFromCapture(BarcodeCapture capture) {
  final raw = capture.barcodes.firstOrNull?.rawValue;
  if (raw == null) return null;
  return resolveScannedText(raw);
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

    final result = scanResultFromCapture(capture);
    final screen = result == null ? null : screenForScan(result);
    if (screen == null) return; // keep scanning until something usable shows up

    _handled = true;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Amiro QR')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
