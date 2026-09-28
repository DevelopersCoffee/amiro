import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

// DESIGN.md tokens, duplicated on purpose: this package must not depend on
// the app. Dark modules on a light ground keep the code reliably scannable.
const _cream = Color(0xFFEDE8DE);
const _ink = Color(0xFF161510);
const _brass = Color(0xFFC08A3E);

/// Renders [data] as a scannable QR code on a brass-framed cream card. Used
/// for the identity share URI — [data] is expected to already be the full
/// `amiro://share?d=...` URI, not raw profile data.
///
/// [size] is the code itself; the card adds padding around it.
Widget buildQrWidget(String data, {double size = 240}) {
  return Container(
    key: const Key('qrCard'),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _cream,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _brass, width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 16),
      ],
    ),
    child: SizedBox(
      width: size,
      height: size,
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        backgroundColor: _cream,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: _ink),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: _ink,
        ),
      ),
    ),
  );
}
