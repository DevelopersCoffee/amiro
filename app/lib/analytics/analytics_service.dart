import 'dart:io';

import 'analytics_install_id.dart';
import 'analytics_preferences.dart';
import 'analytics_schema.dart';
import 'analytics_sink.dart';

typedef AnalyticsClock = DateTime Function();

/// Consent-gated, allow-listed analytics recorder.
class AnalyticsService {
  AnalyticsService({
    required this.preferences,
    required this.installIdStore,
    required this.sinks,
    required this.appVersion,
    AnalyticsClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final AnalyticsPreferences preferences;
  final AnalyticsInstallIdStore installIdStore;
  final List<AnalyticsSink> sinks;
  final String appVersion;
  final AnalyticsClock _clock;

  Future<void> record(
    String event, {
    Map<String, String>? properties,
  }) async {
    if (!analyticsEventNames.contains(event)) return;
    if (!await preferences.isEnabled()) return;

    final allowed = allowedKeysForEvent(event);
    final props = <String, String>{};
    if (properties != null) {
      for (final entry in properties.entries) {
        if (!allowed.contains(entry.key)) continue;
        final value = entry.value;
        if (entry.key == 'surface' &&
            !analyticsPaywallSurfaces.contains(value)) {
          continue;
        }
        if (entry.key == 'sku_kind' && !analyticsSkuKinds.contains(value)) {
          continue;
        }
        if (entry.key == 'community_slug' &&
            !analyticsCommunitySlugs.contains(value)) {
          continue;
        }
        if (entry.key == 'src' && !analyticsAttributionSources.contains(value)) {
          continue;
        }
        props[entry.key] = value;
      }
    }

    final installId = await installIdStore.currentOrCreate();
    final day = _clock().toUtc();
    final eventDay =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    final payload = <String, Object?>{
      'event': event,
      'event_day': eventDay,
      'app_version': appVersion,
      'platform': Platform.operatingSystem,
      'install_id': installId,
      ...props,
    };

    for (final sink in sinks) {
      try {
        await sink.send([payload]);
      } catch (_) {}
    }
  }

  Future<void> onConsentDisabled() async {
    await installIdStore.regenerate();
  }
}