import 'package:amiro_app/crash/crash_allowlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package frames survive; path-only lines drop', () {
    const stack = '#0      x (package:amiro_app/main.dart:1:9)\n/home/a.dart:1\n';
    expect(
      filterDartStackFrames(stack),
      '#0      x (package:amiro_app/main.dart:1:9)',
    );
  });
}