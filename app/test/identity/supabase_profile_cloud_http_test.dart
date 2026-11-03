import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/profile_cloud.dart';
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

  test('revokeBackup succeeds when backup on but server has no profile row', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    expect(await built.secrets.readSessionJson(), isNotNull);

    final result = await built.cloud.revokeBackup(
      identityId: 'never-pushed',
    );
    expect(result.success, isTrue);
    expect(await built.secrets.readSessionJson(), isNull);
  });

  test('revokeBackup fails when DELETE matches zero rows but row still visible', () async {
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
    expect(await built.secrets.readSessionJson(), isNotNull);
  });

  test('X7: failed revoke does not clear credentials', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.deleteReturnsEmpty = true;

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-x7', displayName: 'X', username: 'x'),
    );
    await built.secrets.writeRecoveryCode('recovery-secret');
    final sessionBefore = await built.secrets.readSessionJson();

    expect(
      (await built.cloud.revokeBackup(identityId: 'id-x7')).success,
      isFalse,
    );
    expect(await built.secrets.readSessionJson(), sessionBefore);
    expect(await built.cloud.recoveryCode(), 'recovery-secret');
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

  test('Y5: 429 refresh does not swap to a new anonymous user', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.refreshStatusCode = 429;

    final built = await harness.buildCloud(
      enabled: true,
      sessionExpiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final result = await built.cloud.revokeBackup(identityId: 'id-x');
    expect(result.success, isFalse);
    expect(harness.anonymousSignupCount, 0);
  });

  test('400 validation_failed refresh does not swap users', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.refreshStatusCode = 400;
    harness.refreshBody = jsonEncode({
      'error': 'validation_failed',
      'error_description': 'bad request',
    });

    final built = await harness.buildCloud(
      enabled: true,
      sessionExpiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    expect(
      (await built.cloud.revokeBackup(identityId: 'id-x')).success,
      isFalse,
    );
    expect(harness.anonymousSignupCount, 0);
  });

  test('dead refresh token (400) starts a new anonymous session', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.refreshStatusCode = 400;
    harness.refreshBody = jsonEncode({
      'error': 'invalid_grant',
      'error_description': 'refresh_token_not_found',
    });

    final built = await harness.buildCloud(
      enabled: true,
      sessionExpiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    expect(
      await built.cloud.push(
        const Identity(id: 'id-new', displayName: 'N', username: 'n'),
      ),
      isTrue,
    );
    expect(harness.anonymousSignupCount, 1);
  });

  test('N7: revokeBackup DELETE filters by identity_id', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    const identity = Identity(
      id: 'id-filter',
      displayName: 'F',
      username: 'f',
    );
    expect(await built.cloud.push(identity), isTrue);

    expect(
      (await built.cloud.revokeBackup(identityId: 'id-filter')).success,
      isTrue,
    );
    expect(harness.lastDeleteUri, isNotNull);
    expect(
      harness.lastDeleteUri!.queryParameters['identity_id'],
      'eq.id-filter',
    );
  });

  test('X3: revokeBackup sends Prefer return=representation on DELETE', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-prefer', displayName: 'P', username: 'p'),
    );
    await built.cloud.revokeBackup(identityId: 'id-prefer');
    expect(harness.lastDeletePrefer, 'return=representation');
  });

  test('X2: revoke fails when a profile row is still visible after zero DELETE', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.deleteReturnsEmpty = true;

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-vis', displayName: 'V', username: 'v'),
    );

    final result = await built.cloud.revokeBackup();
    expect(result.success, isFalse);
  });

  test('Y3: empty re-select clears credentials when owner session matches', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.deleteReturnsEmpty = true;

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-y3', displayName: 'Y', username: 'y'),
    );
    expect(await built.secrets.readCloudProfileOwnerId(), 'user-1');
    harness.profileRows.clear();

    final result = await built.cloud.revokeBackup(identityId: 'id-y3');
    expect(result.success, isTrue);
    expect(await built.secrets.readSessionJson(), isNull);
  });

  test('B1: session swap after dead refresh cannot falsely revoke', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-swap', displayName: 'S', username: 's'),
    );
    expect(await built.secrets.readCloudProfileOwnerId(), 'user-1');

    harness.refreshStatusCode = 400;
    harness.refreshBody = jsonEncode({
      'error': 'invalid_grant',
      'error_description': 'refresh_token_not_found',
    });
    harness.deleteReturnsEmpty = true;
    await built.secrets.writeSessionJson(
      jsonEncode({
        'access_token': 'access-token',
        'refresh_token': 'refresh-token',
        'user_id': 'user-1',
        'expires_at': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toUtc()
            .toIso8601String(),
      }),
    );

    final result = await built.cloud.revokeBackup(identityId: 'id-swap');
    expect(result.success, isFalse);
    expect(await built.secrets.readSessionJson(), isNotNull);
    expect(await built.cloud.recoveryCode(), isNotNull);
    expect(await built.secrets.readCloudProfileOwnerId(), 'user-1');
  });

  test('revoke succeeds on retry when row was already deleted', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-retry', displayName: 'R', username: 'r'),
    );
    expect(
      (await built.cloud.revokeBackup(identityId: 'id-retry')).success,
      isTrue,
    );
    harness.profileRows.clear();

    final retry = await built.cloud.revokeBackup(identityId: 'id-retry');
    expect(retry.success, isTrue);
  });

  test('N9: revoke without cloud support does not issue HTTP', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final dir = Directory.systemTemp.createTempSync('amiro_no_cloud');
    final prefs = CloudBackupPreferences.inDirectory(dir);
    await prefs.setEnabled(true);
    final secrets = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: InMemorySecretStorage(),
    );
    final cloud = SupabaseProfileCloud(
      directory: dir,
      projectUrl: Uri.parse('http://127.0.0.1:${harness.port}'),
      anonKey: '',
      backupPreferences: prefs,
      secrets: secrets,
    );
    expect(cloud.supportsRestore, isFalse);
    expect((await cloud.revokeBackup()).success, isTrue);
    expect(harness.deleteCount, 0);
    expect(harness.requestCount, 0);
  });

  test('X11: successful revoke removes legacy recovery plaintext file', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    final legacyFile = File(
      '${built.secrets.legacyDirectory.path}/profile_recovery_code.txt',
    );
    await legacyFile.writeAsString('legacy-on-disk');
    await built.cloud.push(
      const Identity(id: 'id-x11', displayName: 'L', username: 'l'),
    );

    expect((await built.cloud.revokeBackup(identityId: 'id-x11')).success, isTrue);
    expect(await legacyFile.exists(), isFalse);
  });

  test('X8: pull returns null when session read throws', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final dir = Directory.systemTemp.createTempSync('amiro_pull_x8');
    final storage = _ThrowOnSessionReadStorage();
    final secrets = ProfileSecretsStore(
      legacyDirectory: dir,
      secureStorage: storage,
    );
    await secrets.writeSessionJson('{"access_token":"a"}');
    final prefs = CloudBackupPreferences.inDirectory(dir);
    await prefs.setEnabled(true);
    final cloud = SupabaseProfileCloud(
      directory: dir,
      projectUrl: Uri.parse('http://127.0.0.1:${harness.port}'),
      anonKey: 'anon-key',
      backupPreferences: prefs,
      secrets: secrets,
    );

    expect(await cloud.pull(), isNull);
  });

  test('claim returns null on bad code but throws on 503', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.claimStatusCode = 503;

    final built = await harness.buildCloud(enabled: true);
    await expectLater(
      built.cloud.claim('1234567890123456'),
      throwsA(isA<SessionRefreshFailure>()),
    );
  });
}

class _ThrowOnSessionReadStorage implements SecretStorage {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async {
    if (key == 'supabase_session_json') {
      throw StateError('keystore read failed');
    }
    return null;
  }

  @override
  Future<void> write(String key, String value) async {}
}

class _FakeSupabaseHarness {
  _FakeSupabaseHarness(this._server, this.port);

  final HttpServer _server;
  final int port;
  int requestCount = 0;
  int deleteCount = 0;
  bool deleteReturnsEmpty = false;
  int refreshStatusCode = 401;
  String refreshBody = '';
  int anonymousSignupCount = 0;
  int claimStatusCode = 200;
  Uri? lastDeleteUri;
  String? lastDeletePrefer;
  Map<String, dynamic>? lastProfileInsert;
  final List<Map<String, dynamic>> profileRows = [];

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
      if (request.uri.queryParameters['select'] == 'identity_id') {
        if (profileRows.isEmpty) {
          request.response.write('[]');
        } else {
          request.response.write(
            jsonEncode([
              for (final row in profileRows)
                {'identity_id': row['identity_id']},
            ]),
          );
        }
      } else {
        request.response.write(
          jsonEncode([
            for (final row in profileRows) {'payload': row['payload']},
          ]),
        );
      }
    } else if (path == '/rest/v1/profiles' && request.method == 'POST') {
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body);
      Map<String, dynamic> row;
      if (decoded is List && decoded.isNotEmpty) {
        row = Map<String, dynamic>.from(decoded.first as Map);
      } else if (decoded is Map) {
        row = Map<String, dynamic>.from(decoded);
      } else {
        row = {};
      }
      lastProfileInsert = row;
      profileRows.add(row);
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
      lastDeleteUri = request.uri;
      lastDeletePrefer = request.headers.value('prefer');
      final idFilter = request.uri.queryParameters['identity_id'];
      final hadRow = profileRows.any(
        (row) => idFilter == 'eq.${row['identity_id']}',
      );
      if (!deleteReturnsEmpty && hadRow) {
        profileRows.removeWhere(
          (row) => idFilter == 'eq.${row['identity_id']}',
        );
        request.response.statusCode = 200;
        request.response.write(
          jsonEncode([
            {'identity_id': idFilter?.replaceFirst('eq.', '') ?? 'deleted'},
          ]),
        );
      } else {
        request.response.statusCode = 200;
        request.response.write('[]');
      }
    } else if (path.startsWith('/auth/v1/token')) {
      request.response.statusCode = refreshStatusCode;
      if (refreshBody.isNotEmpty) {
        request.response.write(refreshBody);
      }
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
    } else if (path == '/rest/v1/rpc/join_profile') {
      request.response.statusCode = claimStatusCode;
      request.response.write('null');
    } else {
      request.response.statusCode = 404;
    }
    await request.response.close();
  }
}
