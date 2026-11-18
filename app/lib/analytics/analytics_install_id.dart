import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Install-scoped pseudonymous id for analytics de-duplication.
///
/// Regenerated when analytics consent is turned off. Not linked to identity or
/// RevenueCat ids.
class AnalyticsInstallIdStore {
  AnalyticsInstallIdStore(this._file);

  final File _file;
  static final _random = Random.secure();

  factory AnalyticsInstallIdStore.inDirectory(Directory directory) {
    return AnalyticsInstallIdStore(
      File('${directory.path}/analytics_install_id.json'),
    );
  }

  factory AnalyticsInstallIdStore.inMemory({String? id}) {
    return _InMemoryAnalyticsInstallIdStore(id);
  }

  Future<String> currentOrCreate() async {
    final existing = await _readId();
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _newId();
    await _writeId(id);
    return id;
  }

  Future<void> regenerate() async {
    await _writeId(_newId());
  }

  Future<void> clear() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }

  Future<String?> _readId() async {
    if (_file.path.isNotEmpty && await _file.exists()) {
      try {
        final decoded = jsonDecode(await _file.readAsString());
        if (decoded is Map && decoded['id'] is String) {
          return decoded['id'] as String;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> _writeId(String id) async {
    if (_file.path.isEmpty) return;
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode({'id': id}));
  }

  static String _newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20, 32)}';
  }
}

class _InMemoryAnalyticsInstallIdStore extends AnalyticsInstallIdStore {
  _InMemoryAnalyticsInstallIdStore(this._id) : super(File(''));

  String? _id;

  @override
  Future<String> currentOrCreate() async {
    _id ??= AnalyticsInstallIdStore._newId();
    return _id!;
  }

  @override
  Future<void> regenerate() async {
    _id = AnalyticsInstallIdStore._newId();
  }

  @override
  Future<void> clear() async {
    _id = null;
  }
}