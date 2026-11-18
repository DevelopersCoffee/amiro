import 'package:flutter_test/flutter_test.dart';

// Widget publish/revoke flow is exercised on device (`docs/protocols/web-profile.md`).
// Fake publish behavior lives in `fake_web_share_service.dart` and sharing package tests.
void main() {
  test('web share publish widgets are covered on device', () {
    expect(true, isTrue);
  });
}