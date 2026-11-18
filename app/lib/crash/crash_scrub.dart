/// Redacts likely PII from crash [message] and [stack] text before upload.
String scrubCrashText(String input) {
  var text = input;
  text = text.replaceAll(
    RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
    '[redacted-email]',
  );
  text = text.replaceAll(
    RegExp(r'\+?\d[\d\s().-]{8,}\d'),
    '[redacted-phone]',
  );
  text = text.replaceAll(
    RegExp(r'https?://[^\s"<>]+?\?[^\s"<>]*'),
    '[redacted-url]',
  );
  text = text.replaceAll(
    RegExp(r'file://[^\s"<>]+'),
    '[redacted-path]',
  );
  text = text.replaceAll(
    RegExp(r'[A-Za-z]:\\[^\s"<>]+'),
    '[redacted-path]',
  );
  text = text.replaceAll(
    RegExp(r'/(?:[\w.-]+/)+[\w.-]*'),
    '[redacted-path]',
  );
  return text;
}

Map<String, Object?> scrubCrashReport(Map<String, Object?> report) {
  final message = report['message'];
  final stack = report['stack'];
  return {
    ...report,
    if (message is String) 'message': scrubCrashText(message),
    if (stack is String) 'stack': scrubCrashText(stack),
  };
}