import 'package:amiro_app/crash/crash_upload_throttle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tryConsumeUploadQuota counts attempts not successes', () {
    final throttle = CrashUploadThrottle(maxPerSession: 2, maxPerDay: 100);
    expect(throttle.tryConsumeUploadQuota('a'), isTrue);
    expect(throttle.tryConsumeUploadQuota('b'), isTrue);
    expect(throttle.tryConsumeUploadQuota('c'), isFalse);
  });

  test('duplicate fingerprint does not consume another POST slot', () {
    final throttle = CrashUploadThrottle(maxPerSession: 5);
    expect(throttle.tryConsumeUploadQuota('same'), isTrue);
    expect(throttle.tryConsumeUploadQuota('same'), isFalse);
  });

  test('30 concurrent attempts cap at maxPerSession POSTs', () async {
    final throttle = CrashUploadThrottle(maxPerSession: 5, maxPerDay: 100);
  var allowed = 0;
  await Future.wait(
    List.generate(30, (i) async {
      if (throttle.tryConsumeUploadQuota('fp-$i')) {
        allowed += 1;
      }
    }),
  );
    expect(allowed, 5);
  });
}