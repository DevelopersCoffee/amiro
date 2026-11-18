import 'dart:convert';
import 'dart:io';

/// Delivers allow-listed analytics payloads. Implementations must not throw.
abstract interface class AnalyticsSink {
  Future<void> send(List<Map<String, Object?>> events);
}

class MemoryAnalyticsSink implements AnalyticsSink {
  final List<Map<String, Object?>> events = [];

  @override
  Future<void> send(List<Map<String, Object?>> batch) async {
    events.addAll(batch);
  }
}

class HttpAnalyticsSink implements AnalyticsSink {
  HttpAnalyticsSink(this.uri, {HttpClient? client})
    : _client = client ?? HttpClient();

  final Uri uri;
  final HttpClient _client;

  @override
  Future<void> send(List<Map<String, Object?>> events) async {
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'events': events}));
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('analytics ingest ${response.statusCode}', uri: uri);
    }
  }
}