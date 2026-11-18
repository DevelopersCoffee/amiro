import 'dart:typed_data';

import 'package:amiro_app/sharing/web_share_avatar_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('stripAvatarMetadata re-encodes to clean png', () {
    final image = img.Image(width: 8, height: 8);
    img.fill(image, color: img.ColorRgb8(1, 2, 3));
    final original = Uint8List.fromList(img.encodePng(image));
    final stripped = stripAvatarMetadata(original);
    expect(stripped.sublist(0, 4), equals([137, 80, 78, 71]));
    expect(img.decodeImage(stripped), isNotNull);
    expect(stripped.length, lessThanOrEqualTo(original.length + 256));
  });

  test('fallback avatar encodes valid png', () {
    final bytes = buildFallbackWebShareAvatar('Uday');
    expect(bytes.sublist(0, 4), equals([137, 80, 78, 71]));
    expect(img.decodeImage(bytes), isNotNull);
  });
}