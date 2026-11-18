import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/crash/crash_reporter.dart';
import 'package:amiro_app/crash/crash_upload_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('record sends exceptionType and package frames to memory sink', () async {
    final sink = MemoryCrashSink();
    final reporter = CrashReporter(
      sinks: [sink],
      appVersion: '1.0.3+9',
      clock: () => DateTime.utc(2026, 10, 15, 9),
    );

    await reporter.record(StateError('avatar renderer'), StackTrace.empty, 'flutter');

    expect(sink.reports, hasLength(1));
    expect(sink.reports.single['message'], contains('avatar renderer'));
    expect(sink.reports.single['stack'], isA<String>());
    expect(sink.reports.single['source'], 'flutter');
    expect(sink.reports.single['appVersion'], '1.0.3+9');
    expect(sink.reports.single['at'], '2026-10-15T09:00:00.000Z');
  });

  test('a failing sink does not stop the next sink', () async {
    final sink = MemoryCrashSink();
    final reporter = CrashReporter(
      sinks: [_ThrowingSink(), sink],
    );

    await reporter.record('boom', StackTrace.empty, 'platform');

    expect(sink.reports, hasLength(1));
  });

  test('file sink appends one JSON line per crash', () async {
    final file = File(
      '${Directory.systemTemp.path}/amiro-crash-${DateTime.now().microsecondsSinceEpoch}.jsonl',
    );
    final reporter = CrashReporter(sinks: [FileCrashSink(file)]);

    await reporter.record('first', StackTrace.empty, 'flutter');
    await reporter.record('second', StackTrace.empty, 'flutter');

    final lines = await file.readAsLines();
    expect(lines, hasLength(2));
    expect(jsonDecode(lines[0])['message'], 'first');
    expect(jsonDecode(lines[1])['message'], 'second');
    await file.delete();
  });

  test('http sink posts JSON and accepts a 200', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final bodies = <String>[];
    final done = server.listen((request) async {
      bodies.add(await utf8.decoder.bind(request).join());
      request.response.statusCode = 200;
      await request.response.close();
    });

    final reporter = CrashReporter(
      sinks: [
        HttpCrashSink(
          Uri.parse('http://${server.address.host}:${server.port}/crash'),
          allowHttpForTest: true,
        ),
      ],
    );
    await reporter.record('controlled', StackTrace.empty, 'flutter');
    await done.cancel();
    await server.close();

    expect(bodies, hasLength(1));
    final decoded = jsonDecode(bodies.single) as Map<String, dynamic>;
    expect(decoded['exceptionType'], 'StateError');
    expect(decoded['message'], contains('controlled'));
    expect(decoded['frames'], isA<List>());
  });

  test('consent-gated http sink stays quiet until opt-in', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final bodies = <String>[];
    final sub = server.listen((request) async {
      bodies.add(await utf8.decoder.bind(request).join());
      request.response.statusCode = 200;
      await request.response.close();
    });
    final prefs = CrashUploadPreferences.inMemory();
    final reporter = CrashReporter(
      sinks: [
        ConsentGatedHttpCrashSink(
          prefs,
          HttpCrashSink(
            Uri.parse('http://${server.address.host}:${server.port}/crash'),
            allowHttpForTest: true,
          ),
        ),
      ],
    );

    await reporter.record('secret dev@test.com', StackTrace.empty, 'flutter');
    expect(bodies, isEmpty);

    await prefs.setEnabled(true);
    await reporter.record(
      'secret dev@test.com https://x.com/a?b=c /tmp/a.dart',
      StackTrace.current,
      'flutter',
    );
    await sub.cancel();
    await server.close();

    expect(bodies, hasLength(1));
    final decoded = jsonDecode(bodies.single) as Map<String, dynamic>;
    expect(decoded['message'], contains('[redacted-email]'));
    expect(decoded['message'], isNot(contains('dev@test.com')));
    expect(decoded['exceptionType'], isNotNull);
  });

  test('turning consent off stops the next upload', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var posts = 0;
    final sub = server.listen((request) async {
      posts += 1;
      await request.response.close();
    });
    final prefs = CrashUploadPreferences.inMemory(enabled: true);
    final reporter = CrashReporter(
      sinks: [
        ConsentGatedHttpCrashSink(
          prefs,
          HttpCrashSink(
            Uri.parse('http://${server.address.host}:${server.port}/crash'),
            allowHttpForTest: true,
          ),
        ),
      ],
    );

    await reporter.record('one', StackTrace.empty, 'platform');
    expect(posts, 1);
    await prefs.setEnabled(false);
    await reporter.record('two', StackTrace.empty, 'platform');
    await sub.cancel();
    await server.close();

    expect(posts, 1);
  });

  test('http sink requires https in production', () {
    expect(
      () => HttpCrashSink(Uri.parse('http://example.com/crash')),
      throwsArgumentError,
    );
  });

  test('file sink keeps the unscrubbed message', () async {
    final file = File(
      '${Directory.systemTemp.path}/amiro-crash-raw-${DateTime.now().microsecondsSinceEpoch}.jsonl',
    );
    final reporter = CrashReporter(sinks: [FileCrashSink(file)]);
    await reporter.record('dev@test.com', StackTrace.empty, 'flutter');
    final line = jsonDecode((await file.readAsLines()).single) as Map;
    expect(line['message'], contains('dev@test.com'));
    await file.delete();
  });

  test('installCrashReporting records a FlutterError', () async {
    final sink = MemoryCrashSink();
    final reporter = installCrashReporting(CrashReporter(sinks: [sink]));

    FlutterError.reportError(
      FlutterErrorDetails(exception: StateError('widget failed'), stack: StackTrace.empty),
    );
    await Future<void>.delayed(Duration.zero);

    expect(reporter.sinks, isNotEmpty);
    expect(sink.reports.single['source'], 'flutter');
    expect(sink.reports.single['message'], contains('widget failed'));
  });
}

class _ThrowingSink implements CrashSink {
  @override
  Future<void> send(Map<String, Object?> report) async {
    throw StateError('sink down');
  }
}
