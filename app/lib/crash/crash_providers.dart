import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crash_upload_preferences.dart';

/// Overridden in `main.dart`. Default: crash upload off.
final crashUploadPreferencesProvider = Provider<CrashUploadPreferences>((ref) {
  return CrashUploadPreferences.inDirectory(
    Directory.systemTemp.createTempSync('amiro_crash_upload_default'),
  );
});

/// True when the build defines `AMIRO_CRASH_INGEST_URL`. Tests may override.
final crashIngestConfiguredProvider = Provider<bool>((ref) {
  return const String.fromEnvironment('AMIRO_CRASH_INGEST_URL').isNotEmpty;
});