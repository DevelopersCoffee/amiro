import 'dart:convert';
import 'dart:io';

import 'discovery_repository.dart';
import 'encounter_record.dart';

/// The ledger as one JSON array in a file, matching the local-first
/// storage the entitlement store uses.
///
/// Writes go to a temp file that is renamed over the ledger, so a crash
/// mid-write can't truncate the passport. A corrupt file throws
/// [FormatException] on read and is never overwritten: losing every
/// encounter silently would be worse than failing loudly. Writes are
/// serialised so overlapping saves can't lose each other.
class FileDiscoveryRepository implements DiscoveryRepository {
  final File _file;
  Future<void> _queue = Future.value();

  FileDiscoveryRepository(this._file);

  @override
  Future<List<EncounterRecord>> getAll() async => orderedRecords(await _read());

  @override
  Future<EncounterRecord?> findByRemoteIdentityId(
    String remoteIdentityId,
  ) async {
    for (final r in await _read()) {
      if (r.remoteIdentityId == remoteIdentityId) return r;
    }
    return null;
  }

  @override
  Future<void> save(EncounterRecord record) {
    return _serialised(() async => _write(applySave(await _read(), record)));
  }

  @override
  Future<void> delete(String localRecordId) {
    return _serialised(() async {
      final existing = await _read();
      final remaining = [
        for (final r in existing)
          if (r.localRecordId != localRecordId) r,
      ];
      if (remaining.length != existing.length) await _write(remaining);
    });
  }

  Future<void> _serialised(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.catchError((_) {}); // one failure must not block later writes
    return next;
  }

  Future<List<EncounterRecord>> _read() async {
    if (!await _file.exists()) return const [];
    final contents = await _file.readAsString();
    if (contents.trim().isEmpty) return const [];

    final decoded = jsonDecode(contents);
    if (decoded is! List)
      throw const FormatException('the ledger file is not a JSON array');
    return [for (final entry in decoded) EncounterRecord.fromJson(entry)];
  }

  Future<void> _write(List<EncounterRecord> records) async {
    await _file.parent.create(recursive: true);
    final temp = File('${_file.path}.tmp');
    await temp.writeAsString(
      jsonEncode([for (final r in records) r.toJson()]),
      flush: true,
    );
    await temp.rename(_file.path);
  }
}
