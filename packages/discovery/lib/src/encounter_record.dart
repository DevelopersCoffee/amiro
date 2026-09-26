import 'package:sharing/sharing.dart';

/// One person the user has encountered: what we last saw of them and when.
///
/// [localRecordId] is generated on this device and never leaves it;
/// [remoteIdentityId] is the other side's identifier, kept separate so the
/// ledger survives identity rotation or migration. Immutable: an encounter
/// produces a new record via [copyWith].
class EncounterRecord {
  final String localRecordId;
  final String remoteIdentityId;
  final String displayName;
  final DateTime firstEncountered;
  final DateTime lastEncountered;
  final int encounterCount;

  /// The freshest avatar definition JSON we have seen. Earlier looks are not
  /// kept; [firstEncountered] is the only history.
  final String latestAvatarConfig;
  final List<EquippedCosmeticInfo> observedCosmetics;
  final List<SeriesCompletion> observedCollections;

  /// Throws [ArgumentError] for an empty id or name, a count below 1, or
  /// [lastEncountered] before [firstEncountered]. Times are stored as UTC.
  EncounterRecord({
    required this.localRecordId,
    required this.remoteIdentityId,
    required this.displayName,
    required DateTime firstEncountered,
    required DateTime lastEncountered,
    required this.encounterCount,
    required this.latestAvatarConfig,
    required List<EquippedCosmeticInfo> observedCosmetics,
    required List<SeriesCompletion> observedCollections,
  }) : firstEncountered = firstEncountered.toUtc(),
       lastEncountered = lastEncountered.toUtc(),
       observedCosmetics = List.unmodifiable(observedCosmetics),
       observedCollections = List.unmodifiable(observedCollections) {
    if (localRecordId.isEmpty)
      throw ArgumentError('localRecordId must not be empty');
    if (remoteIdentityId.isEmpty)
      throw ArgumentError('remoteIdentityId must not be empty');
    if (displayName.isEmpty)
      throw ArgumentError('displayName must not be empty');
    if (encounterCount < 1)
      throw ArgumentError('encounterCount must be at least 1');
    if (this.lastEncountered.isBefore(this.firstEncountered)) {
      throw ArgumentError(
        'lastEncountered must not be before firstEncountered',
      );
    }
  }

  /// Reads a record from decoded JSON. Anything malformed, including values
  /// the constructor rejects, is a [FormatException].
  factory EncounterRecord.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('an encounter record must be a JSON object');
    }
    try {
      return EncounterRecord(
        localRecordId: _string(json, 'localRecordId'),
        remoteIdentityId: _string(json, 'remoteIdentityId'),
        displayName: _string(json, 'displayName'),
        firstEncountered: _date(json, 'firstEncountered'),
        lastEncountered: _date(json, 'lastEncountered'),
        encounterCount: _int(json, 'encounterCount'),
        latestAvatarConfig: _string(json, 'latestAvatarConfig'),
        observedCosmetics: [
          for (final e in _list(json, 'observedCosmetics'))
            EquippedCosmeticInfo.fromJson(e),
        ],
        observedCollections: [
          for (final e in _list(json, 'observedCollections'))
            SeriesCompletion.fromJson(e),
        ],
      );
    } on ArgumentError catch (e) {
      throw FormatException('invalid encounter record: ${e.message}');
    } on SharingPayloadException catch (e) {
      throw FormatException('invalid encounter record: ${e.message}');
    }
  }

  EncounterRecord copyWith({
    String? displayName,
    DateTime? lastEncountered,
    int? encounterCount,
    String? latestAvatarConfig,
    List<EquippedCosmeticInfo>? observedCosmetics,
    List<SeriesCompletion>? observedCollections,
  }) {
    return EncounterRecord(
      localRecordId: localRecordId,
      remoteIdentityId: remoteIdentityId,
      displayName: displayName ?? this.displayName,
      firstEncountered: firstEncountered,
      lastEncountered: lastEncountered ?? this.lastEncountered,
      encounterCount: encounterCount ?? this.encounterCount,
      latestAvatarConfig: latestAvatarConfig ?? this.latestAvatarConfig,
      observedCosmetics: observedCosmetics ?? this.observedCosmetics,
      observedCollections: observedCollections ?? this.observedCollections,
    );
  }

  Map<String, dynamic> toJson() => {
    'localRecordId': localRecordId,
    'remoteIdentityId': remoteIdentityId,
    'displayName': displayName,
    'firstEncountered': firstEncountered.toIso8601String(),
    'lastEncountered': lastEncountered.toIso8601String(),
    'encounterCount': encounterCount,
    'latestAvatarConfig': latestAvatarConfig,
    'observedCosmetics': [for (final c in observedCosmetics) c.toJson()],
    'observedCollections': [for (final c in observedCollections) c.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is EncounterRecord &&
      other.localRecordId == localRecordId &&
      other.remoteIdentityId == remoteIdentityId &&
      other.displayName == displayName &&
      other.firstEncountered == firstEncountered &&
      other.lastEncountered == lastEncountered &&
      other.encounterCount == encounterCount &&
      other.latestAvatarConfig == latestAvatarConfig &&
      _listEquals(other.observedCosmetics, observedCosmetics) &&
      _listEquals(other.observedCollections, observedCollections);

  @override
  int get hashCode => Object.hash(
    localRecordId,
    remoteIdentityId,
    displayName,
    firstEncountered,
    lastEncountered,
    encounterCount,
    latestAvatarConfig,
    Object.hashAll(observedCosmetics),
    Object.hashAll(observedCollections),
  );
}

String _string(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String)
    throw FormatException('$field is missing or not a string');
  return value;
}

int _int(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! int)
    throw FormatException('$field is missing or not an integer');
  return value;
}

DateTime _date(Map<String, dynamic> json, String field) {
  final parsed = DateTime.tryParse(_string(json, field));
  if (parsed == null) throw FormatException('$field is not an ISO-8601 date');
  return parsed;
}

List<Object?> _list(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! List) throw FormatException('$field is missing or not a list');
  return value;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
