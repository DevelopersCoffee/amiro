/// Redacts likely secrets from crash text. Always truncate before heavy work.
const crashMessageMax = 500;
const crashFrameLineMax = 256;
const crashFramesMax = 30;

String scrubCrashMessage(String input, [int max = crashMessageMax]) {
  var text = input.length > max ? input.substring(0, max) : input;
  final patterns = <RegExp, String>{
    RegExp(
      r'\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b',
    ): '[redacted-jwt]',
    RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]{8,}\b', caseSensitive: false):
        'Bearer [redacted]',
    RegExp(
      r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
      caseSensitive: false,
    ): '[redacted-id]',
    RegExp(r'\b[0-9a-f]{32,64}\b', caseSensitive: false): '[redacted-hex]',
    RegExp(r'\b[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9.-]{1,253}\.[A-Za-z]{2,}\b'):
        '[redacted-email]',
    RegExp(r'\b\+?\d[\d\s().-]{6,14}\d\b'): '[redacted-phone]',
    RegExp(r'\bhttps?:\/\/[^\s"<>#]+', caseSensitive: false): '[redacted-url]',
    RegExp(r'#[^\s"<>]+'): '#[redacted]',
    RegExp(r"([?&][^= \t\r\n\"']+=)([^&\s\"<>]+)"): r'$1[redacted]',
  };
  for (final entry in patterns.entries) {
    text = text.replaceAll(entry.key, entry.value);
  }
  return text;
}

List<String> extractPackageFrames(String stack, {int maxFrames = crashFramesMax}) {
  final frames = <String>[];
  for (final line in stack.split(RegExp(r'\r?\n'))) {
    if (!line.contains('package:')) continue;
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final capped = trimmed.length > crashFrameLineMax
        ? trimmed.substring(0, crashFrameLineMax)
        : trimmed;
    frames.add(scrubCrashMessage(capped, crashFrameLineMax));
    if (frames.length >= maxFrames) break;
  }
  return frames;
}

/// Legacy local file sink still stores a readable report shape.
Map<String, Object?> scrubCrashReport(Map<String, Object?> report) {
  final message = report['message'];
  final stack = report['stack'];
  return {
    ...report,
    if (message is String) 'message': scrubCrashMessage(message),
    if (stack is String) 'stack': stack.split('\n').map(scrubCrashMessage).join('\n'),
  };
}