import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/crash/crash_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

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
        HttpCrashSink(Uri.parse('http://${server.address.host}:${server.port}/crash')),
      ],
    );
    await reporter.record('controlled', StackTrace.empty, 'flutter');
    await done.cancel();
    await server.close();

    expect(bodies, hasLength(1));
    expect(jsonDecode(bodies.single)['message'], 'controlled');
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
