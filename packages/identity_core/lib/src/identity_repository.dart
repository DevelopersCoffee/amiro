import 'identity.dart';

/// Storage boundary for a device's single local Identity.
///
/// This pass supports exactly one identity per device (no multi-profile,
/// no accounts). Swapping the backing store later only touches
/// implementations of this interface.
abstract class IdentityRepository {
  Future<Identity?> getCurrent();
  Future<void> save(Identity identity);
  Future<void> clear();
}
