import 'package:amiro_app/crash/crash_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildCrashUploadPayload keeps only package frames', () {
    final stack = StackTrace.fromString('''
#0      main (package:amiro_app/main.dart:10:5)
#1      _test (file:///tmp/a.dart:1:1)
''');
    final payload = buildCrashUploadPayload(
      error: StateError('fail Bearer secret eyJhbGci.test.test'),
      stack: stack,
      source: 'flutter',
      appVersion: '1.0.6',
      platform: 'android',
    );
    expect(payload['exceptionType'], 'StateError');
    expect(payload['message'], isA<String>());
    expect((payload['message'] as String), isNot(contains('eyJ')));
    final frames = payload['frames']! as List;
    expect(frames, hasLength(1));
    expect(frames.first, contains('package:amiro_app'));
  });
}