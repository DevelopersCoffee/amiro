import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/profile_secrets_store.dart';
import 'package:amiro_app/identity/secret_storage.dart';
import 'package:amiro_app/identity/supabase_profile_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

void main() {
  test('push sends no HTTP when backup is disabled', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: false);
    final cloud = built.cloud;
    const identity = Identity(
      id: 'id-1',
      displayName: 'Uday',
      username: 'uday',
      email: 'secret@example.com',
    );

    expect(await cloud.push(identity), isFalse);
    expect(harness.requestCount, 0);
  });

  test('push uploads allowlisted fields only when backup is enabled', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final builtEnabled = await harness.buildCloud(enabled: true);
    final cloud = builtEnabled.cloud;
    final identity = Identity(
      id: 'id-2',
      displayName: 'Alex',
      username: 'alex',
      email: 'secret@example.com',
      bio: 'private bio',
      mobile: '555',
      xHandle: '@secret',
      instagramHandle: '@insta',
      website: 'https://public.example',
      privacy: {
        'email': const PrivacyFlag(false),
        'bio': const PrivacyFlag(false),
        'mobile': const PrivacyFlag(false),
        'xHandle': const PrivacyFlag(false),
        'instagramHandle': const PrivacyFlag(false),
        'website': const PrivacyFlag(true),
      },
    );

    expect(await cloud.push(identity), isTrue);
    final insertBody = harness.lastProfileInsert;
    expect(insertBody, isNotNull);
    final payload = insertBody!['payload'] as Map<String, dynamic>;
    expect(payload.keys, containsAll(['id', 'displayName', 'username', 'privacy']));
    expect(payload.containsKey('email'), isFalse);
    expect(payload.containsKey('bio'), isFalse);
    expect(payload.containsKey('mobile'), isFalse);
    expect(payload.containsKey('xHandle'), isFalse);
    expect(payload.containsKey('instagramHandle'), isFalse);
    expect(payload['website'], 'https://public.example');
    expect(insertBody.containsKey('revenuecat_app_user_id'), isFalse);
  });

  test('revokeBackup issues DELETE; disabled push sends no further HTTP', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    const identity = Identity(
      id: 'id-3',
      displayName: 'Sam',
      username: 'sam',
    );
    expect(await built.cloud.push(identity), isTrue);

    expect(
      (await built.cloud.revokeBackup(identityId: 'id-3')).success,
      isTrue,
    );
    expect(harness.deleteCount, 1);
    final afterDelete = harness.requestCount;

    await built.prefs.setEnabled(false);
    expect(await built.cloud.push(identity), isFalse);
    expect(harness.requestCount, afterDelete);
  });

  test('revokeBackup fails when DELETE matches zero rows', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.deleteReturnsEmpty = true;

    final built = await harness.buildCloud(enabled: true);
    const identity = Identity(
      id: 'id-zero',
      displayName: 'Z',
      username: 'z',
    );
    expect(await built.cloud.push(identity), isTrue);

    final result = await built.cloud.revokeBackup(identityId: 'id-zero');
    expect(result.success, isFalse);
    expect(result.userMessage, isNotNull);
  });

  test('revokeBackup clears credentials after a successful DELETE', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-4', displayName: 'A', username: 'a'),
    );
    expect(await built.secrets.readSessionJson(), isNotNull);
    expect(await built.cloud.recoveryCode(), isNotNull);

    expect((await built.cloud.revokeBackup(identityId: 'id-4')).success, isTrue);
    expect(await built.secrets.readSessionJson(), isNull);
    expect(await built.cloud.recoveryCode(), isNull);
  });

  test('transient refresh failure does not sign in as a new anonymous user', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.refreshStatusCode = 503;

    final built = await harness.buildCloud(
      enabled: true,
      sessionExpiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final result = await built.cloud.revokeBackup(identityId: 'id-x');
    expect(result.success, isFalse);
    expect(harness.anonymousSignupCount, 0);
  });
}

class _FakeSupabaseHarness {
  _FakeSupabaseHarness(this._server, this.port);

  final HttpServer _server;
  final int port;
  int requestCount = 0;
  int deleteCount = 0;
  bool deleteReturnsEmpty = false;
  int refreshStatusCode = 401;
  int anonymousSignupCount = 0;
  Map<String, dynamic>? lastProfileInsert;

  static Future<_FakeSupabaseHarness> start() async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    final harness = _FakeSupabaseHarness(server, server.port);
    server.listen(harness._handle);
    return harness;
  }

  Future<({
    SupabaseProfileCloud cloud,
    CloudBackupPreferences prefs,
    ProfileSecretsStore secrets,
  })> buildCloud({
    required bool enabled,
    DateTime? sessionExpiresAt,
  }) async {
    final dir = Directory.systemTemp.createTempSync('amiro_fake_sb');
    final prefs = CloudBackupPreferences.inDirectory(dir);
    if (enabled) {
      await prefs.setEnabled(true);
    }
    final secrets = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: InMemorySecretStorage(),
    );
    final expires =
        sessionExpiresAt ??
        DateTime.now().add(const Duration(hours: 1));
    await secrets.writeSessionJson(
      jsonEncode({
        'access_token': 'access-token',
        'refresh_token': 'refresh-token',
        'user_id': 'user-1',
        'expires_at': expires.toUtc().toIso8601String(),
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
      secrets: secrets,
    );
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    requestCount += 1;
    final path = request.uri.path;
    if (path == '/rest/v1/profiles' && request.method == 'GET') {
      request.response.statusCode = 200;
      request.response.write('[]');
    } else if (path == '/rest/v1/profiles' && request.method == 'POST') {
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body);
      if (decoded is List && decoded.isNotEmpty) {
        lastProfileInsert = Map<String, dynamic>.from(decoded.first as Map);
      } else if (decoded is Map) {
        lastProfileInsert = Map<String, dynamic>.from(decoded);
      }
      request.response.statusCode = 201;
      request.response.write('[]');
    } else if (path == '/rest/v1/profiles' && request.method == 'PATCH') {
      request.response.statusCode = 200;
      request.response.write('[]');
    } else if (path == '/rest/v1/profile_members' && request.method == 'POST') {
      request.response.statusCode = 201;
      request.response.write('[]');
    } else if (path == '/rest/v1/profiles' && request.method == 'DELETE') {
      deleteCount += 1;
      if (deleteReturnsEmpty) {
        request.response.statusCode = 200;
        request.response.write('[]');
      } else {
        request.response.statusCode = 200;
        request.response.write(jsonEncode([{'identity_id': 'deleted'}]));
      }
    } else if (path.startsWith('/auth/v1/token')) {
      request.response.statusCode = refreshStatusCode;
    } else if (path == '/auth/v1/signup') {
      anonymousSignupCount += 1;
      request.response.statusCode = 201;
      request.response.write(
        jsonEncode({
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
          'expires_in': 3600,
          'user': {'id': 'new-user'},
        }),
      );
    } else {
      request.response.statusCode = 404;
    }
    await request.response.close();
  }
}
