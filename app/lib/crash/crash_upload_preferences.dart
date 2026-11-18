import 'dart:convert';
import 'dart:io';

/// Whether the user opted in to sending scrubbed crash reports (default off).
class CrashUploadPreferences {
  CrashUploadPreferences(this._file);

  final File _file;

  factory CrashUploadPreferences.inDirectory(Directory directory) {
    return CrashUploadPreferences(
      File('${directory.path}/crash_upload_opt_in.json'),
    );
  }

  /// Opt-in state held in memory (widget tests).
  factory CrashUploadPreferences.inMemory({bool enabled = false}) {
    return _InMemoryCrashUploadPreferences(enabled);
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
    if (_file.path.isEmpty) return;
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode({'enabled': enabled}));
    await tmp.rename(_file.path);
  }
}

class _InMemoryCrashUploadPreferences extends CrashUploadPreferences {
  _InMemoryCrashUploadPreferences(this._enabled) : super(File(''));

  bool _enabled;

  @override
  Future<bool> isEnabled() async => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }
}