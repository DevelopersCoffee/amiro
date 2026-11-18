import 'package:amiro_app/crash/crash_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pre-truncate runs before redaction (secrets past 2048 are dropped)', () {
  final jwt =
      'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.sig';
    final padding = 'x' * (crashMessagePreTruncate + 50);
    final raw = 'StateError: $padding$jwt';
    final out = prepareCrashMessage('StateError', raw);
    expect(out, isNot(contains('[redacted-jwt]')));
    expect(out.length, lessThanOrEqualTo(crashMessageFinalMax));
    expect(out.length, greaterThan(20));
  });

  test('final message cap is 300 chars (not a constant stub)', () {
    final body = 'a' * 10_000;
    final out = prepareCrashMessage('StateError', 'StateError: $body');
    expect(out.length, lessThanOrEqualTo(crashMessageFinalMax));
    expect(out, contains('aaaaaaaaaa'));
    expect(out, startsWith('StateError:'));
  });

  test('invalid runtime types become Error in the composed line', () {
    final out = prepareCrashMessage('Rahul Verma', 'Rahul Verma: controlled');
    expect(out, 'Error: controlled');
    expect(out, isNot(contains('Rahul Verma')));
  });

  test('sanitizeCrashRuntimeType rejects human names before redaction', () {
    expect(sanitizeCrashRuntimeType('Rahul Verma'), 'Error');
    expect(sanitizeCrashRuntimeType('StateError'), 'StateError');
    expect(sanitizeCrashRuntimeType('List<int>'), 'List<int>');
  });
}