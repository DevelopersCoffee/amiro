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
  final bool _isAndroid;
  bool _configured = false;
  String? _boundAmiroIdentityId;

  /// True after [Purchases.configure] succeeded on this instance.
  bool get isConfigured => _configured;

  /// Last Amiro identity id passed to [bindAmiroIdentity], if any.
  String? get boundAmiroIdentityId => _boundAmiroIdentityId;

  /// [isAndroid] defaults to the real platform; tests pass it explicitly.
  RevenueCatEntitlementStore({bool? isAndroid})
    : _isAndroid = isAndroid ?? Platform.isAndroid;

  /// Ties RevenueCat's App User ID to this device's Amiro identity so
  /// restore cannot silently adopt another profile's entitlements when the
  /// project is set to **Keep with original App User ID** (see
  /// `docs/qa/restore-purchases-device.md`).
  Future<void> bindAmiroIdentity(String identityId) async {
    if (identityId.isEmpty) return;
    _boundAmiroIdentityId = identityId;
    if (_configured) {
      await _ensureLoggedInAsIdentity();
    }
  }

  /// Configuring is idempotent and safe to call from every constructor —
  /// nothing purchase-related can happen before this resolves.
  Future<bool> _ensureConfigured() async {
    if (_configured) return true;
    if (!_isAndroid) {
      // iOS has no App Store Connect credentials registered in RevenueCat
      // yet, so purchases would fail server-side validation — see
      // TODOS.md. Treat iOS as "no purchases available" rather than
      // crashing.
      return false;
    }
    await Purchases.configure(PurchasesConfiguration(revenueCatAndroidApiKey));
    _configured = true;
    await _ensureLoggedInAsIdentity();
    return true;
  }

  Future<void> _ensureLoggedInAsIdentity() async {
    final id = _boundAmiroIdentityId;
    if (id == null || id.isEmpty) return;
    final current = await Purchases.appUserID;
    if (current != id) {
      await Purchases.logIn(id);
    }
  }

  static String _entitlementKey(String cosmeticId) => 'cosmetic_$cosmeticId';
  static String _storeProductId(String cosmeticId) => 'amiro_$cosmeticId';

  Set<String> _ownedFromCustomerInfo(CustomerInfo info) {
    return cosmeticCatalog
        .where(
          (item) =>
              info.entitlements.active.containsKey(_entitlementKey(item.id)),
        )
        .map((item) => item.id)
        .toSet();
  }

  @override
  Future<Set<String>> ownedCosmeticIds() async {
    if (!await _ensureConfigured()) return const {};
    await _ensureLoggedInAsIdentity();
    final info = await Purchases.getCustomerInfo();
    return _ownedFromCustomerInfo(info);
  }

  @override
  Future<RestoreOutcome> restore() async {
    if (!await _ensureConfigured()) {
      return const RestoreOutcome.unavailable();
    }
    await _ensureLoggedInAsIdentity();
    final before = await ownedCosmeticIds();
    try {
      final info = await Purchases.restorePurchases();
      final after = _ownedFromCustomerInfo(info);
      final gained = after.difference(before);
      if (gained.isNotEmpty) {
        return RestoreOutcome.restored(gained);
      }
      return const RestoreOutcome.nothingToRestore();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.receiptAlreadyInUseError ||
          code == PurchasesErrorCode.receiptInUseByOtherSubscriberError) {
        throw const RestoreOwnershipConflictException();
      }
      rethrow;
    }
  }

  /// RevenueCat's id for this install. The same Google account on another
  /// phone still restores purchases through [restore]; this id is only the
  /// join key stored next to the profile in Supabase.
  Future<String?> appUserId() async {
    if (!await _ensureConfigured()) return null;
    await _ensureLoggedInAsIdentity();
    return Purchases.appUserID;
  }

  @override
  Future<void> grant(String cosmeticId) async {
    if (!await _ensureConfigured()) {
      throw StateError(
        'Purchases are only available on Android until iOS store '
        'credentials are configured in RevenueCat.',
      );
    }
    await _ensureLoggedInAsIdentity();
    final storeId = _storeProductId(cosmeticId);
    // Catalog items are Play one-time products; getProducts looks up
    // subscriptions unless told otherwise and would find nothing.
    final products = await Purchases.getProducts([
      storeId,
    ], productCategory: ProductCategory.nonSubscription);
    if (products.isEmpty) {
      throw StateError('No store product found for "$storeId".');
    }
    try {
      await Purchases.purchase(PurchaseParams.storeProduct(products.first));
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }
      if (PurchasesErrorHelper.getErrorCode(e) ==
              PurchasesErrorCode.receiptAlreadyInUseError ||
          PurchasesErrorHelper.getErrorCode(e) ==
              PurchasesErrorCode.receiptInUseByOtherSubscriberError) {
        throw const RestoreOwnershipConflictException();
      }
      rethrow;
    }
    // A successful purchaseStoreProduct means RevenueCat's on-device
    // CustomerInfo cache already reflects the new entitlement — no need
    // to re-fetch here.
  }
}