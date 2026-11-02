import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/profile_secrets_store.dart';
import 'package:amiro_app/identity/secret_storage.dart';
import 'package:amiro_app/identity/supabase_profile_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import 'recording_profile_cloud.dart';

void main() {
  test('RecordingProfileCloud tracks push and revoke calls', () async {
    final cloud = RecordingProfileCloud();
    const identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
    );
    expect(await cloud.push(identity), isTrue);
    expect(cloud.pushCalls, 1);
    expect(await cloud.revokeBackup(), isTrue);
    expect(cloud.revokeCalls, 1);
  });

  test('prefs disabled prevents HTTP push (mutant C1 guard)', () async {
    final harness = await _Harness.start();
    addTearDown(harness.close);
    final built = await harness.buildCloud(enabled: false);
    const identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
    );
    expect(await built.cloud.push(identity), isFalse);
    expect(harness.requestCount, 0);
  });

  test('prefs enabled allows HTTP push (mutant C1)', () async {
    final harness = await _Harness.start();
    addTearDown(harness.close);
    final built = await harness.buildCloud(enabled: true);
    const identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
    );
    expect(await built.cloud.push(identity), isTrue);
    expect(harness.requestCount, greaterThan(0));
  });
}

class _Harness {
  _Harness(this._server, this.port);

  final HttpServer _server;
  final int port;
  int requestCount = 0;

  static Future<_Harness> start() async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    final harness = _Harness(server, server.port);
    server.listen(harness._handle);
    return harness;
  }

  Future<({SupabaseProfileCloud cloud, CloudBackupPreferences prefs})> buildCloud({
    required bool enabled,
  }) async {
    final dir = Directory.systemTemp.createTempSync('amiro_flow');
    final prefs = CloudBackupPreferences.inDirectory(dir);
    if (enabled) await prefs.setEnabled(true);
    final secrets = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: InMemorySecretStorage(),
    );
    await secrets.writeSessionJson(
      jsonEncode({
        'access_token': 'access-token',
        'refresh_token': 'refresh-token',
        'user_id': 'user-1',
        'expires_at': DateTime.now()
            .add(const Duration(hours: 1))
            .toUtc()
            .toIso8601String(),
      }),
    );
    return (
      cloud: SupabaseProfileCloud(
        directory: dir,
        projectUrl: Uri.parse('http://127.0.0.1:$port'),
        anonKey: 'anon-key',
        backupPreferences: prefs,
        secrets: secrets,
      ),
      prefs: prefs,
    );
  }

  Future<void> close() async => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    requestCount += 1;
    final path = request.uri.path;
    if (path == '/rest/v1/profiles' && request.method == 'GET') {
      request.response.statusCode = 200;
      request.response.write('[]');
    } else if (path == '/rest/v1/profiles' && request.method == 'POST') {
      request.response.statusCode = 201;
      request.response.write('[]');
    } else if (path == '/rest/v1/profile_members' && request.method == 'POST') {
      request.response.statusCode = 201;
      request.response.write('[]');
    } else if (path == '/rest/v1/profiles' && request.method == 'PATCH') {
      request.response.statusCode = 200;
      request.response.write('[]');
    } else if (path == '/rest/v1/profiles' && request.method == 'DELETE') {
      request.response.statusCode = 204;
    } else {
      request.response.statusCode = 404;
    }
    await request.response.close();
  }
}
