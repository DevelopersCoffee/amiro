import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/profile_cloud.dart';
import 'package:amiro_app/identity/profile_secrets_store.dart';
import 'package:amiro_app/identity/secret_storage.dart';
import 'package:amiro_app/identity/supabase_profile_cloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

/// Real GoTrue refresh error body (not the OAuth-style `error`/`error_description`).
final _goTrueRefreshTokenNotFoundBody = jsonEncode({
  'code': 400,
  'error_code': 'refresh_token_not_found',
  'msg': 'Invalid Refresh Token: Refresh Token Not Found',
});

/// Pinned copy (BF7); must match production [SupabaseProfileCloud] stranded text.
const _strandedInstallRevokeMessage =
    'This device cannot remove the cloud backup copy. If sign-in on this '
    'device no longer matches the account that enabled backup, request '
    'deletion by email as described in the privacy policy.';

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
    harness.refreshBody = _goTrueRefreshTokenNotFoundBody;

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

  test('Z2/Z3: real GoTrue refresh body swaps on refresh_token_not_found', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.refreshStatusCode = 400;
    harness.refreshBody = _goTrueRefreshTokenNotFoundBody;

    final built = await harness.buildCloud(
      enabled: true,
      sessionExpiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    expect(
      await built.cloud.push(
        const Identity(id: 'id-gotrue', displayName: 'G', username: 'g'),
      ),
      isTrue,
    );
    expect(harness.anonymousSignupCount, 1);
  });

  test('Z4: refresh auth failure reads error_description without error_code', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.refreshStatusCode = 400;
    harness.refreshBody = jsonEncode({
      'code': 400,
      'error_description': 'refresh_token_not_found',
    });

    final built = await harness.buildCloud(
      enabled: true,
      sessionExpiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    expect(
      await built.cloud.push(
        const Identity(id: 'id-z4', displayName: 'Z', username: 'z'),
      ),
      isTrue,
    );
    expect(harness.anonymousSignupCount, 1);
  });

  test('Z5/B1: swapped owner fails empty re-select and keeps credentials', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-swap', displayName: 'S', username: 's'),
    );
    expect(await built.secrets.readCloudProfileOwnerId(), 'user-1');

    harness.refreshStatusCode = 400;
    harness.refreshBody = _goTrueRefreshTokenNotFoundBody;
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
    expect(result.userMessage, _strandedInstallRevokeMessage);
    expect(await built.secrets.readSessionJson(), isNotNull);
    expect(await built.cloud.recoveryCode(), isNotNull);
    expect(await built.secrets.readCloudProfileOwnerId(), 'user-1');
    expect(harness.anonymousSignupCount, 1);
  });

  test('Z6: legacy install with recovery code fails when row is not visible', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.deleteReturnsEmpty = true;

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-legacy', displayName: 'L', username: 'l'),
    );
    await built.secrets.deleteCloudProfileOwnerIdForTest();
    expect(await built.secrets.readCloudProfileOwnerId(), isNull);
    expect(await built.cloud.recoveryCode(), isNotNull);
    harness.profileRows.clear();

    final result = await built.cloud.revokeBackup(identityId: 'id-legacy');
    expect(result.success, isFalse);
    expect(result.userMessage, _strandedInstallRevokeMessage);
    expect(await built.secrets.readSessionJson(), isNotNull);
    expect(await built.cloud.recoveryCode(), isNotNull);
  });

  test('Z9: no owner id and no recovery code succeeds when row is gone', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    expect(await built.cloud.recoveryCode(), isNull);

    final result = await built.cloud.revokeBackup(identityId: 'never-uploaded');
    expect(result.success, isTrue);
    expect(await built.secrets.readSessionJson(), isNull);
  });

  test('member revoke sees row but cannot delete (owner-only DELETE)', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    harness.seedProfile(
      identityId: 'id-member',
      ownerId: 'user-1',
      payload: const {
        'id': 'id-member',
        'displayName': 'O',
        'username': 'o',
      },
      recoveryCode: '1234567890123456',
      members: {'user-2'},
    );

    final built = await harness.buildCloud(
      enabled: true,
      userId: 'user-2',
      accessToken: 'access-user-2',
    );
    await built.secrets.writeRecoveryCode('1234567890123456');

    final result = await built.cloud.revokeBackup(identityId: 'id-member');
    expect(result.success, isFalse);
    expect(result.userMessage, isNotNull);
    expect(result.userMessage, isNot(_strandedInstallRevokeMessage));
    expect(await built.secrets.readSessionJson(), isNotNull);
  });

  test('Z12: claim does not write cloud profile owner id', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    harness.seedProfile(
      identityId: 'id-claim',
      ownerId: 'user-owner',
      payload: const {
        'id': 'id-claim',
        'displayName': 'C',
        'username': 'c',
      },
      recoveryCode: 'abcdef0123456789',
    );

    final built = await harness.buildCloud(enabled: true);
    expect(await built.secrets.readCloudProfileOwnerId(), isNull);

    final identity = await built.cloud.claim('abcdef0123456789');
    expect(identity, isNotNull);
    expect(await built.secrets.readCloudProfileOwnerId(), isNull);
  });

  test('Z13/BF1: member push does not write cloud profile owner id', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    harness.seedProfile(
      identityId: 'id-z13',
      ownerId: 'user-1',
      payload: const {
        'id': 'id-z13',
        'displayName': 'M',
        'username': 'm',
      },
      recoveryCode: 'fedcba9876543210',
      members: {'user-2'},
    );

    final built = await harness.buildCloud(
      enabled: true,
      userId: 'user-2',
      accessToken: 'access-user-2',
    );
    expect(await built.secrets.readCloudProfileOwnerId(), isNull);

    expect(
      await built.cloud.push(
        const Identity(id: 'id-z13', displayName: 'M', username: 'm'),
      ),
      isTrue,
    );
    expect(await built.secrets.readCloudProfileOwnerId(), isNull);
  });

  test('BF1b: member revoke does not backfill cloud profile owner id', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    harness.seedProfile(
      identityId: 'id-bf1b',
      ownerId: 'user-1',
      payload: const {
        'id': 'id-bf1b',
        'displayName': 'M',
        'username': 'm',
      },
      recoveryCode: '1234567890123456',
      members: {'user-2'},
    );

    final built = await harness.buildCloud(
      enabled: true,
      userId: 'user-2',
      accessToken: 'access-user-2',
    );
    await built.secrets.writeRecoveryCode('1234567890123456');

    await built.cloud.revokeBackup(identityId: 'id-bf1b');

    expect(await built.secrets.readCloudProfileOwnerId(), isNull);
  });

  test('Z14: offline claim throws SessionRefreshFailure', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await harness.close();

    await expectLater(
      built.cloud.claim('1234567890123456'),
      throwsA(isA<SessionRefreshFailure>()),
    );
  });

  test('BF3: legacy push backfills stored cloud profile owner id', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    const identity = Identity(id: 'id-bf3', displayName: 'B', username: 'b');
    expect(await built.cloud.push(identity), isTrue);
    await built.secrets.deleteCloudProfileOwnerIdForTest();
    expect(await built.secrets.readCloudProfileOwnerId(), isNull);

    expect(await built.cloud.push(identity), isTrue);
    expect(await built.secrets.readCloudProfileOwnerId(), 'user-1');
  });

  test('BF2: revoke backfills owner id before DELETE runs', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-bf2', displayName: 'B', username: 'b'),
    );
    await built.secrets.deleteCloudProfileOwnerIdForTest();
    harness.onBeforeDelete = () async {
      expect(await built.secrets.readCloudProfileOwnerId(), 'user-1');
    };

    expect(
      (await built.cloud.revokeBackup(identityId: 'id-bf2')).success,
      isTrue,
    );
  });

  test('BF4: backfill does not overwrite an existing cloud profile owner id', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-bf4', displayName: 'B', username: 'b'),
    );
    await built.secrets.writeCloudProfileOwnerId('already-set');

    await built.cloud.push(
      const Identity(id: 'id-bf4', displayName: 'B2', username: 'b2'),
    );

    expect(await built.secrets.readCloudProfileOwnerId(), 'already-set');
  });

  test('BF5/BF6: owner select 500 leaves owner id unchanged', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.ownerIdSelectStatusCode = 500;

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-bf5', displayName: 'B', username: 'b'),
    );
    await built.secrets.deleteCloudProfileOwnerIdForTest();

    expect(await built.cloud.push(
      const Identity(id: 'id-bf5', displayName: 'B2', username: 'b2'),
    ), isTrue);
    expect(await built.secrets.readCloudProfileOwnerId(), isNull);

    expect(
      (await built.cloud.revokeBackup(identityId: 'id-bf5')).success,
      isTrue,
    );
  });

  test('BF6: backfill uses identity_id filter when multiple rows visible', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    const identity = Identity(id: 'id-target', displayName: 'T', username: 't');
    expect(await built.cloud.push(identity), isTrue);
    harness.seedProfile(
      identityId: 'id-other',
      ownerId: 'other-owner',
      payload: const {
        'id': 'id-other',
        'displayName': 'O',
        'username': 'o',
      },
      recoveryCode: 'aaaaaaaabbbbbbbb',
      members: {'user-1'},
    );
    await built.secrets.deleteCloudProfileOwnerIdForTest();

    expect(await built.cloud.push(identity), isTrue);
    expect(await built.secrets.readCloudProfileOwnerId(), 'user-1');
  });

  test('backfill ignores non-JSON owner select body', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.ownerIdSelectBody = '<html>not json</html>';

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-html', displayName: 'H', username: 'h'),
    );
    await built.secrets.deleteCloudProfileOwnerIdForTest();

    expect(await built.cloud.push(
      const Identity(id: 'id-html', displayName: 'H2', username: 'h2'),
    ), isTrue);
    expect(await built.secrets.readCloudProfileOwnerId(), isNull);
  });

  test('BF3 swap: backfill does not write after session swap', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-swap-bf', displayName: 'S', username: 's'),
    );
    await built.secrets.deleteCloudProfileOwnerIdForTest();
    harness.refreshStatusCode = 400;
    harness.refreshBody = _goTrueRefreshTokenNotFoundBody;
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

    await built.cloud.revokeBackup(identityId: 'id-swap-bf');

    expect(await built.secrets.readCloudProfileOwnerId(), isNull);
    expect(harness.anonymousSignupCount, 1);
  });

  test('X2b: revoke with null identityId uses primary row and fails on zero DELETE', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.deleteReturnsEmpty = true;

    final built = await harness.buildCloud(enabled: true);
    await built.cloud.push(
      const Identity(id: 'id-x2b', displayName: 'X', username: 'x'),
    );

    final result = await built.cloud.revokeBackup();
    expect(result.success, isFalse);
    expect(harness.deleteCount, greaterThan(0));
  });

  test('fake POST profiles rejects owner_id mismatch with 403', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);

    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:${harness.port}/rest/v1/profiles'),
    );
    request.headers.set('Authorization', 'Bearer access-token');
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'identity_id': 'id-forbidden',
      'owner_id': 'someone-else',
      'payload': {'id': 'id-forbidden', 'displayName': 'F', 'username': 'f'},
      'recovery_code': '1234567890123456',
    }));
    final response = await request.close();
    expect(response.statusCode, 403);
    client.close();
  });

  test('fake profile_members rejects non-owner join with 403', () async {
    final harness = await _FakeSupabaseHarness.start();
    addTearDown(harness.close);
    harness.seedProfile(
      identityId: 'id-403',
      ownerId: 'user-1',
      payload: const {'id': 'id-403', 'displayName': 'O', 'username': 'o'},
      recoveryCode: '1234567890123456',
    );

    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('http://127.0.0.1:${harness.port}/rest/v1/profile_members'),
    );
    request.headers.set('Authorization', 'Bearer access-user-2');
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'identity_id': 'id-403',
      'user_id': 'user-2',
    }));
    final response = await request.close();
    expect(response.statusCode, 403);
    client.close();
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

class _ProfileRow {
  _ProfileRow({
    required this.identityId,
    required this.ownerId,
    required this.payload,
    required this.recoveryCode,
    Set<String>? members,
  }) : members = members ?? {};

  final String identityId;
  final String ownerId;
  Map<String, dynamic> payload;
  final String recoveryCode;
  final Set<String> members;

  bool visibleTo(String userId) =>
      ownerId == userId || members.contains(userId);
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
  int? ownerIdSelectStatusCode;
  String? ownerIdSelectBody;
  Future<void> Function()? onBeforeDelete;
  Uri? lastDeleteUri;
  String? lastDeletePrefer;
  Map<String, dynamic>? lastProfileInsert;
  final List<_ProfileRow> profileRows = [];
  final Map<String, String> accessTokenToUserId = {
    'access-token': 'user-1',
    'new-access': 'new-user',
    'access-user-2': 'user-2',
  };

  static Future<_FakeSupabaseHarness> start() async {
    final server = await HttpServer.bind('127.0.0.1', 0);
    final harness = _FakeSupabaseHarness(server, server.port);
    server.listen(harness._handle);
    return harness;
  }

  void seedProfile({
    required String identityId,
    required String ownerId,
    required Map<String, dynamic> payload,
    required String recoveryCode,
    Set<String>? members,
  }) {
    profileRows.add(
      _ProfileRow(
        identityId: identityId,
        ownerId: ownerId,
        payload: Map<String, dynamic>.from(payload),
        recoveryCode: recoveryCode,
        members: members,
      ),
    );
  }

  Future<({
    SupabaseProfileCloud cloud,
    CloudBackupPreferences prefs,
    ProfileSecretsStore secrets,
  })> buildCloud({
    required bool enabled,
    DateTime? sessionExpiresAt,
    String userId = 'user-1',
    String accessToken = 'access-token',
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
    accessTokenToUserId[accessToken] = userId;
    final expires =
        sessionExpiresAt ??
        DateTime.now().add(const Duration(hours: 1));
    await secrets.writeSessionJson(
      jsonEncode({
        'access_token': accessToken,
        'refresh_token': 'refresh-token',
        'user_id': userId,
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

  String? _userIdFromRequest(HttpRequest request) {
    final auth = request.headers.value('authorization');
    if (auth == null || !auth.toLowerCase().startsWith('bearer ')) {
      return null;
    }
    final token = auth.substring(7).trim();
    return accessTokenToUserId[token];
  }

  Iterable<_ProfileRow> _visibleRows(String? userId) sync* {
    if (userId == null) return;
    for (final row in profileRows) {
      if (row.visibleTo(userId)) yield row;
    }
  }

  _ProfileRow? _rowByIdentity(String identityId) {
    for (final row in profileRows) {
      if (row.identityId == identityId) return row;
    }
    return null;
  }

  Future<void> _handle(HttpRequest request) async {
    requestCount += 1;
    final path = request.uri.path;
    final userId = _userIdFromRequest(request);
    if (path == '/rest/v1/profiles' && request.method == 'GET') {
      request.response.statusCode = 200;
      final select = request.uri.queryParameters['select'];
      final identityEq = request.uri.queryParameters['identity_id'];
      var visible = _visibleRows(userId).toList();
      if (identityEq != null && identityEq.startsWith('eq.')) {
        final id = identityEq.substring(3);
        visible = visible.where((row) => row.identityId == id).toList();
      }
      if (select == 'identity_id') {
        request.response.write(
          jsonEncode([
            for (final row in visible) {'identity_id': row.identityId},
          ]),
        );
      } else if (select == 'owner_id') {
        if (ownerIdSelectStatusCode != null) {
          request.response.statusCode = ownerIdSelectStatusCode!;
          request.response.write(ownerIdSelectBody ?? '');
        } else if (ownerIdSelectBody != null) {
          request.response.write(ownerIdSelectBody);
        } else {
          request.response.write(
            jsonEncode([
              for (final row in visible) {'owner_id': row.ownerId},
            ]),
          );
        }
      } else {
        request.response.write(
          jsonEncode([
            for (final row in visible) {'payload': row.payload},
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
      final identityId = row['identity_id'] as String?;
      final ownerId = row['owner_id'] as String? ?? userId;
      if (identityId != null &&
          ownerId != null &&
          userId != null &&
          ownerId != userId) {
        request.response.statusCode = 403;
        request.response.write('{}');
      } else if (identityId != null && _rowByIdentity(identityId) != null) {
        request.response.statusCode = 409;
        request.response.write('{}');
      } else if (identityId != null && ownerId != null) {
        profileRows.add(
          _ProfileRow(
            identityId: identityId,
            ownerId: ownerId,
            payload: Map<String, dynamic>.from(
              row['payload'] as Map? ?? {},
            ),
            recoveryCode: row['recovery_code'] as String? ?? '',
          ),
        );
        request.response.statusCode = 201;
        request.response.write('[]');
      } else {
        request.response.statusCode = 400;
        request.response.write('{}');
      }
    } else if (path == '/rest/v1/profiles' && request.method == 'PATCH') {
      final identityEq = request.uri.queryParameters['identity_id'];
      if (identityEq != null && identityEq.startsWith('eq.')) {
        final id = identityEq.substring(3);
        final row = _rowByIdentity(id);
        if (row != null && userId != null && row.visibleTo(userId)) {
          final body = await utf8.decoder.bind(request).join();
          final decoded = jsonDecode(body);
          if (decoded is Map && decoded['payload'] is Map) {
            row.payload = Map<String, dynamic>.from(decoded['payload'] as Map);
          }
        }
      }
      request.response.statusCode = 200;
      request.response.write('[]');
    } else if (path == '/rest/v1/profile_members' && request.method == 'POST') {
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final identityId = decoded['identity_id'] as String?;
        final memberId = decoded['user_id'] as String? ?? userId;
        final row = identityId != null ? _rowByIdentity(identityId) : null;
        if (row == null ||
            userId == null ||
            memberId == null ||
            row.ownerId != userId ||
            memberId != userId) {
          request.response.statusCode = 403;
          request.response.write('{}');
          await request.response.close();
          return;
        }
        row.members.add(memberId);
      }
      request.response.statusCode = 201;
      request.response.write('[]');
    } else if (path == '/rest/v1/profiles' && request.method == 'DELETE') {
      if (onBeforeDelete != null) {
        await onBeforeDelete!();
      }
      deleteCount += 1;
      lastDeleteUri = request.uri;
      lastDeletePrefer = request.headers.value('prefer');
      final idFilter = request.uri.queryParameters['identity_id'];
      final identityId = idFilter?.replaceFirst('eq.', '');
      final row = identityId != null ? _rowByIdentity(identityId) : null;
      final canDelete =
          row != null && userId != null && row.ownerId == userId;
      if (!deleteReturnsEmpty && canDelete) {
        profileRows.remove(row);
        request.response.statusCode = 200;
        request.response.write(
          jsonEncode([
            {'identity_id': identityId},
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
      if (claimStatusCode >= 200 && claimStatusCode < 300) {
        final body = await utf8.decoder.bind(request).join();
        final decoded = jsonDecode(body);
        final code = decoded is Map ? decoded['p_code'] as String? : null;
        _ProfileRow? match;
        if (code != null) {
          for (final row in profileRows) {
            if (row.recoveryCode == code.trim()) {
              match = row;
              break;
            }
          }
        }
        if (match != null && userId != null) {
          match.members.add(userId);
          request.response.write(jsonEncode(match.payload));
        } else {
          request.response.write('null');
        }
      } else {
        request.response.write('null');
      }
    } else {
      request.response.statusCode = 404;
    }
    await request.response.close();
  }
}
