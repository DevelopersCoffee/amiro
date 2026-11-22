import 'dart:convert';
import 'dart:io';

/// Persists per-day upload attempt counts across process restarts.
class CrashUploadThrottleStore {
  CrashUploadThrottleStore(this._file);

  final File _file;

  factory CrashUploadThrottleStore.inDirectory(Directory directory) {
    return CrashUploadThrottleStore(
      File('${directory.path}/crash_upload_throttle_state.json'),
    );
  }

  /// Ephemeral store for widget/unit tests (no disk I/O).
  factory CrashUploadThrottleStore.ephemeral() {
    return _EphemeralCrashUploadThrottleStore();
  }

  (String? dayKey, int dailyCount) loadSync() {
    if (_file.path.isEmpty || !_file.existsSync()) {
      return (null, 0);
    }
    try {
      final decoded = jsonDecode(_file.readAsStringSync());
      if (decoded is Map) {
        final day = decoded['dayKey'];
        final count = decoded['dailyCount'];
        if (day is String && count is int && count >= 0) {
          return (day, count);
        }
      }
    } catch (_) {}
    return (null, 0);
  }

  /// Persists the daily attempt count to disk.
  ///
  /// Runs on the crash path; filesystem exceptions are caught and swallowed so
  /// the crash reporter itself never throws during active error handling.
  void saveSync(String dayKey, int dailyCount) {
    if (_file.path.isEmpty) return;
    try {
      _file.parent.createSync(recursive: true);
      final tmp = File('${_file.path}.tmp');
      tmp.writeAsStringSync(
        jsonEncode({'dayKey': dayKey, 'dailyCount': dailyCount}),
      );
      tmp.renameSync(_file.path);
    } catch (_) {
      // Fails closed if store write fails; slot remains counted in-memory.
    }
  }
}

class _EphemeralCrashUploadThrottleStore extends CrashUploadThrottleStore {
  _EphemeralCrashUploadThrottleStore() : super(File(''));

  String? _dayKey;
  int _dailyCount = 0;

  @override
  (String? dayKey, int dailyCount) loadSync() => (_dayKey, _dailyCount);

  @override
  void saveSync(String dayKey, int dailyCount) {
    _dayKey = dayKey;
    _dailyCount = dailyCount;
  }
}
