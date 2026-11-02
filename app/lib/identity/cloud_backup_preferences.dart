import 'dart:convert';
import 'dart:io';

/// Whether the user opted in to Supabase profile backup (default off).
class CloudBackupPreferences {
  CloudBackupPreferences(this._file);

  final File _file;

  factory CloudBackupPreferences.inDirectory(Directory directory) {
    return CloudBackupPreferences(
      File('${directory.path}/cloud_backup_opt_in.json'),
    );
  }

  Future<bool> isEnabled() async {
    if (!await _file.exists()) return false;
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map && decoded['enabled'] is bool) {
        return decoded['enabled'] as bool;
      }
    } catch (_) {}
    return false;
  }

  Future<void> setEnabled(bool enabled) async {
    await _file.writeAsString(jsonEncode({'enabled': enabled}));
  }
}
