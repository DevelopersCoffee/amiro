/// Allowlist-based crash payload shaping for upload (see `test/fixtures/crash_allowlist_golden.json`).
library;

const int crashMessagePreTruncate = 2048;
const int crashStackPreTruncate = 8192;
const int crashMessageFinalMax = 300;
const int crashStackFinalMax = 8000;

final RegExp _jwtPattern = RegExp(
  r'eyJ[A-Za-z0-9_-]{1,2000}\.[A-Za-z0-9_-]{1,2000}\.[A-Za-z0-9_-]{1,2000}',
);
final RegExp _bearerPattern = RegExp(r'Bearer\s+\S{1,500}');
final RegExp _uuidPattern = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);
/// Amiro identity ids, recovery codes, and similar 32-char secrets.
final RegExp _hex32Pattern = RegExp(
  r'(?<![0-9a-fA-F])[0-9a-fA-F]{32}(?![0-9a-fA-F])',
);
final RegExp _googlePlayPurchaseTokenPattern = RegExp(
  r'GPA\.[0-9A-Za-z\-]{12,200}',
);
final RegExp _hexPattern = RegExp(r'(?<![\w/])[0-9a-fA-F]{16,128}(?![\w/])');
final RegExp _base64Pattern = RegExp(r'[A-Za-z0-9+/]{20,}={0,2}');
final RegExp _sharePathTokenPattern = RegExp(r'(?<=/u/)[A-Za-z0-9_-]{10,}');
final RegExp _emailPattern = RegExp(
  r'[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9.-]{1,253}\.[a-zA-Z]{2,24}',
);
final RegExp _phonePattern = RegExp(
  r'\+?[0-9][0-9\s\-().]{6,24}[0-9]',
);
final RegExp _unixPathPattern = RegExp(
  r'(?:^|[\s(])(/[\w./\-]{1,200})',
);
final RegExp _dartFramePattern = RegExp(
  r'^#\d+\s+\S.* \((package:[a-z0-9_]+/|dart:[a-z_]+)[\w/.-]*:\d+(:\d+)?\)$',
);

String truncateCrashText(String input, int maxChars) {
  if (input.length <= maxChars) return input;
  return input.substring(0, maxChars);
}

String redactCrashSecrets(String input) {
  var text = input;
  text = text.replaceAll(_jwtPattern, '[redacted-jwt]');
  text = text.replaceAll(_bearerPattern, '[redacted-bearer]');
  text = text.replaceAll(_uuidPattern, '[redacted-uuid]');
  text = text.replaceAll(_sharePathTokenPattern, '[redacted-base64url]');
  text = text.replaceAll(
    _googlePlayPurchaseTokenPattern,
    '[redacted-play-purchase]',
  );
  text = text.replaceAll(_hex32Pattern, '[redacted-hex32]');
  text = text.replaceAll(_emailPattern, '[redacted-email]');
  text = text.replaceAll(_phonePattern, '[redacted-phone]');
  text = text.replaceAllMapped(
    _unixPathPattern,
    (m) => m.group(0)!.replaceFirst(m.group(1)!, '[redacted-path]'),
  );
  text = text.replaceAll(_hexPattern, '[redacted-hex]');
  text = text.replaceAll(_base64Pattern, '[redacted-base64]');
  return text;
}

String filterDartStackFrames(String stack) {
  final kept = <String>[];
  for (final line in stack.split('\n')) {
    final trimmed = line.trimRight();
    if (trimmed.isEmpty) continue;
    if (_dartFramePattern.hasMatch(trimmed)) {
      kept.add(trimmed);
    }
  }
  return kept.join('\n');
}

String prepareCrashMessage(String runtimeType, String rawMessage) {
  var body = rawMessage;
  final prefix = '$runtimeType: ';
  if (body.startsWith(prefix)) {
    body = body.substring(prefix.length);
  }
  body = truncateCrashText(body, crashMessagePreTruncate);
  body = redactCrashSecrets(body);
  body = truncateCrashText(body, crashMessageFinalMax);
  final withType = '$runtimeType: $body';
  return truncateCrashText(withType, crashMessageFinalMax);
}

String prepareCrashStack(String rawStack) {
  var stack = truncateCrashText(rawStack, crashStackPreTruncate);
  stack = filterDartStackFrames(stack);
  return truncateCrashText(stack, crashStackFinalMax);
}

Map<String, Object?> scrubCrashReport(Map<String, Object?> report) {
  final runtimeType =
      report['runtimeType'] as String? ?? report['errorType'] as String? ?? 'Error';
  final rawMessage = report['message'];
  final rawStack = report['stack'];
  final messageStr =
      rawMessage is String ? rawMessage : rawMessage?.toString() ?? '';
  final stackStr = rawStack is String ? rawStack : '';

  return {
  ...report,
    'message': prepareCrashMessage(runtimeType, messageStr),
    'stack': prepareCrashStack(stackStr),
  };
}

String crashFingerprint(Object error, StackTrace stack) {
  final type = error.runtimeType.toString();
  final frames = filterDartStackFrames(stack.toString());
  final top = frames.split('\n').firstWhere((l) => l.isNotEmpty, orElse: () => '');
  return '$type|$top';
}