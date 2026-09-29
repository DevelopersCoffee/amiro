import 'dart:io';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'cosmetic_listing.dart';
import 'entitlement_store.dart';
import 'revenuecat_keys.dart';

/// Backs [EntitlementStore] with real Play Billing purchases via
/// RevenueCat. Catalog ids map to RevenueCat objects by convention (see
/// `rc products list` / `rc entitlements list` in the RevenueCat project):
/// store product id `amiro_<id>`, entitlement lookup key `cosmetic_<id>`.
class RevenueCatEntitlementStore implements EntitlementStore {
  bool _configured = false;

  /// Configuring is idempotent and safe to call from every constructor —
  /// nothing purchase-related can happen before this resolves.
  Future<bool> _ensureConfigured() async {
    if (_configured) return true;
    if (!Platform.isAndroid) {
      // iOS has no App Store Connect credentials registered in RevenueCat
      // yet, so purchases would fail server-side validation — see
      // TODOS.md. Treat iOS as "no purchases available" rather than
      // crashing.
      return false;
    }
    await Purchases.configure(
      PurchasesConfiguration(revenueCatAndroidApiKey),
    );
    _configured = true;
    return true;
  }

  static String _entitlementKey(String cosmeticId) => 'cosmetic_$cosmeticId';
  static String _storeProductId(String cosmeticId) => 'amiro_$cosmeticId';

  @override
  Future<Set<String>> ownedCosmeticIds() async {
    if (!await _ensureConfigured()) return const {};
    final info = await Purchases.getCustomerInfo();
    return cosmeticCatalog
        .where(
          (item) =>
              info.entitlements.active.containsKey(_entitlementKey(item.id)),
        )
        .map((item) => item.id)
        .toSet();
  }

  @override
  Future<void> grant(String cosmeticId) async {
    if (!await _ensureConfigured()) {
      throw StateError(
        'Purchases are only available on Android until iOS store '
        'credentials are configured in RevenueCat.',
      );
    }
    final storeId = _storeProductId(cosmeticId);
    final products = await Purchases.getProducts([storeId]);
    if (products.isEmpty) {
      throw StateError('No store product found for "$storeId".');
    }
    try {
      await Purchases.purchase(
        PurchaseParams.storeProduct(products.first),
      );
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }
      rethrow;
    }
    // A successful purchaseStoreProduct means RevenueCat's on-device
    // CustomerInfo cache already reflects the new entitlement — no need
    // to re-fetch here.
  }
}
