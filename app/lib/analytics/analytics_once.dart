import 'dart:convert';
import 'dart:io';

/// Persists which once-per-install funnel events already fired locally.
class AnalyticsOnceStore {
  AnalyticsOnceStore(this._file);

  final File _file;

  factory AnalyticsOnceStore.inDirectory(Directory directory) {
    return AnalyticsOnceStore(
      File('${directory.path}/analytics_once.json'),
    );
  }

  factory AnalyticsOnceStore.inMemory([Set<String>? fired]) {
    return _InMemoryAnalyticsOnceStore(fired ?? {});
  }

  Future<bool> hasFired(String event) async {
    return (await _load()).contains(event);
  }

  Future<bool> markFired(String event) async {
    final set = await _load();
    if (set.contains(event)) return false;
    set.add(event);
    await _save(set);
    return true;
  }

  Future<Set<String>> _load() async {
    if (_file.path.isEmpty) return {};
    if (!await _file.exists()) return {};
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map && decoded['fired'] is List) {
        return (decoded['fired'] as List).map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    return {};
  }

  Future<void> _save(Set<String> fired) async {
    if (_file.path.isEmpty) return;
    await _file.parent.create(recursive: true);
    await _file.writeAsString(
      jsonEncode({'fired': fired.toList()..sort()}),
    );
  }
}

class _InMemoryAnalyticsOnceStore extends AnalyticsOnceStore {
  _InMemoryAnalyticsOnceStore(this._fired) : super(File(''));

  Set<String> _fired;

  @override
  Future<bool> hasFired(String event) async => _fired.contains(event);

  @override
  Future<bool> markFired(String event) async {
    if (_fired.contains(event)) return false;
    _fired = {..._fired, event};
    return true;
  }
}