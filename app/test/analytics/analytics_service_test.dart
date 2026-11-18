import 'package:amiro_app/analytics/analytics_install_id.dart';
import 'package:amiro_app/analytics/analytics_preferences.dart';
import 'package:amiro_app/analytics/analytics_service.dart';
import 'package:amiro_app/analytics/analytics_sink.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no network without consent', () async {
    final sink = MemoryAnalyticsSink();
    final service = AnalyticsService(
      preferences: AnalyticsPreferences.inMemory(),
      installIdStore: AnalyticsInstallIdStore.inMemory(),
      sinks: [sink],
      appVersion: '1.0.0',
      clock: () => DateTime.utc(2026, 11, 18),
    );
    await service.record('setup_complete');
    expect(sink.events, isEmpty);
  });

  test('consent on sends only allow-listed keys', () async {
    final prefs = AnalyticsPreferences.inMemory(enabled: true);
    final sink = MemoryAnalyticsSink();
    final service = AnalyticsService(
      preferences: prefs,
      installIdStore: AnalyticsInstallIdStore.inMemory(id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'),
      sinks: [sink],
      appVersion: '1.0.6+12',
      clock: () => DateTime.utc(2026, 11, 18),
    );
    await service.record(
      'paywall_shown',
      properties: {
        'surface': 'store_tab',
        'displayName': 'secret',
        'remote_id': 'x',
      },
    );
    expect(sink.events, hasLength(1));
    final payload = sink.events.single;
    expect(payload.keys, containsAll(['event', 'event_day', 'app_version', 'install_id']));
    expect(payload.keys, isNot(contains('displayName')));
    expect(payload['surface'], 'store_tab');
  });

  test('opt-out regenerates install id', () async {
    final prefs = AnalyticsPreferences.inMemory(enabled: true);
    final idStore = AnalyticsInstallIdStore.inMemory();
    final service = AnalyticsService(
      preferences: prefs,
      installIdStore: idStore,
      sinks: [],
      appVersion: '1.0.0',
    );
    final first = await idStore.currentOrCreate();
    await service.onConsentDisabled();
    final second = await idStore.currentOrCreate();
    expect(second, isNot(first));
  });
}