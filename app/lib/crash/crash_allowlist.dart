/// Allowlist-based crash payload shaping for upload (see `test/fixtures/crash_allowlist_golden.json`).
library;

const int crashMessagePreTruncate = 2048;
const int crashStackPreTruncate = 8192;
const int crashMessageFinalMax = 300;
const int crashStackFinalMax = 8000;
const int crashRuntimeTypeMax = 120;

final RegExp _jwtPattern = RegExp(
  r'eyJ[A-Za-z0-9_-]{1,2000}\.[A-Za-z0-9_-]{1,2000}\.[A-Za-z0-9_-]{1,2000}',
);
final RegExp _bearerPattern = RegExp(r'Bearer\s+\S{1,500}');
final RegExp _uuidPattern = RegExp(
  r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
);
final RegExp _httpUrlPattern = RegExp(
  r'''https?://(?:[^\s"'<>]|'[^']*'|"[^"]*")+''',
);
final RegExp _fileUrlPattern = RegExp(r'file://[^\s"<>]+');
final RegExp _winPathPattern = RegExp(
  r'(?:^|[\s(])([A-Za-z]:\\[^\s"<>]+)',
);
/// Amiro identity ids, recovery codes, and similar 32-char secrets.
final RegExp _hex32Pattern = RegExp(
  r'(?<![0-9a-fA-F])[0-9a-fA-F]{32}(?![0-9a-fA-F])',
);
final RegExp _googlePlayOrderIdPattern = RegExp(
  r'GPA\.[0-9A-Za-z\-_]{12,200}',
);
final RegExp _purchaseTokenKeyValuePattern = RegExp(
  r'''\b(purchase[_-]?token|token)["']?\s*[=:\s]\s*['"]?([A-Za-z0-9._\-+/=]+)''',
  caseSensitive: false,
);
final RegExp _hexPattern = RegExp(r'(?<![\w/])[0-9a-fA-F]{16,128}(?![\w/])');
final RegExp _base64Pattern = RegExp(r'[A-Za-z0-9+/_\-]{20,}={0,2}');
final RegExp _sharePathTokenPattern = RegExp(r'(?<=/u/)[A-Za-z0-9_-]{10,}');
final RegExp _emailPattern = RegExp(
  r'[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9.-]{1,253}\.[a-zA-Z]{2,24}',
);
final RegExp _phonePattern = RegExp(
  r'\+?[0-9][0-9\s\-().]{6,24}[0-9]',
);
final RegExp _unixPathPattern = RegExp(
  r'''(?:^['"]?|[\s(]['"]?|[:=]\s*['"]?)(/[\p{L}\p{N}./\-_]{1,200})''',
  unicode: true,
);
final RegExp _dartRuntimeTypePattern = RegExp(
  r'^[A-Za-z_$][\w$<>, ]{0,119}$',
);
final RegExp _dartFramePattern = RegExp(
  r'^#\d+\s+\S.* \((package:[a-z0-9_]+/|dart:[a-z_]+)[\w/.-]*:\d+(:\d+)?\)$',
);

String truncateCrashText(String input, int maxChars) {
  if (input.length <= maxChars) return input;
  return input.substring(0, maxChars);
}

/// Caps length first, then validates Dart type syntax; invalid types become [Error].
String sanitizeCrashRuntimeType(String raw) {
  final capped = truncateCrashText(raw, crashRuntimeTypeMax);
  if (!_dartRuntimeTypePattern.hasMatch(capped)) {
    return 'Error';
  }
  if (redactCrashSecrets(capped) != capped) {
    return 'Error';
  }
  if (RegExp(r'\s').hasMatch(capped)) {
    final firstAngle = capped.indexOf('<');
    final lastAngle = capped.lastIndexOf('>');
    if (firstAngle == -1 || lastAngle == -1 || firstAngle >= lastAngle) {
      return 'Error';
    }
    final firstSpace = capped.indexOf(RegExp(r'\s'));
    final lastSpace = capped.lastIndexOf(RegExp(r'\s'));
    if (firstSpace < firstAngle || lastSpace > lastAngle) {
      return 'Error';
    }
    if (RegExp(r'(?<!,)\s').hasMatch(capped) ||
        RegExp(r',\s{2,}').hasMatch(capped)) {
      return 'Error';
    }
  }
  return capped;
}

String redactCrashSecrets(String input) {
  var text = input;
  text = text.replaceAll(_jwtPattern, '[redacted-jwt]');
  text = text.replaceAll(_bearerPattern, '[redacted-bearer]');
  text = text.replaceAll(_uuidPattern, '[redacted-uuid]');
  text = text.replaceAll(_httpUrlPattern, '[redacted-url]');
  text = text.replaceAll(_fileUrlPattern, '[redacted-path]');
  text = text.replaceAllMapped(
    _winPathPattern,
    (m) => m.group(0)!.replaceFirst(m.group(1)!, '[redacted-path]'),
  );
  text = text.replaceAll(_sharePathTokenPattern, '[redacted-base64url]');
  text = text.replaceAll(_googlePlayOrderIdPattern, '[redacted-play-purchase]');
  text = text.replaceAllMapped(
    _purchaseTokenKeyValuePattern,
    (m) => '${m.group(1)}=[redacted-play-token]',
  );
  text = text.replaceAll(_hex32Pattern, '[redacted-hex32]');
  text = text.replaceAll(_hexPattern, '[redacted-hex]');
  text = text.replaceAll(_emailPattern, '[redacted-email]');
  text = text.replaceAll(_phonePattern, '[redacted-phone]');
  text = text.replaceAllMapped(
    _unixPathPattern,
    (m) => m.group(0)!.replaceFirst(m.group(1)!, '[redacted-path]'),
  );
  text = text.replaceAllMapped(_base64Pattern, (m) {
    final chunk = m.group(0)!;
    return chunk.contains('redacted') ? chunk : '[redacted-base64]';
  });
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

String _scrubbedFirstLine(
  String runtimeType,
  String rawMessage, {
  String? rawRuntimeType,
}) {
  var body = rawMessage;
  for (final type in <String>{
    runtimeType,
    if (rawRuntimeType != null) rawRuntimeType,
  }) {
    final prefix = '$type: ';
    if (body.startsWith(prefix)) {
      body = body.substring(prefix.length);
      break;
    }
  }
  body = body.split(RegExp(r'\r?\n')).first;
  body = truncateCrashText(body, crashMessagePreTruncate);
  body = redactCrashSecrets(body);
  body = truncateCrashText(body, crashMessageFinalMax);
  final withType = '$runtimeType: $body';
  return truncateCrashText(withType, crashMessageFinalMax);
}

String prepareCrashMessage(String runtimeType, String rawMessage) {
  final safeType = sanitizeCrashRuntimeType(runtimeType);
  return _scrubbedFirstLine(safeType, rawMessage, rawRuntimeType: runtimeType);
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
