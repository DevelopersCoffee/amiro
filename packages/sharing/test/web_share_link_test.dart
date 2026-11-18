import 'dart:math';

import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

void main() {
  test('token has at least 128 bits and URL has no PII', () {
    final token = generateWebShareToken(Random(1));
    expect(token.length, greaterThanOrEqualTo(16));
    final uri = buildWebShareUri(token);
    expect(webShareUriContainsNoPii(uri), isTrue);
    expect(uri, contains('https://id.amiro.app/u/'));
    expect(uri.contains('#'), isFalse);
    expect(uri.contains('?'), isFalse);
  });

  test('parseWebShareToken rejects fragment and query payloads', () {
    const token = 'abcdefghijklmnopqrstuv';
    expect(
      parseWebShareToken('https://id.amiro.app/u/$token'),
      token,
    );
    expect(parseWebShareToken('https://id.amiro.app/u/$token#email=a@b.c'), isNull);
    expect(parseWebShareToken('https://id.amiro.app/u/$token?d=secret'), isNull);
    expect(parseWebShareToken('amiro://encounter?d=abc'), isNull);
  });

  test('isWebShareUri allows only https host u path', () {
    final ok = Uri.parse('https://id.amiro.app/u/${'x' * 20}');
    expect(isWebShareUri(ok), isTrue);
    expect(isWebShareUri(Uri.parse('http://id.amiro.app/u/${'x' * 20}')), isFalse);
  });
}