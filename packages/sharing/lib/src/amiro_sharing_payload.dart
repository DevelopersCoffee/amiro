import 'dart:convert';

/// Wire schema version this library reads and writes.
const kAmiroSharingSchemaVersion = 1;

/// Upper bound on the encoded JSON, in UTF-8 bytes. Keeps a QR code
/// scannable and stops a hostile payload from bloating memory.
const maxSharingPayloadBytes = 4096;

/// Upper bound on entries in each list of a payload.
const maxSharedListLength = 32;

enum PayloadErrorKind {
  /// Not JSON, not an object, or the schema version field is unusable.
  malformed,

  /// Well-formed, but from a schema version this library doesn't read.
  unsupportedVersion,

  /// Over [maxSharingPayloadBytes].
  tooLarge,

  /// Right shape, wrong content: a missing/empty field, bad counts, duplicates.
  invalid,
}

/// Why a payload was rejected. Anything that reaches discovery has already
/// passed validation, so callers can treat this as "not a usable Amiro".
class SharingPayloadException implements Exception {
  final PayloadErrorKind kind;
  final String message;

  const SharingPayloadException(this.kind, this.message);

  @override
  String toString() => 'SharingPayloadException(${kind.name}): $message';
}

/// A cosmetic the sender has equipped, as displayed on their card.
///
/// Sender-claimed: a receiver that knows the item in its own catalog should
/// prefer its own name and rarity and treat these as a fallback.
class EquippedCosmeticInfo {
  final String id;
  final String name;

  /// Null for items outside any numbered series (e.g. free basics).
  final String? seriesId;
  final String rarity;

  const EquippedCosmeticInfo({
    required this.id,
    required this.name,
    required this.seriesId,
    required this.rarity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (seriesId != null) 'seriesId': seriesId,
        'rarity': rarity,
      };

  @override
  bool operator ==(Object other) =>
      other is EquippedCosmeticInfo &&
      other.id == id &&
      other.name == name &&
      other.seriesId == seriesId &&
      other.rarity == rarity;

  @override
  int get hashCode => Object.hash(id, name, seriesId, rarity);
}

/// How much of one series the sender has collected.
class SeriesCompletion {
  final String seriesId;
  final int currentCount;
  final int totalCount;

  const SeriesCompletion({
    required this.seriesId,
    required this.currentCount,
    required this.totalCount,
  });

  Map<String, dynamic> toJson() => {
        'seriesId': seriesId,
        'currentCount': currentCount,
        'totalCount': totalCount,
      };

  @override
  bool operator ==(Object other) =>
      other is SeriesCompletion &&
      other.seriesId == seriesId &&
      other.currentCount == currentCount &&
      other.totalCount == totalCount;

  @override
  int get hashCode => Object.hash(seriesId, currentCount, totalCount);
}

/// The one identity-exchange contract. QR and NFC both carry exactly this;
/// discovery only ever sees a payload that passed [validate].
///
/// Transport-agnostic: no URI scheme, no NDEF, just JSON text.
class AmiroSharingPayload {
  final int schemaVersion;

  /// The sender's stable identity id: an identifier, not proof of identity.
  final String remoteIdentityId;
  final String displayName;

  /// Opaque avatar definition JSON, interpreted by avatar_core.
  final String activeAvatarConfig;
  final List<EquippedCosmeticInfo> equippedCosmetics;
  final List<SeriesCompletion> collectionCompletion;

  const AmiroSharingPayload({
    this.schemaVersion = kAmiroSharingSchemaVersion,
    required this.remoteIdentityId,
    required this.displayName,
    required this.activeAvatarConfig,
    required this.equippedCosmetics,
    required this.collectionCompletion,
  });

  /// Parses and validates [raw]. Throws [SharingPayloadException]; never
  /// returns a payload that failed validation.
  factory AmiroSharingPayload.decode(String raw) {
    if (utf8.encode(raw).length > maxSharingPayloadBytes) {
      throw const SharingPayloadException(
        PayloadErrorKind.tooLarge,
        'payload exceeds $maxSharingPayloadBytes bytes',
      );
    }

    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException catch (e) {
      throw SharingPayloadException(
          PayloadErrorKind.malformed, 'not valid JSON: ${e.message}');
    }
    if (json is! Map<String, dynamic>) {
      throw const SharingPayloadException(
          PayloadErrorKind.malformed, 'payload is not a JSON object');
    }

    final version = json['schemaVersion'];
    if (version is! int) {
      throw const SharingPayloadException(
        PayloadErrorKind.malformed,
        'schemaVersion is missing or not an integer',
      );
    }
    if (version != kAmiroSharingSchemaVersion) {
      throw SharingPayloadException(
        PayloadErrorKind.unsupportedVersion,
        'schemaVersion $version is not supported (expected $kAmiroSharingSchemaVersion)',
      );
    }

    final payload = AmiroSharingPayload(
      schemaVersion: version,
      remoteIdentityId: _requiredString(json, 'remoteIdentityId'),
      displayName: _requiredString(json, 'displayName'),
      activeAvatarConfig: _requiredString(json, 'activeAvatarConfig'),
      equippedCosmetics: [
        for (final entry in _requiredList(json, 'equippedCosmetics'))
          _cosmeticFrom(entry),
      ],
      collectionCompletion: [
        for (final entry in _requiredList(json, 'collectionCompletion'))
          _completionFrom(entry),
      ],
    );
    payload.validate();
    return payload;
  }

  /// Validated JSON text ready for a QR code or NFC record. Throws
  /// [SharingPayloadException] rather than emit a payload a receiver would
  /// reject.
  String encode() {
    validate();
    final text = jsonEncode(toJson());
    if (utf8.encode(text).length > maxSharingPayloadBytes) {
      throw const SharingPayloadException(
        PayloadErrorKind.tooLarge,
        'payload exceeds $maxSharingPayloadBytes bytes',
      );
    }
    return text;
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'remoteIdentityId': remoteIdentityId,
        'displayName': displayName,
        'activeAvatarConfig': activeAvatarConfig,
        'equippedCosmetics': [for (final c in equippedCosmetics) c.toJson()],
        'collectionCompletion': [
          for (final s in collectionCompletion) s.toJson()
        ],
      };

  /// Throws [SharingPayloadException] unless every rule holds.
  void validate() {
    if (schemaVersion != kAmiroSharingSchemaVersion) {
      throw SharingPayloadException(
        PayloadErrorKind.unsupportedVersion,
        'schemaVersion $schemaVersion is not supported',
      );
    }
    for (final (name, value) in [
      ('remoteIdentityId', remoteIdentityId),
      ('displayName', displayName),
      ('activeAvatarConfig', activeAvatarConfig),
    ]) {
      if (value.isEmpty) {
        _invalid('$name must not be empty');
      }
    }

    _checkLength('equippedCosmetics', equippedCosmetics.length);
    final cosmeticIds = <String>{};
    for (final c in equippedCosmetics) {
      if (c.id.isEmpty || c.name.isEmpty || c.rarity.isEmpty) {
        _invalid('a cosmetic needs a non-empty id, name and rarity');
      }
      if (c.seriesId != null && c.seriesId!.isEmpty) {
        _invalid('cosmetic ${c.id} has an empty seriesId');
      }
      if (!cosmeticIds.add(c.id)) {
        _invalid('duplicate cosmetic id ${c.id}');
      }
    }

    _checkLength('collectionCompletion', collectionCompletion.length);
    final seriesIds = <String>{};
    for (final s in collectionCompletion) {
      if (s.seriesId.isEmpty) {
        _invalid('a collection entry needs a seriesId');
      }
      if (s.totalCount < 1) {
        _invalid('series ${s.seriesId} needs a totalCount of at least 1');
      }
      if (s.currentCount < 0 || s.currentCount > s.totalCount) {
        _invalid(
            'series ${s.seriesId} count ${s.currentCount} is outside 0..${s.totalCount}');
      }
      if (!seriesIds.add(s.seriesId)) {
        _invalid('duplicate series id ${s.seriesId}');
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AmiroSharingPayload &&
      other.schemaVersion == schemaVersion &&
      other.remoteIdentityId == remoteIdentityId &&
      other.displayName == displayName &&
      other.activeAvatarConfig == activeAvatarConfig &&
      _listEquals(other.equippedCosmetics, equippedCosmetics) &&
      _listEquals(other.collectionCompletion, collectionCompletion);

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        remoteIdentityId,
        displayName,
        activeAvatarConfig,
        Object.hashAll(equippedCosmetics),
        Object.hashAll(collectionCompletion),
      );
}

Never _invalid(String message) =>
    throw SharingPayloadException(PayloadErrorKind.invalid, message);

void _checkLength(String field, int length) {
  if (length > maxSharedListLength) {
    _invalid('$field has more than $maxSharedListLength entries');
  }
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.isEmpty) {
    _invalid('$field is missing or not a non-empty string');
  }
  return value;
}

List<Object?> _requiredList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! List) {
    _invalid('$field is missing or not a list');
  }
  _checkLength(field, value.length);
  return value;
}

EquippedCosmeticInfo _cosmeticFrom(Object? entry) {
  if (entry is! Map<String, dynamic>) {
    _invalid('a cosmetic entry is not an object');
  }
  final seriesId = entry['seriesId'];
  if (seriesId != null && seriesId is! String) {
    _invalid('cosmetic seriesId is not a string');
  }
  return EquippedCosmeticInfo(
    id: _requiredString(entry, 'id'),
    name: _requiredString(entry, 'name'),
    seriesId: seriesId as String?,
    rarity: _requiredString(entry, 'rarity'),
  );
}

SeriesCompletion _completionFrom(Object? entry) {
  if (entry is! Map<String, dynamic>) {
    _invalid('a collection entry is not an object');
  }
  final current = entry['currentCount'];
  final total = entry['totalCount'];
  if (current is! int || total is! int) {
    _invalid('collection counts must be integers');
  }
  return SeriesCompletion(
    seriesId: _requiredString(entry, 'seriesId'),
    currentCount: current,
    totalCount: total,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
