import 'dart:convert';
import 'dart:io';

/// Whether the user opted in to minimal product analytics (default off).
class AnalyticsPreferences {
  AnalyticsPreferences(this._file);

  final File _file;

  factory AnalyticsPreferences.inDirectory(Directory directory) {
    return AnalyticsPreferences(
      File('${directory.path}/analytics_opt_in.json'),
    );
  }

  factory AnalyticsPreferences.inMemory({bool enabled = false}) {
    return _InMemoryAnalyticsPreferences(enabled);
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
    await _file.writeAsString(jsonEncode({'enabled': enabled}));
  }
}

class _InMemoryAnalyticsPreferences extends AnalyticsPreferences {
  _InMemoryAnalyticsPreferences(this._enabled) : super(File(''));

  bool _enabled;

  @override
  Future<bool> isEnabled() async => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
  }
}