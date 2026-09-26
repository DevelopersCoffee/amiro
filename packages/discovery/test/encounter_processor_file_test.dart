import 'dart:io';

import 'package:discovery/discovery.dart';
import 'package:sharing/sharing.dart';
import 'package:test/test.dart';

AmiroSharingPayload _payload(String remote) => AmiroSharingPayload(
  remoteIdentityId: remote,
  displayName: remote,
  activeAvatarConfig: '{"id":"a"}',
  equippedCosmetics: const [],
  collectionCompletion: const [],
);

void main() {
  test('encounters and the unique count survive an app restart', () async {
    final dir = Directory.systemTemp.createTempSync('processor_file_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/encounters.json');

    final first = EncounterProcessor(FileDiscoveryRepository(file));
    for (final remote in ['A', 'A', 'B']) {
      await first.save(
        await first.receivePayload(_payload(remote)) as PendingEncounter,
      );
    }

    final restarted = EncounterProcessor(FileDiscoveryRepository(file));
    final again = await restarted.receivePayload(_payload('A'));

    expect(await restarted.uniqueEncounterCount(), 2);
    expect(again, isA<KnownEncounter>());
    expect((again as KnownEncounter).previous.encounterCount, 2);
  });
}
