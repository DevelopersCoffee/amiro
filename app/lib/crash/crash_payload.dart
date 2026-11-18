import 'crash_scrub.dart';

const _kSources = {'flutter', 'platform'};

/// Minimal crash upload: exception type, scrubbed message, package frames only.
Map<String, Object?> buildCrashUploadPayload({
  required Object error,
  required StackTrace stack,
  required String source,
  required String appVersion,
  required String platform,
}) {
  final normalizedSource = _kSources.contains(source) ? source : 'platform';
  final frames = extractPackageFrames(stack.toString());
  return {
    'exceptionType': error.runtimeType.toString(),
    'message': scrubCrashMessage(error.toString()),
    'frames': frames,
    'source': normalizedSource,
    'appVersion': appVersion.length > 64 ? appVersion.substring(0, 64) : appVersion,
    'platform': platform,
  };
}