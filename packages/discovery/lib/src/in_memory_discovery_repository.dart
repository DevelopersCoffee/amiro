import 'discovery_repository.dart';
import 'encounter_record.dart';

/// Not persisted; for tests and as a stand-in until the file store is wired.
class InMemoryDiscoveryRepository implements DiscoveryRepository {
  List<EncounterRecord> _records = const [];

  @override
  Future<List<EncounterRecord>> getAll() async => orderedRecords(_records);

  @override
  Future<EncounterRecord?> findByRemoteIdentityId(
    String remoteIdentityId,
  ) async {
    for (final r in _records) {
      if (r.remoteIdentityId == remoteIdentityId) return r;
    }
    return null;
  }

  @override
  Future<void> save(EncounterRecord record) async {
    _records = applySave(_records, record);
  }

  @override
  Future<void> delete(String localRecordId) async {
    _records = [
      for (final r in _records)
        if (r.localRecordId != localRecordId) r,
    ];
  }
}
