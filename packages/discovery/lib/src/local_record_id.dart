import 'dart:math';

const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford base32

/// A new ULID-style id for an [EncounterRecord.localRecordId]: 48 bits of
/// millisecond time then 80 random bits, 26 characters that sort by
/// creation time. Independent of the remote identity id, so a record
/// survives the other side rotating or migrating their identity.
///
/// [now] and [random] exist for tests.
String newLocalRecordId({DateTime? now, Random? random}) {
  final rng = random ?? Random.secure();
  var time = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch;

  final chars = List<String>.filled(26, '0');
  for (var i = 9; i >= 0; i--) {
    chars[i] = _alphabet[time % 32];
    time ~/= 32;
  }
  for (var i = 10; i < 26; i++) {
    chars[i] = _alphabet[rng.nextInt(32)];
  }
  return chars.join();
}
