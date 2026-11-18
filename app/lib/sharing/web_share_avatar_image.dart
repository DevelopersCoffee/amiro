import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Re-encodes [input] as PNG with metadata stripped (no EXIF / text chunks).
Uint8List stripAvatarMetadata(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    throw const FormatException('avatar image could not be decoded');
  }
  return Uint8List.fromList(img.encodePng(decoded));
}

/// Branded fallback avatar for web publish when no raster capture exists yet.
Uint8List buildFallbackWebShareAvatar(String displayName) {
  const size = 512;
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(22, 21, 16));
  final border = img.ColorRgb8(192, 138, 62);
  for (var x = 48; x < size - 48; x++) {
    image.setPixel(x, 48, border);
    image.setPixel(x, size - 49, border);
  }
  for (var y = 48; y < size - 48; y++) {
    image.setPixel(48, y, border);
    image.setPixel(size - 49, y, border);
  }

  final trimmed = displayName.trim();
  final label = trimmed.isEmpty ? 'A' : trimmed[0].toUpperCase();
  img.drawString(
    image,
    label,
    font: img.arial24,
    x: size ~/ 2 - 12,
    y: size ~/ 2 - 14,
    color: img.ColorRgb8(237, 232, 222),
  );

  return stripAvatarMetadata(Uint8List.fromList(img.encodePng(image)));
}