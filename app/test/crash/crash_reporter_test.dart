import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/crash/crash_reporter.dart';
import 'package:amiro_app/crash/crash_upload_preferences.dart';
import 'package:amiro_app/crash/crash_upload_throttle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

HttpCrashSink _loopbackSink(Uri uri) =>
    HttpCrashSink(uri, allowInsecureHttp: true);

ConsentGatedHttpCrashSink _gatedSink({
  required CrashUploadPreferences prefs,
  required HttpCrashSink inner,
  CrashUploadThrottle? throttle,
}) {
  return ConsentGatedHttpCrashSink(
    prefs,
    throttle ?? CrashUploadThrottle(),
    inner,
  );
}

void main() {
  test('record sends the message, stack, version and source', () async {
    final sink = MemoryCrashSink();
    final reporter = CrashReporter(
      sinks: [sink],
      appVersion: '1.0.3+9',
      clock: () => DateTime.utc(2026, 10, 15, 9),
    );

    await reporter.record(StateError('avatar renderer'), StackTrace.empty, 'flutter');

    expect(sink.reports, hasLength(1));
    expect(sink.reports.single['message'], contains('avatar renderer'));
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
        _loopbackSink(
          Uri.parse('http://${server.address.host}:${server.port}/crash'),
        ),
      ],
    );
    await reporter.record('controlled', StackTrace.empty, 'flutter');
    await done.cancel();
    await server.close();

    expect(bodies, hasLength(1));
    expect(jsonDecode(bodies.single)['message'], 'controlled');
  });

  test('http sink rejects non-https without allowInsecureHttp', () {
    expect(
      () => HttpCrashSink(Uri.parse('http://example.com/crash')),
      throwsArgumentError,
    );
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
        _gatedSink(
          prefs: prefs,
          inner: _loopbackSink(
            Uri.parse('http://${server.address.host}:${server.port}/crash'),
          ),
        ),
      ],
    );

    await reporter.record(
      StateError('eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.sig'),
      StackTrace.empty,
      'flutter',
    );
    expect(bodies, isEmpty);

    await prefs.setEnabled(true);
    await reporter.record(
      StateError('eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.sig'),
      StackTrace.empty,
      'flutter',
    );
    await sub.cancel();
    await server.close();

    expect(bodies, hasLength(1));
    final decoded = jsonDecode(bodies.single) as Map<String, dynamic>;
    expect(decoded['message'], contains('[redacted-jwt]'));
    expect(decoded['message'], isNot(contains('eyJzdWIiOiIxIn0')));
  });

  test('a crash recorded before opt-in is not uploaded after opt-in', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var posts = 0;
    final sub = server.listen((request) async {
      posts += 1;
      await request.response.close();
    });
    final prefs = CrashUploadPreferences.inMemory();
    final reporter = CrashReporter(
      sinks: [
        _gatedSink(
          prefs: prefs,
          inner: _loopbackSink(
            Uri.parse('http://${server.address.host}:${server.port}/crash'),
          ),
        ),
      ],
    );

    await reporter.record(StateError('before'), StackTrace.empty, 'flutter');
    expect(posts, 0);
    await prefs.setEnabled(true);
    await reporter.record(StateError('after'), StackTrace.empty, 'flutter');
    await sub.cancel();
    await server.close();

    expect(posts, 1);
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
        _gatedSink(
          prefs: prefs,
          inner: _loopbackSink(
            Uri.parse('http://${server.address.host}:${server.port}/crash'),
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

  test('throttle caps concurrent crash uploads by attempt quota', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var posts = 0;
    final sub = server.listen((request) async {
      posts += 1;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await request.response.close();
    });
    final prefs = CrashUploadPreferences.inMemory(enabled: true);
    final throttle = CrashUploadThrottle(maxPerSession: 5, maxPerDay: 100);
    final reporter = CrashReporter(
      sinks: [
        _gatedSink(
          prefs: prefs,
          throttle: throttle,
          inner: _loopbackSink(
            Uri.parse('http://${server.address.host}:${server.port}/crash'),
          ),
        ),
      ],
    );

    await Future.wait(
      List.generate(
        30,
        (i) => reporter.record(StateError('e$i'), StackTrace.empty, 'flutter'),
      ),
    );
    await sub.cancel();
    await server.close();

    expect(posts, 5);
  });

  test('throttle dedupes identical fingerprint', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var posts = 0;
    final sub = server.listen((request) async {
      posts += 1;
      await request.response.close();
    });
    final prefs = CrashUploadPreferences.inMemory(enabled: true);
    final reporter = CrashReporter(
      sinks: [
        _gatedSink(
          prefs: prefs,
          inner: _loopbackSink(
            Uri.parse('http://${server.address.host}:${server.port}/crash'),
          ),
        ),
      ],
    );

    await reporter.record(StateError('dup'), StackTrace.empty, 'flutter');
    await reporter.record(StateError('dup'), StackTrace.empty, 'flutter');
    await sub.cancel();
    await server.close();

    expect(posts, 1);
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