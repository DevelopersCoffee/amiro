import 'package:amiro_app/crash/crash_scrub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scrubCrashText redacts email, phone, query URLs, and paths', () {
    const raw = 'contact dev@test.com or +1 (555) 123-4567 '
        'at https://example.com/path?q=secret '
        'file:///data/user/0/com.amiro/app/crash '
        'C:\\Users\\alice\\secret.txt '
        'stack /home/alice/proj/lib/main.dart:42';
    final scrubbed = scrubCrashText(raw);

    expect(scrubbed, isNot(contains('dev@test.com')));
    expect(scrubbed, contains('[redacted-email]'));
    expect(scrubbed, isNot(contains('555')));
    expect(scrubbed, contains('[redacted-phone]'));
    expect(scrubbed, isNot(contains('q=secret')));
    expect(scrubbed, contains('[redacted-url]'));
    expect(scrubbed, isNot(contains('/home/alice')));
    expect(scrubbed, contains('[redacted-path]'));
    expect(scrubbed, isNot(contains('C:\\Users')));
  });

  test('scrubCrashReport only rewrites message and stack', () {
    final out = scrubCrashReport({
      'message': 'fail dev@test.com',
      'stack': 'at /tmp/a.dart:1',
      'source': 'flutter',
    });
    expect(out['source'], 'flutter');
    expect(out['message'], contains('[redacted-email]'));
    expect(out['stack'], contains('[redacted-path]'));
  });
}