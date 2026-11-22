import 'dart:convert';
import 'dart:math';

import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

/// Mirrors Postgres `rtrim(translate(encode(bytes,'base64'), '+/', '-_'), '=')`.
String postgresStyleWebShareToken(List<int> bytes) {
  final encoded = base64.encode(bytes);
  final translated = encoded.replaceAllMapped(
    RegExp(r'[+/]'),
    (match) => match.group(0) == '+' ? '-' : '_',
  );
  return translated.replaceFirst(RegExp(r'=+$'), '');
}

final _workerTokenPattern = RegExp(r'^[A-Za-z0-9_-]{22,64}$');

void main() {
  test('token has at least 128 bits and URL has no PII', () {
    final token = generateWebShareToken(Random(1));
    expect(token.length, greaterThanOrEqualTo(22));
    final uri = buildWebShareUri(token);
    expect(webShareUriContainsNoPii(uri), isTrue);
    expect(uri, contains('https://id.amiro.app/u/'));
    expect(uri.contains('#'), isFalse);
    expect(uri.contains('?'), isFalse);
  });

  test('parseWebShareToken rejects short tokens and fragments', () {
    const token = 'abcdefghijklmnopqrstuvwxy';
    expect(parseWebShareToken('https://id.amiro.app/u/$token'), token);
    expect(parseWebShareToken('https://id.amiro.app/u/tooshorttoken'), isNull);
    expect(parseWebShareToken('https://id.amiro.app/u/$token#email=a@b.c'), isNull);
    expect(parseWebShareToken('https://id.amiro.app/u/$token?d=secret'), isNull);
  });

  test('isWebShareUri allows only https host u path', () {
    final ok = Uri.parse('https://id.amiro.app/u/${'x' * 22}');
    expect(isWebShareUri(ok), isTrue);
    expect(isWebShareUri(Uri.parse('http://id.amiro.app/u/${'x' * 22}')), isFalse);
  });

  test('postgres and client tokens match Worker path regex', () {
    final postgresSamples = <String>[
      for (var i = 0; i < 8; i++)
        postgresStyleWebShareToken(List<int>.generate(16, (j) => (i * 17 + j * 31) % 256)),
    ];
    for (final token in [...postgresSamples, generateWebShareToken(Random(99))]) {
      expect(_workerTokenPattern.hasMatch(token), isTrue, reason: token);
      expect(isWebShareUri(Uri.parse(buildWebShareUri(token))), isTrue);
    }
    expect(_workerTokenPattern.hasMatch('has+plus'), isFalse);
    expect(_workerTokenPattern.hasMatch('has/slash'), isFalse);
    expect(_workerTokenPattern.hasMatch('padding=='), isFalse);
  });
}