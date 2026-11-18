import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_install_id.dart';
import 'analytics_once.dart';
import 'analytics_preferences.dart';
import 'analytics_service.dart';
import 'analytics_sink.dart';

final analyticsPreferencesProvider = Provider<AnalyticsPreferences>((ref) {
  return AnalyticsPreferences.inDirectory(
    Directory.systemTemp.createTempSync('amiro_analytics_default'),
  );
});

final analyticsInstallIdStoreProvider = Provider<AnalyticsInstallIdStore>((ref) {
  return AnalyticsInstallIdStore.inDirectory(
    Directory.systemTemp.createTempSync('amiro_analytics_id_default'),
  );
});

final analyticsOnceStoreProvider = Provider<AnalyticsOnceStore>((ref) {
  return AnalyticsOnceStore.inDirectory(
    Directory.systemTemp.createTempSync('amiro_analytics_once_default'),
  );
});

/// When empty, analytics HTTP sink is not configured (same pattern as crash).
final analyticsIngestConfiguredProvider = Provider<bool>((ref) {
  return const String.fromEnvironment('AMIRO_ANALYTICS_INGEST_URL').isNotEmpty;
});

/// Sinks (including HTTP) wired in `main.dart`; tests override this provider.
final analyticsSinksProvider = Provider<List<AnalyticsSink>>((ref) {
  return const [];
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    preferences: ref.watch(analyticsPreferencesProvider),
    installIdStore: ref.watch(analyticsInstallIdStoreProvider),
    sinks: ref.watch(analyticsSinksProvider),
    appVersion: '1.0.6+12',
  );
});

final analyticsEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(analyticsPreferencesProvider).isEnabled();
});