import 'package:amiro_app/analytics/analytics_funnel.dart';
import 'package:amiro_app/analytics/analytics_install_id.dart';
import 'package:amiro_app/analytics/analytics_once.dart';
import 'package:amiro_app/analytics/analytics_preferences.dart';
import 'package:amiro_app/analytics/analytics_providers.dart';
import 'package:amiro_app/analytics/analytics_sink.dart';
import 'package:amiro_app/discovery/discovery_providers.dart';
import 'package:amiro_app/identity/identity_providers.dart';
import 'package:discovery/discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';

import '../identity/in_memory_identity_repository.dart';

void main() {
  test('second_encounter payload has no other-person fields', () async {
    final repo = InMemoryDiscoveryRepository();
    await repo.save(
      EncounterRecord(
        localRecordId: 'a',
        remoteIdentityId: 'remote-1',
        displayName: 'Other',
        firstEncountered: DateTime.utc(2026, 1, 1),
        lastEncountered: DateTime.utc(2026, 1, 2),
        encounterCount: 1,
        latestAvatarConfig: '{}',
        observedCosmetics: const [],
        observedCollections: const [],
      ),
    );
    await repo.save(
      EncounterRecord(
        localRecordId: 'b',
        remoteIdentityId: 'remote-2',
        displayName: 'Second',
        firstEncountered: DateTime.utc(2026, 1, 3),
        lastEncountered: DateTime.utc(2026, 1, 3),
        encounterCount: 1,
        latestAvatarConfig: '{}',
        observedCosmetics: const [],
        observedCollections: const [],
      ),
    );
    final sink = MemoryAnalyticsSink();
    final container = ProviderContainer(
      overrides: [
        analyticsPreferencesProvider.overrideWithValue(
          AnalyticsPreferences.inMemory(enabled: true),
        ),
        analyticsInstallIdStoreProvider.overrideWithValue(
          AnalyticsInstallIdStore.inMemory(
            id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          ),
        ),
        analyticsOnceStoreProvider.overrideWithValue(AnalyticsOnceStore.inMemory()),
        analyticsSinksProvider.overrideWithValue([sink]),
        discoveryRepositoryProvider.overrideWithValue(repo),
        identityRepositoryProvider.overrideWithValue(
          InMemoryIdentityRepository(
            const Identity(id: 'me', displayName: 'U', username: 'u'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(analyticsFunnelProvider).afterEncounterSave();
    expect(sink.events, hasLength(1));
    final keys = sink.events.single.keys.toSet();
    expect(
      keys,
      anyOf(
        equals({
          'event',
          'event_day',
          'app_version',
          'platform',
          'install_id',
        }),
      ),
    );
    expect(keys, isNot(contains('displayName')));
    expect(keys, isNot(contains('remoteIdentityId')));
  });

  test('setup_complete fires only once', () async {
    final sink = MemoryAnalyticsSink();
    final container = ProviderContainer(
      overrides: [
        analyticsPreferencesProvider.overrideWithValue(
          AnalyticsPreferences.inMemory(enabled: true),
        ),
        analyticsInstallIdStoreProvider.overrideWithValue(
          AnalyticsInstallIdStore.inMemory(),
        ),
        analyticsOnceStoreProvider.overrideWithValue(AnalyticsOnceStore.inMemory()),
        analyticsSinksProvider.overrideWithValue([sink]),
      ],
    );
    addTearDown(container.dispose);
    final funnel = container.read(analyticsFunnelProvider);
    const identity = Identity(
      id: 'id-1',
      displayName: 'Ada',
      username: 'ada',
      avatarDefinitionJson: '{}',
    );
    await funnel.trySetupComplete(identity, avatarLoaded: true);
    await funnel.trySetupComplete(identity, avatarLoaded: true);
    expect(sink.events.where((e) => e['event'] == 'setup_complete'), hasLength(1));
  });
}