import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/crash/crash_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _loadFixture() {
  final file = File(
    '${Directory.current.path}/../test/fixtures/crash_allowlist_golden.json',
  );
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  final fixture = _loadFixture();

  for (final entry in fixture['secretRedaction'] as List) {
    final map = entry as Map<String, dynamic>;
    test('secret redaction: ${map['id']}', () {
      expect(redactCrashSecrets(map['input'] as String), map['expected']);
    });
  }

  test('stack frame allowlist', () {
    final block = fixture['stackFilter'] as Map<String, dynamic>;
    expect(
      filterDartStackFrames(block['input'] as String),
      block['expected'],
    );
  });

  test('full report scrub matches golden', () {
    final block = fixture['fullReport'] as Map<String, dynamic>;
    final out = scrubCrashReport({
      'runtimeType': block['runtimeType'],
      'message': block['message'],
      'stack': block['stack'],
    });
    expect(out['message'], block['expectedMessage']);
    expect(out['stack'], block['expectedStack']);
  });
}