import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:identity_core/identity_core.dart';

import 'cloud_backup_preferences.dart';
import 'profile_cloud.dart';
import 'profile_secrets_store.dart';

/// Anonymous Supabase session plus the profile row it is allowed to read.
///
/// The anon key is public. Row access is the signed-in user's token, checked
/// by row level security. The service-role key stays on the webhook worker.
class SupabaseProfileCloud implements ProfileCloud {
  SupabaseProfileCloud({
    required this.directory,
    required this.projectUrl,
    required this.anonKey,
    required this.backupPreferences,
    required this.secrets,
    Random? random,
  }) : _random = random ?? Random.secure();

  final Directory directory;
  final Uri projectUrl;
  final String anonKey;
  final CloudBackupPreferences backupPreferences;
  final ProfileSecretsStore secrets;
  final Random _random;

  @override
  bool get supportsRestore => anonKey.isNotEmpty;

  @override
  Future<String?> recoveryCode() async {
    final code = await secrets.readRecoveryCode();
    if (code == null || code.isEmpty) return null;
    return code.trim();
  }

  @override
  Future<bool> push(Identity identity) async {
    if (!supportsRestore || !await backupPreferences.isEnabled()) {
      return false;
    }
    try {
      final session = await _ensureSession();
      final code = await recoveryCode() ?? await _newCode();
      final payload = identityToCloudPayload(identity);
      final existing = await _selectPayloads(session);
      if (existing.isEmpty) {
        final inserted = await _insertProfile(
          session: session,
          identity: identity,
          code: code,
          payload: payload,
        );
        if (!inserted) {
          final joined = await _insertMember(session, identity.id);
          if (!joined) return false;
          final updated = await _updateProfile(
            session: session,
            identityId: identity.id,
            payload: payload,
          );
          return updated;
        }
        final member = await _insertMember(session, identity.id);
        if (!member) return false;
      } else {
        final updated = await _updateProfile(
          session: session,
          identityId: identity.id,
          payload: payload,
        );
        if (!updated) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Identity?> pull() async {
    if (!supportsRestore) return null;
    try {
      final sessionRaw = await secrets.readSessionJson();
      if (sessionRaw == null) return null;
      final session = await _ensureSession();
      final rows = await _selectPayloads(session);
      if (rows.isEmpty) return null;
      return identityFromCloudPayload(rows.first);
    } catch (_) {
      return null;
    }
  }

  static const _revokeZeroRowsMessage =
      'Only the device that created the backup can remove the cloud copy, '
      'or the copy was already removed.';

  @override
  Future<RevokeBackupResult> revokeBackup({String? identityId}) async {
    if (!supportsRestore) return const RevokeBackupResult.ok();
    try {
      final session = await _ensureSession();
      final id = identityId ?? await _primaryIdentityId(session);
      if (id != null) {
        final response = await _send(
          method: 'DELETE',
          uri: _rest('profiles').replace(
            queryParameters: {'identity_id': 'eq.$id'},
          ),
          headers: {
            ..._userHeaders(session),
            'Prefer': 'return=representation',
          },
        );
        final deletedCount = _deletedRowCount(response);
        if (response.status >= 200 &&
            response.status < 300 &&
            deletedCount > 0) {
          await secrets.clearCloudBackupCredentials();
          return const RevokeBackupResult.ok();
        }
        if (response.status < 200 || response.status >= 300) {
          return const RevokeBackupResult.failed();
        }
        // Zero rows: re-select below — row may still exist (member device).
      }
      final visible = await _selectPayloads(session);
      if (visible.isEmpty) {
        await secrets.clearCloudBackupCredentials();
        return const RevokeBackupResult.ok();
      }
      return const RevokeBackupResult.failed(_revokeZeroRowsMessage);
    } catch (_) {
      return const RevokeBackupResult.failed();
    }
  }

  int _deletedRowCount(({int status, String body}) response) {
    if (response.body.isEmpty) return 0;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded.length;
    } catch (_) {}
    return 0;
  }

  Future<String?> _primaryIdentityId(_Session session) async {
    final response = await _send(
      method: 'GET',
      uri: _rest('profiles').replace(
        queryParameters: {'select': 'identity_id', 'limit': '1'},
      ),
      headers: _userHeaders(session),
    );
    if (response.status < 200 || response.status >= 300) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) return null;
    final row = decoded.first;
    if (row is Map && row['identity_id'] is String) {
      return row['identity_id'] as String;
    }
    return null;
  }

  @override
  Future<Identity?> claim(String code) async {
    final trimmed = code.trim();
    if (!supportsRestore || trimmed.length < 16) return null;
    try {
      final session = await _ensureSession();
      final response = await _send(
        method: 'POST',
        uri: _rest('rpc/join_profile'),
        headers: _userHeaders(session),
        body: jsonEncode({'p_code': trimmed}),
      );
      if (_isTransientHttpStatus(response.status)) {
        throw SessionRefreshFailure(response.status);
      }
      if (response.status < 200 || response.status >= 300) return null;
      if (response.body.isEmpty || response.body == 'null') return null;
      final identity = identityFromCloudPayload(jsonDecode(response.body));
      if (identity == null) return null;
      await secrets.writeRecoveryCode(trimmed);
      return identity;
    } on SessionRefreshFailure {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  static bool _isTransientHttpStatus(int status) {
    if (status >= 500) return true;
    return status == 408 || status == 429;
  }

  Future<bool> _insertProfile({
    required _Session session,
    required Identity identity,
    required String code,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _send(
      method: 'POST',
      uri: _rest('profiles'),
      headers: _userHeaders(session),
      body: jsonEncode({
        'identity_id': identity.id,
        'owner_id': session.userId,
        'payload': payload,
        'recovery_code': code,
      }),
    );
    if (response.status < 200 || response.status >= 300) return false;
    await secrets.writeRecoveryCode(code);
    return true;
  }

  Future<bool> _insertMember(_Session session, String identityId) async {
    final response = await _send(
      method: 'POST',
      uri: _rest('profile_members'),
      headers: _userHeaders(session),
      body: jsonEncode({
        'identity_id': identityId,
        'user_id': session.userId,
      }),
    );
    return (response.status >= 200 && response.status < 300) ||
        response.status == 409;
  }

  Future<bool> _updateProfile({
    required _Session session,
    required String identityId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _send(
      method: 'PATCH',
      uri: _rest('profiles').replace(
        queryParameters: {'identity_id': 'eq.$identityId'},
      ),
      headers: _userHeaders(session),
      body: jsonEncode({
        'payload': payload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return response.status >= 200 && response.status < 300;
  }

  Future<List<Object?>> _selectPayloads(_Session session) async {
    final response = await _send(
      method: 'GET',
      uri: _rest('profiles').replace(queryParameters: {'select': 'payload'}),
      headers: _userHeaders(session),
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('profile read failed');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return [
      for (final row in decoded)
        if (row is Map && row['payload'] != null) row['payload'],
    ];
  }

  Future<String> _newCode() async {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uri _rest(String path) => projectUrl.replace(path: '/rest/v1/$path');

  Map<String, String> _anonHeaders() => {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
  };

  Map<String, String> _userHeaders(_Session session) => {
    'apikey': anonKey,
    'Authorization': 'Bearer ${session.accessToken}',
  };

  Future<_Session> _ensureSession() async {
    if (await secrets.hasLegacyPlaintextFiles()) {
      await secrets.migrateFromLegacyPlaintext();
    }
    final existing = await _readSession();
    final freshUntil = DateTime.now().add(const Duration(minutes: 1));
    if (existing != null && existing.expiresAt.isAfter(freshUntil)) {
      return existing;
    }
    if (existing != null) {
      try {
        final refreshed = await _refresh(existing.refreshToken);
        await _writeSession(refreshed);
        return refreshed;
      } on SessionRefreshFailure catch (e) {
        if (!e.isAuthFailure) {
          rethrow;
        }
        // A dead refresh token starts a new anonymous user. The recovery
        // code still joins the old profile.
      }
    }
    final created = await _signInAnonymously();
    await _writeSession(created);
    return created;
  }

  Future<_Session> _signInAnonymously() async {
    final response = await _send(
      method: 'POST',
      uri: projectUrl.replace(path: '/auth/v1/signup'),
      headers: _anonHeaders(),
      body: jsonEncode({'data': <String, dynamic>{}}),
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError('anonymous sign-in failed');
    }
    final session = _sessionFromJson(jsonDecode(response.body));
    if (session == null) throw StateError('anonymous sign-in failed');
    return session;
  }

  Future<_Session> _refresh(String refreshToken) async {
    final response = await _send(
      method: 'POST',
      uri: projectUrl.replace(
        path: '/auth/v1/token',
        queryParameters: {'grant_type': 'refresh_token'},
      ),
      headers: _anonHeaders(),
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    if (response.status < 200 || response.status >= 300) {
      throw SessionRefreshFailure(response.status);
    }
    final session = _sessionFromJson(jsonDecode(response.body));
    if (session == null) {
      throw SessionRefreshFailure(response.status);
    }
    return session;
  }

  _Session? _sessionFromJson(Object? decoded) {
    if (decoded is! Map) return null;
    final json = Map<String, dynamic>.from(decoded);
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    final user = json['user'];
    if (access is! String || refresh is! String || user is! Map) return null;
    final userId = user['id'];
    if (userId is! String) return null;
    final expiresIn = json['expires_in'];
    final seconds = expiresIn is int ? expiresIn : 3600;
    return _Session(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
    );
  }

  Future<_Session?> _readSession() async {
    final raw = await secrets.readSessionJson();
    final decoded = sessionJsonFromStored(raw);
    if (decoded == null) return null;
    final access = decoded['access_token'];
    final refresh = decoded['refresh_token'];
    final userId = decoded['user_id'];
    final expires = decoded['expires_at'];
    if (access is! String || refresh is! String || userId is! String) {
      return null;
    }
    return _Session(
      accessToken: access,
      refreshToken: refresh,
      userId: userId,
      expiresAt: expires is String
          ? DateTime.tryParse(expires) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Future<void> _writeSession(_Session session) async {
    await secrets.writeSessionJson(
      jsonEncode({
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken,
        'user_id': session.userId,
        'expires_at': session.expiresAt.toUtc().toIso8601String(),
      }),
    );
  }

  Future<({int status, String body})> _send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      headers.forEach(request.headers.set);
      if (body != null) request.write(body);
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final text = await response.transform(utf8.decoder).join();
      return (status: response.statusCode, body: text);
    } finally {
      client.close();
    }
  }
}

class _Session {
  const _Session({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final DateTime expiresAt;
}
