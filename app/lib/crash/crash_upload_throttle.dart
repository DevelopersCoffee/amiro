import 'crash_upload_throttle_store.dart';

/// Limits crash uploads to avoid tight-loop POST storms when opted in.
///
/// [tryReserveUploadSlot] reserves quota synchronously before any network I/O.
/// Failed uploads still count toward session/daily caps. Duplicate fingerprints
/// do not consume additional slots.
class CrashUploadThrottle {
  CrashUploadThrottle({
    this.maxPerSession = 5,
    this.maxPerDay = 20,
    CrashUploadThrottleStore? store,
    DateTime Function()? clock,
  })  : _store = store ?? CrashUploadThrottleStore.ephemeral(),
        _clock = clock ?? DateTime.now {
    _rehydrateDaily();
  }

  final int maxPerSession;
  final int maxPerDay;
  final CrashUploadThrottleStore _store;
  final DateTime Function() _clock;

  int _sessionCount = 0;
  int _dailyCount = 0;
  String? _dayKey;
  final Set<String> _fingerprints = {};

  void _rehydrateDaily() {
    final (persistedDay, persistedCount) = _store.loadSync();
    final today = _currentDayKey();
    if (persistedDay == today && persistedCount >= 0) {
      _dayKey = persistedDay;
      _dailyCount = persistedCount;
    }
  }

  String _currentDayKey() {
    final now = _clock().toUtc();
    return '${now.year}-${now.month}-${now.day}';
  }

  void _rollDay() {
    final key = _currentDayKey();
    if (_dayKey != key) {
      _dayKey = key;
      _dailyCount = 0;
    }
  }

  /// Reserves one upload attempt slot when under caps and not a duplicate fp.
  bool tryReserveUploadSlot(String fingerprint) {
    _rollDay();
    if (_fingerprints.contains(fingerprint)) return false;
    if (_sessionCount >= maxPerSession) return false;
    if (_dailyCount >= maxPerDay) return false;
    _sessionCount += 1;
    _dailyCount += 1;
    _fingerprints.add(fingerprint);
    try {
      _store.saveSync(_dayKey!, _dailyCount);
    } catch (_) {
      // Fails closed if store write fails; slot remains counted in-memory.
    }
    return true;
  }

  void reset() {
    _sessionCount = 0;
    _dailyCount = 0;
    _dayKey = null;
    _fingerprints.clear();
    try {
      _store.saveSync(_currentDayKey(), 0);
    } catch (_) {}
  }
}
