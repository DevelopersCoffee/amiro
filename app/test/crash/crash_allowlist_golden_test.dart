import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/crash/crash_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> golden;

  setUpAll(() {
    final raw = File(
      '${Directory.current.path}/../test/fixtures/crash_allowlist_golden.json',
    ).readAsStringSync();
    golden = jsonDecode(raw) as Map<String, dynamic>;
  });

  for (final entry in golden['secretRedaction'] as List) {
    final map = entry as Map<String, dynamic>;
    test('secret redaction: ${map['id']}', () {
      expect(redactCrashSecrets(map['input'] as String), map['expected']);
    });
  }

  test('stack frame allowlist', () {
    final block = golden['stackFilter'] as Map<String, dynamic>;
    expect(
      filterDartStackFrames(block['input'] as String),
      block['expected'],
    );
  });

  test('full report scrub matches golden', () {
    final block = golden['fullReport'] as Map<String, dynamic>;
    final out = scrubCrashReport({
      'runtimeType': block['runtimeType'],
      'message': block['message'],
      'stack': block['stack'],
    });
    expect(out['message'], block['expectedMessage']);
    expect(out['stack'], block['expectedStack']);
  });
}