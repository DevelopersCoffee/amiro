import 'package:amiro_app/crash/crash_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('64 KB adversarial scrub finishes within 50ms', () {
    final payload = '!' * 64 * 1024;
    final sw = Stopwatch()..start();
    final out = redactCrashSecrets(payload);
    sw.stop();
    expect(out.length, payload.length);
    expect(sw.elapsedMilliseconds, lessThan(50));
  });
}