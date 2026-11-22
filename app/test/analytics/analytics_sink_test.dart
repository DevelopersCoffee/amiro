import 'package:amiro_app/analytics/analytics_ingest.dart';
import 'package:amiro_app/analytics/analytics_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HttpAnalyticsSink rejects non-https in release-safe constructor', () {
    expect(
      () => HttpAnalyticsSink(Uri.parse('http://example.com/analytics/t')),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('HttpAnalyticsSink allows http only when explicitly opted in', () {
    expect(
      HttpAnalyticsSink(
        Uri.parse('http://127.0.0.1/analytics/t'),
        allowInsecureHttp: true,
      ),
      isNotNull,
    );
  });

  test('analyticsSinksFromIngestUrl skips malformed define', () {
    final sinks = analyticsSinksFromIngestUrl(
      '%%%not-a-url%%%',
      releaseMode: true,
    );
    expect(sinks, isEmpty);
  });

  test('analyticsSinksFromIngestUrl skips non-https in release', () {
    final sinks = analyticsSinksFromIngestUrl(
      'http://example.com/analytics/t',
      releaseMode: true,
    );
    expect(sinks, isEmpty);
  });

  test('analyticsSinksFromIngestUrl accepts https', () {
    final sinks = analyticsSinksFromIngestUrl(
      'https://example.com/analytics/t',
      releaseMode: true,
    );
    expect(sinks, hasLength(1));
    expect(sinks.single, isA<HttpAnalyticsSink>());
  });
}