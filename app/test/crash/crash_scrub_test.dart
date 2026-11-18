import 'package:amiro_app/crash/crash_scrub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scrubCrashMessage redacts jwt bearer email and fragments quickly', () {
    final input =
        'Bearer abc eyJhbGciOiJIUzI1NiJ9.a.b dev@test.com '
        'https://x.com/a?secret=1#frag ${'x' * 80000}';
    final stopwatch = Stopwatch()..start();
    final out = scrubCrashMessage(input);
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(200));
    expect(out, isNot(contains('dev@test.com')));
    expect(out, contains('[redacted-email]'));
    expect(out, isNot(contains('eyJhbGci')));
    expect(out.length, lessThanOrEqualTo(crashMessageMax));
  });
}