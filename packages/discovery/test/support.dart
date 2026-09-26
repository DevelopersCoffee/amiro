import 'package:discovery/discovery.dart';
import 'package:sharing/sharing.dart';

final t0 = DateTime.utc(2026, 9, 26, 10);

EncounterRecord record({
  String localRecordId = 'local-1',
  String remoteIdentityId = 'remote-1',
  String displayName = 'Ada',
  DateTime? firstEncountered,
  DateTime? lastEncountered,
  int encounterCount = 1,
  String latestAvatarConfig = '{"id":"a"}',
  List<EquippedCosmeticInfo> observedCosmetics = const [
    EquippedCosmeticInfo(
      id: 'riviera_optics',
      name: 'Riviera Optics',
      seriesId: 'series_1',
      rarity: 'RARE',
    ),
  ],
  List<SeriesCompletion> observedCollections = const [
    SeriesCompletion(seriesId: 'series_1', currentCount: 1, totalCount: 3),
  ],
}) {
  return EncounterRecord(
    localRecordId: localRecordId,
    remoteIdentityId: remoteIdentityId,
    displayName: displayName,
    firstEncountered: firstEncountered ?? t0,
    lastEncountered: lastEncountered ?? firstEncountered ?? t0,
    encounterCount: encounterCount,
    latestAvatarConfig: latestAvatarConfig,
    observedCosmetics: observedCosmetics,
    observedCollections: observedCollections,
  );
}
