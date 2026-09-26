import 'encounter_record.dart';

/// Storage for the Discovery Passport ledger. Storage only: deciding whether
/// an incoming payload is a new or a known identity is the encounter state
/// machine's job.
///
/// Invariant every implementation keeps: at most one record per
/// [EncounterRecord.remoteIdentityId]. The unique-encounter count is
/// `getAll().length`, so this is what stops one person counting twice.
abstract class DiscoveryRepository {
  /// Every record, oldest first encounter first. The list is unmodifiable.
  Future<List<EncounterRecord>> getAll();

  Future<EncounterRecord?> findByRemoteIdentityId(String remoteIdentityId);

  /// Inserts [record], or replaces the record with the same
  /// [EncounterRecord.localRecordId]. Throws [ArgumentError] if a *different*
  /// record already holds this remote identity id.
  Future<void> save(EncounterRecord record);

  /// Removes the record, if present. Frees its remote identity id.
  Future<void> delete(String localRecordId);
}

/// The records after saving [record] into [existing], applying the
/// one-record-per-remote-identity rule. Shared by every implementation.
List<EncounterRecord> applySave(
  List<EncounterRecord> existing,
  EncounterRecord record,
) {
  for (final other in existing) {
    if (other.remoteIdentityId == record.remoteIdentityId &&
        other.localRecordId != record.localRecordId) {
      throw ArgumentError(
        'remote identity ${record.remoteIdentityId} already has record ${other.localRecordId}',
      );
    }
  }
  return [
    for (final r in existing)
      if (r.localRecordId != record.localRecordId) r,
    record,
  ];
}

/// [records] ordered oldest first encounter first (ties by local id),
/// unmodifiable.
List<EncounterRecord> orderedRecords(Iterable<EncounterRecord> records) {
  final sorted = records.toList()
    ..sort((a, b) {
      final byTime = a.firstEncountered.compareTo(b.firstEncountered);
      return byTime != 0 ? byTime : a.localRecordId.compareTo(b.localRecordId);
    });
  return List.unmodifiable(sorted);
}
