import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:discovery/discovery.dart';

import '../identity/identity_providers.dart';

/// Where the Discovery Passport is stored. Overridden in `main.dart` with a
/// [FileDiscoveryRepository]; tests get a fresh in-memory ledger each.
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return InMemoryDiscoveryRepository();
});

/// Turns a received card into a passport entry. Knows the user's own
/// identity id so scanning your own card is not counted as an encounter.
final encounterProcessorProvider = Provider<EncounterProcessor>((ref) {
  final ownId = ref.watch(currentIdentityProvider).value?.id;
  return EncounterProcessor(
    ref.watch(discoveryRepositoryProvider),
    ownIdentityId: ownId,
  );
});

/// Everyone in the passport, oldest first encounter first. Invalidate after
/// a save so the passport screen refreshes.
final encounterRecordsProvider =
    FutureProvider.autoDispose<List<EncounterRecord>>((ref) {
      return ref.watch(discoveryRepositoryProvider).getAll();
    });
