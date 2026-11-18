import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amiro_app/analytics/analytics_install_id.dart';
import 'package:amiro_app/analytics/analytics_once.dart';
import 'package:amiro_app/analytics/analytics_preferences.dart';
import 'package:amiro_app/analytics/analytics_providers.dart';
import 'package:amiro_app/analytics/analytics_sink.dart';

/// Default analytics wiring for widget tests (consent off, no HTTP).
List<Override> analyticsTestOverrides() {
  return [
    analyticsPreferencesProvider.overrideWithValue(AnalyticsPreferences.inMemory()),
    analyticsInstallIdStoreProvider.overrideWithValue(
      AnalyticsInstallIdStore.inMemory(),
    ),
    analyticsOnceStoreProvider.overrideWithValue(AnalyticsOnceStore.inMemory()),
    analyticsSinksProvider.overrideWithValue(const []),
    analyticsIngestConfiguredProvider.overrideWithValue(false),
  ];
}