/// Limits crash uploads to avoid tight-loop POST storms when opted in.
/// Quota is consumed synchronously on each upload **attempt** (not on success).
class CrashUploadThrottle {
  CrashUploadThrottle({
    this.maxPerSession = 5,
    this.maxPerDay = 20,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxPerSession;
  final int maxPerDay;
  final DateTime Function() _clock;

  int _sessionAttempts = 0;
  int _dailyAttempts = 0;
  String? _dayKey;
  final Set<String> _fingerprints = {};

  void _rollDay() {
    final now = _clock().toUtc();
    final key = '${now.year}-${now.month}-${now.day}';
    if (_dayKey != key) {
      _dayKey = key;
      _dailyAttempts = 0;
    }
  }

  /// Synchronous gate: counts this attempt and returns false when over quota or duplicate.
  bool tryConsumeUploadQuota(String fingerprint) {
    _rollDay();
    if (_fingerprints.contains(fingerprint)) {
      return false;
    }
    if (_sessionAttempts >= maxPerSession) {
      return false;
    }
    if (_dailyAttempts >= maxPerDay) {
      return false;
    }
    _sessionAttempts += 1;
    _dailyAttempts += 1;
    _fingerprints.add(fingerprint);
    return true;
  }

  void reset() {
    _sessionAttempts = 0;
    _dailyAttempts = 0;
    _dayKey = null;
    _fingerprints.clear();
  }
}