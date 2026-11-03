import 'dart:convert';
import 'dart:io';

import 'secret_storage.dart';

/// Supabase session tokens and the profile recovery code — never Auto Backup.
class ProfileSecretsStore {
  ProfileSecretsStore({
    required this.legacyDirectory,
    SecretStorage? secureStorage,
  }) : _secure = secureStorage ?? FlutterSecretStorage();

  final Directory legacyDirectory;
  final SecretStorage _secure;

  static const _sessionKey = 'supabase_session_json';
  static const _recoveryCodeKey = 'profile_recovery_code';

  File get _legacySessionFile =>
      File('${legacyDirectory.path}/supabase_session.json');
  File get _legacyCodeFile =>
      File('${legacyDirectory.path}/profile_recovery_code.txt');

  Future<bool> hasLegacyPlaintextFiles() async {
    if (await _legacySessionFile.exists()) return true;
    if (await _legacyCodeFile.exists()) return true;
    return false;
  }

  Future<void> migrateFromLegacyPlaintext() async {
    if (!await hasLegacyPlaintextFiles()) return;

    if (await _legacySessionFile.exists()) {
      if (await _secure.read(_sessionKey) == null) {
        final raw = await _legacySessionFile.readAsString();
        if (raw.trim().isNotEmpty) {
          await _secure.write(_sessionKey, raw);
          await _legacySessionFile.delete();
        }
      } else {
        await _legacySessionFile.delete();
      }
    }
    if (await _legacyCodeFile.exists()) {
      if (await _secure.read(_recoveryCodeKey) == null) {
        final code = (await _legacyCodeFile.readAsString()).trim();
        if (code.isNotEmpty) {
          await _secure.write(_recoveryCodeKey, code);
          await _legacyCodeFile.delete();
        }
      } else {
        await _legacyCodeFile.delete();
      }
    }
  }

  /// Clears Supabase session and recovery code after a successful cloud revoke.
  Future<void> clearCloudBackupCredentials() async {
    await _secure.delete(_sessionKey);
    await _secure.delete(_recoveryCodeKey);
    if (await _legacySessionFile.exists()) {
      await _legacySessionFile.delete();
    }
    if (await _legacyCodeFile.exists()) {
      await _legacyCodeFile.delete();
    }
  }

  Future<String?> readSessionJson() async {
    if (await _legacySessionFile.exists()) {
      await migrateFromLegacyPlaintext();
    }
    return _secure.read(_sessionKey);
  }

  Future<void> writeSessionJson(String json) async {
    await _secure.write(_sessionKey, json);
    if (await _legacySessionFile.exists()) {
      await _legacySessionFile.delete();
    }
  }

  Future<String?> readRecoveryCode() async {
    if (await _legacyCodeFile.exists()) {
      await migrateFromLegacyPlaintext();
    }
    return _secure.read(_recoveryCodeKey);
  }

  Future<void> writeRecoveryCode(String code) async {
    await _secure.write(_recoveryCodeKey, code);
    if (await _legacyCodeFile.exists()) {
      await _legacyCodeFile.delete();
    }
  }
}

/// Parses session JSON written by [ProfileSecretsStore].
Map<String, dynamic>? sessionJsonFromStored(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

/// Runs legacy migration with a timeout; failures are ignored so startup continues.
Future<void> runProfileSecretsMigrationSafely(
  ProfileSecretsStore store, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (!await store.hasLegacyPlaintextFiles()) return;
  try {
    await store.migrateFromLegacyPlaintext().timeout(timeout);
  } catch (_) {}
}
