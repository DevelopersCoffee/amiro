/// Limits crash uploads to avoid tight-loop POST storms when opted in.
class CrashUploadThrottle {
  CrashUploadThrottle({
    this.maxPerSession = 5,
    this.maxPerDay = 20,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxPerSession;
  final int maxPerDay;
  final DateTime Function() _clock;

  int _sessionCount = 0;
  int _dailyCount = 0;
  String? _dayKey;
  final Set<String> _fingerprints = {};

  void _rollDay() {
    final now = _clock().toUtc();
    final key = '${now.year}-${now.month}-${now.day}';
    if (_dayKey != key) {
      _dayKey = key;
      _dailyCount = 0;
    }
  }

  bool shouldUpload(String fingerprint) {
    _rollDay();
    if (_sessionCount >= maxPerSession) return false;
    if (_dailyCount >= maxPerDay) return false;
    if (_fingerprints.contains(fingerprint)) return false;
    return true;
  }

  void recordUpload(String fingerprint) {
    _rollDay();
    _sessionCount += 1;
    _dailyCount += 1;
    _fingerprints.add(fingerprint);
  }

  void reset() {
    _sessionCount = 0;
    _dailyCount = 0;
    _dayKey = null;
    _fingerprints.clear();
  }
}