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

/// POSTs allow-listed events; DELETE revokes server rows for an install id.
class HttpAnalyticsSink implements AnalyticsSink {
  HttpAnalyticsSink(
    this.uri, {
    HttpClient? client,
    this.allowInsecureHttp = false,
  }) : _client = client ?? HttpClient() {
    if (!allowInsecureHttp && uri.scheme != 'https') {
      throw ArgumentError('Analytics ingest URL must use https');
    }
    _client.connectionTimeout = const Duration(seconds: 10);
  }

  final Uri uri;
  final bool allowInsecureHttp;
  final HttpClient _client;

  static const Duration _uploadTimeout = Duration(seconds: 15);

  @override
  Future<void> send(List<Map<String, Object?>> events) async {
    await _post(events).timeout(_uploadTimeout);
  }

  Future<void> revokeInstall(String installId) async {
    await _deleteRevoke(installId).timeout(_uploadTimeout);
  }

  Future<void> _post(List<Map<String, Object?>> events) async {
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'events': events}));
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('analytics ingest ${response.statusCode}', uri: uri);
    }
  }

  Future<void> _deleteRevoke(String installId) async {
    final request = await _client.openUrl('DELETE', uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({'install_id': installId}));
    final response = await request.close();
    await response.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'analytics revoke ${response.statusCode}',
        uri: uri,
      );
    }
  }
}