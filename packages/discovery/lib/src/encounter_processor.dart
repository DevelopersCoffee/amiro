import 'package:sharing/sharing.dart';

import 'discovery_repository.dart';
import 'encounter_record.dart';
import 'local_record_id.dart';

/// The outcome of receiving a scanned or tapped identity.
///
/// RECEIVED -> VALIDATED -> known? -> UPDATE | CREATE -> PRESENT -> SAVED.
/// [EncounterProcessor.receive] runs up to PRESENT and writes nothing; the
/// user's "save to passport" is [EncounterProcessor.save].
sealed class EncounterResult {
  const EncounterResult();
}

/// The data failed validation. It never reaches the ledger.
final class EncounterRejected extends EncounterResult {
  final SharingPayloadException error;

  const EncounterRejected(this.error);
}

/// The user scanned their own card. Not an encounter.
final class SelfEncounter extends EncounterResult {
  const SelfEncounter();
}

/// A valid encounter waiting for the user to save it.
sealed class PendingEncounter extends EncounterResult {
  final AmiroSharingPayload payload;
  final DateTime receivedAt;

  /// The record that saving would write, for the comparison screen.
  final EncounterRecord proposed;

  const PendingEncounter({
    required this.payload,
    required this.receivedAt,
    required this.proposed,
  });
}

/// First time this identity has been seen: saving creates a record and
/// raises the unique-encounter count.
final class NewEncounter extends PendingEncounter {
  const NewEncounter({
    required super.payload,
    required super.receivedAt,
    required super.proposed,
  });
}

/// Already in the passport: saving updates [previous] and leaves the
/// unique-encounter count alone.
final class KnownEncounter extends PendingEncounter {
  final EncounterRecord previous;

  const KnownEncounter({
    required super.payload,
    required super.receivedAt,
    required super.proposed,
    required this.previous,
  });
}

/// Turns received payloads into ledger changes. Transport-agnostic: QR and
/// NFC both hand it the same payload.
class EncounterProcessor {
  final DiscoveryRepository _repository;
  final DateTime Function() _clock;
  final String Function() _newId;
  final String? _ownIdentityId;
  Future<void> _tail = Future.value();

  /// [ownIdentityId] is this user's own id, so scanning their own card isn't
  /// counted. [clock] and [newId] exist for tests.
  EncounterProcessor(
    this._repository, {
    DateTime Function()? clock,
    String Function()? newId,
    String? ownIdentityId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? newLocalRecordId,
       _ownIdentityId = ownIdentityId;

  /// Unique people met: one per remote identity, however often they were met.
  Future<int> uniqueEncounterCount() async =>
      (await _repository.getAll()).length;

  /// Validates [raw] payload JSON, then classifies it. Writes nothing.
  Future<EncounterResult> receive(String raw) async {
    final AmiroSharingPayload payload;
    try {
      payload = AmiroSharingPayload.decode(raw);
    } on SharingPayloadException catch (e) {
      return EncounterRejected(e);
    }
    return _classify(payload);
  }

  /// As [receive], for a payload that is already parsed. It is validated
  /// again: a payload built in code is not trusted just for existing.
  Future<EncounterResult> receivePayload(AmiroSharingPayload payload) async {
    try {
      payload.validate();
    } on SharingPayloadException catch (e) {
      return EncounterRejected(e);
    }
    return _classify(payload);
  }

  /// Commits [pending] to the ledger and returns the stored record.
  ///
  /// Idempotent (saving the same encounter twice counts it once), and safe
  /// against a stale preview: if the ledger changed since [pending] was
  /// produced, the update is recomputed from what is stored now.
  Future<EncounterRecord> save(PendingEncounter pending) {
    return _serialised(() async {
      final current = await _repository.findByRemoteIdentityId(
        pending.payload.remoteIdentityId,
      );
      if (current == pending.proposed) return current!; // already saved

      final EncounterRecord toWrite;
      final expectedBefore = pending is KnownEncounter
          ? pending.previous
          : null;
      if (current == expectedBefore) {
        toWrite = pending.proposed;
      } else if (current == null) {
        // Deleted since the preview: it is a first contact again.
        toWrite = _create(pending.payload, pending.receivedAt);
      } else {
        toWrite = _update(current, pending.payload, pending.receivedAt);
      }
      await _repository.save(toWrite);
      return toWrite;
    });
  }

  Future<EncounterResult> _classify(AmiroSharingPayload payload) async {
    if (payload.remoteIdentityId == _ownIdentityId)
      return const SelfEncounter();

    final receivedAt = _clock().toUtc();
    final existing = await _repository.findByRemoteIdentityId(
      payload.remoteIdentityId,
    );
    if (existing == null) {
      return NewEncounter(
        payload: payload,
        receivedAt: receivedAt,
        proposed: _create(payload, receivedAt),
      );
    }
    return KnownEncounter(
      payload: payload,
      receivedAt: receivedAt,
      proposed: _update(existing, payload, receivedAt),
      previous: existing,
    );
  }

  EncounterRecord _create(AmiroSharingPayload payload, DateTime at) {
    return EncounterRecord(
      localRecordId: _newId(),
      remoteIdentityId: payload.remoteIdentityId,
      displayName: payload.displayName,
      firstEncountered: at,
      lastEncountered: at,
      encounterCount: 1,
      latestAvatarConfig: payload.activeAvatarConfig,
      observedCosmetics: payload.equippedCosmetics,
      observedCollections: payload.collectionCompletion,
    );
  }

  EncounterRecord _update(
    EncounterRecord existing,
    AmiroSharingPayload payload,
    DateTime at,
  ) {
    return existing.copyWith(
      displayName: payload.displayName,
      // A clock that steps backwards must not shrink the record's history.
      lastEncountered: at.isBefore(existing.lastEncountered)
          ? existing.lastEncountered
          : at,
      encounterCount: existing.encounterCount + 1,
      latestAvatarConfig: payload.activeAvatarConfig,
      observedCosmetics: payload.equippedCosmetics,
      observedCollections: payload.collectionCompletion,
    );
  }

  Future<T> _serialised<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }
}
