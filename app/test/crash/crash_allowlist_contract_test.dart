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

  test('final message cap is exactly 300 chars (not a constant stub)', () {
    final body = '!' * 10_000;
    final out = prepareCrashMessage('StateError', 'StateError: $body');
    expect(out.length, 300);
    expect(out, 'StateError: ${'!' * 288}');
    expect(out, startsWith('StateError:'));
  });

  test('long repeated characters trigger base64 redaction', () {
    final body = 'a' * 10_000;
    final out = prepareCrashMessage('StateError', 'StateError: $body');
    expect(out, 'StateError: [redacted-base64]');
  });

  test('invalid runtime types become Error in the composed line', () {
    final out = prepareCrashMessage('Rahul Verma', 'Rahul Verma: controlled');
    expect(out, 'Error: controlled');
    expect(out, isNot(contains('Rahul Verma')));
  });

  test('sanitizeCrashRuntimeType rejects human names and secrets', () {
    expect(sanitizeCrashRuntimeType('Rahul Verma'), 'Error');
    expect(sanitizeCrashRuntimeType('StateError'), 'StateError');
    expect(sanitizeCrashRuntimeType('List<int>'), 'List<int>');
    expect(sanitizeCrashRuntimeType('abcdef0123456789abcdef0123456789'), 'Error');
    expect(sanitizeCrashRuntimeType('Jane Doe, 9876543210'), 'Error');
  });

  test('sanitizeCrashRuntimeType caps length at 120 chars', () {
    final longType = 'A\$' * 100;
    final sanitized = sanitizeCrashRuntimeType(longType);
    expect(sanitized.length, 120);
    expect(sanitized, 'A\$' * 60);
  });

  test('sanitizeCrashRuntimeType allows whitespace only after comma inside angles', () {
    expect(sanitizeCrashRuntimeType('Map<String, int>'), 'Map<String, int>');
    expect(sanitizeCrashRuntimeType('Map<String, List<int>>'), 'Map<String, List<int>>');
    expect(sanitizeCrashRuntimeType('Foo <Bar>'), 'Error');
    expect(sanitizeCrashRuntimeType('Foo<Bar , Baz>'), 'Error');
    expect(sanitizeCrashRuntimeType('List<int?>'), 'Error');
    expect(sanitizeCrashRuntimeType('(int, String)'), 'Error');
    expect(sanitizeCrashRuntimeType('() => void'), 'Error');
  });
}
