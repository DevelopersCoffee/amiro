import 'dart:math';

/// A new random identity id: 16 bytes from a cryptographic RNG, hex-encoded.
///
/// Not derived from the clock. Two identities created in the same
/// microsecond must not collide, and nothing else should key off a
/// timestamp embedded in the id.
///
/// [random] exists for tests. Production callers omit it.
String newIdentityId({Random? random}) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
