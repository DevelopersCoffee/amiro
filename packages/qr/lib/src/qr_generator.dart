import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders [data] as a scannable QR code. Used for the identity share URI —
/// [data] is expected to already be the full `amiro://share?d=...` URI, not
/// raw profile data.
Widget buildQrWidget(String data, {double size = 240}) {
  return SizedBox(
    width: size,
    height: size,
    child: QrImageView(
      data: data,
      version: QrVersions.auto,
      backgroundColor: const Color(0xFFFFFFFF),
    ),
  );
}
