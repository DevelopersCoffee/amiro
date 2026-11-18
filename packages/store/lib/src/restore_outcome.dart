/// Result of [EntitlementStore.restore] when the store account responded.
sealed class RestoreOutcome {
  const RestoreOutcome();

  /// Play (or RevenueCat) reported active entitlements that were not visible
  /// to the app before this restore call.
  const factory RestoreOutcome.restored(Set<String> newlyOwned) =
      RestoreHadPurchases;

  /// Restore completed but nothing new was attached to this Amiro identity.
  const factory RestoreOutcome.nothingToRestore() = RestoreNothingToRestore;

  /// Purchases are unavailable on this platform (e.g. iOS without store creds).
  const factory RestoreOutcome.unavailable() = RestoreUnavailable;
}

final class RestoreHadPurchases extends RestoreOutcome {
  final Set<String> newlyOwned;
  const RestoreHadPurchases(this.newlyOwned);
}

final class RestoreNothingToRestore extends RestoreOutcome {
  const RestoreNothingToRestore();
}

final class RestoreUnavailable extends RestoreOutcome {
  const RestoreUnavailable();
}

/// Thrown when purchase or restore would run without a bound Amiro identity
/// or while RevenueCat still reports an anonymous App User ID.
class RevenueCatIdentityRequiredException implements Exception {
  const RevenueCatIdentityRequiredException();

  @override
  String toString() =>
      'RevenueCat purchases require an Amiro identity to be set up first.';
}

/// Thrown when RevenueCat cannot reach its servers (e.g. logIn while offline).
class RevenueCatOfflineException implements Exception {
  const RevenueCatOfflineException();

  @override
  String toString() => 'RevenueCat is offline.';
}

/// Thrown when RevenueCat refuses to attach a receipt because it belongs to a
/// different identified App User ID ([PurchasesErrorCode.receiptAlreadyInUseError]
/// or [PurchasesErrorCode.receiptInUseByOtherSubscriberError]) — expected when
/// the project uses **Keep with original App User ID** and another Amiro
/// identity tries to restore on the same Play account.
class RestoreOwnershipConflictException implements Exception {
  const RestoreOwnershipConflictException();

  @override
  String toString() =>
      'These purchases belong to another Amiro identity on this device.';
}