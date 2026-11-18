import 'dart:convert';
import 'dart:io';

import 'package:amiro_app/identity/cloud_backup_preferences.dart';
import 'package:amiro_app/identity/profile_secrets_store.dart';
import 'package:amiro_app/identity/supabase_profile_cloud.dart';
import 'package:amiro_app/sharing/encounter_share_options.dart';
import 'package:amiro_app/sharing/supabase_web_share_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

class _RpcHarness extends SupabaseProfileCloud {
  _RpcHarness()
      : super(
          directory: Directory.systemTemp,
          projectUrl: Uri.parse('https://example.supabase.co'),
          anonKey: 'anon',
          backupPreferences: CloudBackupPreferences.inMemory(),
          secrets: ProfileSecretsStore(legacyDirectory: Directory.systemTemp),
        );

  final List<Map<String, String>> headers = [];

  @override
  bool get supportsRestore => true;

  @override
  Future<({String accessToken, String userId})> userSessionForDataPlane() async {
    return (accessToken: 'token', userId: 'user-1');
  }

  @override
  Future<({int status, String body})> sendAuthenticated({
    required String method,
    required Uri uri,
    String? body,
    required String accessToken,
    Map<String, String> extraHeaders = const {},
  }) async {
    headers.add(extraHeaders);
    if (uri.path.endsWith('/rpc/web_share_revoke')) {
      return (status: 204, body: '');
    }
    if (uri.path.endsWith('/rpc/web_share_rotate')) {
      return (
        status: 200,
        body: jsonEncode({'token': 'newtokenabcdefghijklmnopqrstuv'}),
      );
    }
    return (
      status: 200,
      body: jsonEncode({'token': 'abcdefghijklmnopqrstuvwxy'}),
    );
  }
}

Identity _identity() =>
    const Identity(id: 'id-1', displayName: 'Ada', username: 'ada');

void main() {
  test('parseWebShareRpcToken rejects 204 empty body', () {
    expect(parseWebShareRpcToken(204, ''), isNull);
  });

  test('parseWebShareRpcToken reads token from RPC row', () {
    final token = parseWebShareRpcToken(
      200,
      jsonEncode({'token': 'abcdefghijklmnopqrstuvwxy'}),
    );
    expect(token, 'abcdefghijklmnopqrstuvwxy');
  });

  test('rotate uses web_share_rotate RPC with return=representation', () async {
    final harness = _RpcHarness();
    final client = SupabaseWebShareClient(harness);
    final result = await client.rotate(
      identity: _identity(),
      definition: null,
      purchasedIds: const {},
      shareOptions: const EncounterShareOptions(),
      existingToken: 'oldtokenabcdefghijklmnopqrst',
    );
    expect(result.ok, isTrue);
    expect(harness.headers.single['Prefer'], 'return=representation');
  });

  test('revoke fails when RPC returns 204', () async {
    final harness = _RpcHarness();
    final client = SupabaseWebShareClient(harness);
    final ok = await client.revoke(token: 'abcdefghijklmnopqrstuvwxy');
    expect(ok, isFalse);
  });

  test('buildWebShareRpcBody includes rotate token when set', () {
    final body = buildWebShareRpcBody(
      identityId: 'id-1',
      displayName: 'Ada',
      publicContact: const {'bio': 'hi'},
      cardExtras: const {},
      avatarHex: '\\x89504e47',
      oldToken: 'oldt',
    );
    expect(body['p_old_token'], 'oldt');
  });
}