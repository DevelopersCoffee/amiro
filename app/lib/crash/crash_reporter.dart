import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'crash_allowlist.dart';
import 'crash_upload_preferences.dart';
import 'crash_upload_throttle.dart';

/// Where a captured crash is delivered. Implementations must not throw;
/// [CrashReporter] already swallows sink failures so a broken reporter
/// cannot take down the error path.
abstract interface class CrashSink {
  Future<void> send(Map<String, Object?> report);
}

/// Remembers reports in memory. Used by tests and as a stand-in when no
/// remote ingest URL is configured.
class MemoryCrashSink implements CrashSink {
  final List<Map<String, Object?>> reports = [];

  @override
  Future<void> send(Map<String, Object?> report) async {
    reports.add(report);
  }
}

/// Appends one JSON object per line. Survives a process restart, so a
/// crash is still on the device if the network post never happened.
class FileCrashSink implements CrashSink {
  FileCrashSink(this.file);

  final File file;

  @override
  Future<void> send(Map<String, Object?> report) async {
    await file.parent.create(recursive: true);
    await file.writeAsString('${jsonEncode(report)}\n', mode: FileMode.append);
  }
}

/// POSTs the report as JSON. The URL is a build-time define
/// (`--dart-define=AMIRO_CRASH_INGEST_URL=...`); it is not stored in git.
class HttpCrashSink implements CrashSink {
  HttpCrashSink(
    this.uri, {
    HttpClient? client,
    this.allowInsecureHttp = false,
  }) : _client = client ?? HttpClient() {
    if (!allowInsecureHttp && uri.scheme != 'https') {
      throw ArgumentError('Crash ingest URL must use https');
    }
    _client.connectionTimeout = const Duration(seconds: 10);
  }

  final Uri uri;
  final bool allowInsecureHttp;
  final HttpClient _client;

  static const Duration _uploadTimeout = Duration(seconds: 15);

  @override
  Future<void> send(Map<String, Object?> report) async {
    await _post(report).timeout(_uploadTimeout);
  }

  Future<void> _post(Map<String, Object?> report) async {
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(report));
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('crash ingest ${response.statusCode}', uri: uri);
    }
  }
}

/// Skips the network unless the user opted in; scrubs and throttles before upload.
class ConsentGatedHttpCrashSink implements CrashSink {
  ConsentGatedHttpCrashSink(
    this.preferences,
    this.throttle,
    this.inner,
  );

  final CrashUploadPreferences preferences;
  final CrashUploadThrottle throttle;
  final HttpCrashSink inner;

  @override
  Future<void> send(Map<String, Object?> report) async {
    if (!await preferences.isEnabled()) return;
    final fingerprint = report['fingerprint'] as String? ?? '';
    if (!throttle.tryConsumeUploadQuota(fingerprint)) return;
    final upload = Map<String, Object?>.from(scrubCrashReport(report))
      ..remove('fingerprint')
      ..remove('at');
    await inner.send(upload);
  }
}

class CrashReporter {
  CrashReporter({
    required this.sinks,
    this.appVersion = '1.0.6+12',
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final List<CrashSink> sinks;
  final String appVersion;
  final DateTime Function() _clock;

  Future<void> record(Object error, StackTrace stack, String source) async {
    final fingerprint = crashFingerprint(error, stack);
    final report = <String, Object?>{
      'message': error.toString(),
      'stack': stack.toString(),
      'runtimeType': error.runtimeType.toString(),
      'source': source,
      'appVersion': appVersion,
      'platform': Platform.operatingSystem,
      'at': _clock().toUtc().toIso8601String(),
      'fingerprint': fingerprint,
    };
    for (final sink in sinks) {
      try {
        await sink.send(report);
      } catch (_) {
        // A sink failure must not replace the original crash.
      }
    }
  }
}

/// Installs Flutter and platform error hooks. Returns the reporter so tests
/// can inspect it. Previous hooks are still called.
CrashReporter installCrashReporting(CrashReporter reporter) {
  final previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    reporter.record(
      details.exception,
      details.stack ?? StackTrace.empty,
      'flutter',
    );
    previousFlutter?.call(details);
  };

  final previousPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.record(error, stack, 'platform');
    if (previousPlatform != null) return previousPlatform(error, stack);
    return true;
  };
  return reporter;
}