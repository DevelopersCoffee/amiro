import 'package:flutter/foundation.dart';

import 'analytics_sink.dart';

/// Builds HTTP analytics sinks from the build-time ingest URL define.
///
/// Mirrors crash ingest guards: invalid or non-https URLs disable upload without
/// crashing startup.
List<AnalyticsSink> analyticsSinksFromIngestUrl(
  String ingestUrl, {
  bool releaseMode = kReleaseMode,
}) {
  if (ingestUrl.isEmpty) return [];
  final ingestUri = Uri.tryParse(ingestUrl);
  if (ingestUri == null) {
    debugPrint('AMIRO_ANALYTICS_INGEST_URL is invalid; analytics upload disabled.');
    return [];
  }
  if (ingestUri.scheme == 'https') {
    return [HttpAnalyticsSink(ingestUri)];
  }
  if (!releaseMode) {
    return [HttpAnalyticsSink(ingestUri, allowInsecureHttp: true)];
  }
  debugPrint(
    'AMIRO_ANALYTICS_INGEST_URL must use https in release builds; analytics disabled.',
  );
  return [];
}