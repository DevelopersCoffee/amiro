import 'dart:convert';
import 'dart:io';

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
      installIdStore: AnalyticsInstallIdStore.inMemory(id: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'),
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
    final idStore = AnalyticsInstallIdStore.inMemory(id: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee');
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

  test('opt-out calls revoke on HTTP sink before regenerating id', () async {
    final id = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
    String? revoked;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.method == 'DELETE') {
        final body = await utf8.decoder.bind(request).join();
        revoked = (jsonDecode(body) as Map)['install_id'] as String;
        request.response.statusCode = 200;
      }
      await request.response.close();
    });
    final sink = HttpAnalyticsSink(
      Uri.parse('http://127.0.0.1:${server.port}/analytics/t'),
      allowInsecureHttp: true,
    );
    final service = AnalyticsService(
      preferences: AnalyticsPreferences.inMemory(enabled: true),
      installIdStore: AnalyticsInstallIdStore.inMemory(id: id),
      sinks: [sink],
      appVersion: '1.0.0',
    );
    await service.onConsentDisabled();
    await server.close(force: true);
    expect(revoked, id);
  });
}