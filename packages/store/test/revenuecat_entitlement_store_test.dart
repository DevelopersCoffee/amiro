import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:store/store.dart';

Map<String, dynamic> _catalogEntitlement(String key, String productId) => {
      'identifier': key,
      'isActive': true,
      'willRenew': false,
      'latestPurchaseDate': '2026-10-01T00:00:00Z',
      'originalPurchaseDate': '2026-10-01T00:00:00Z',
      'productIdentifier': productId,
      'isSandbox': true,
      'ownershipType': 'PURCHASED',
      'store': 'PLAY_STORE',
      'periodType': 'NORMAL',
    };

Map<String, dynamic> _storeProductJson(String storeId) => {
      'identifier': storeId,
      'description': 'desc',
      'title': 'title',
      'price': 0.99,
      'priceString': r'$0.99',
      'currencyCode': 'USD',
      'productCategory': 'nonSubscription',
    };

Map<String, dynamic> _purchaseResultJson(Map<String, dynamic> activeEntitlements) => {
      'customerInfo': _customerInfoJson(activeEntitlements),
      'transaction': {
        'transactionIdentifier': 'tx-1',
        'productIdentifier': 'amiro_full_beard',
        'purchaseDate': '2026-10-01T00:00:00Z',
      },
    };

Map<String, dynamic> _customerInfoJson(Map<String, dynamic> activeEntitlements) {
  return <String, dynamic>{
    'entitlements': {
      'all': activeEntitlements,
      'active': activeEntitlements,
      'verification': 'NOT_REQUESTED',
    },
    'allPurchasedProductIdentifiers': [],
    'activeSubscriptions': [],
    'latestExpirationDate': null,
    'firstSeen': '2026-10-01T00:00:00Z',
    'originalAppUserId': 'test',
    'requestDate': '2026-10-01T00:00:00Z',
    'allExpirationDates': {},
    'allPurchaseDates': {},
    'originalApplicationVersion': null,
    'originalPurchaseDate': null,
    'managementURL': null,
    'nonSubscriptionTransactions': [],
    'subscriptionsByProductIdentifier': {},
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');
  final calls = <MethodCall>[];
  Map<String, dynamic> activeEntitlements = {};
  String? boundAppUserId;

  setUp(() {
    calls.clear();
    activeEntitlements = {};
    boundAppUserId = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            return boundAppUserId ?? r'$RCAnonymousID:test';
          }
          if (call.method == 'logIn') {
            boundAppUserId = call.arguments['appUserID'] as String;
            return {
              'customerInfo': _customerInfoJson(activeEntitlements),
              'created': false,
            };
          }
          if (call.method == 'logOut') {
            boundAppUserId = r'$RCAnonymousID:logged-out';
            return _customerInfoJson({});
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfoJson(activeEntitlements);
          }
          if (call.method == 'getProductInfo') return <dynamic>[];
          if (call.method == 'purchaseProduct') {
            return _purchaseResultJson(activeEntitlements);
          }
          if (call.method == 'restorePurchases') {
            return _customerInfoJson(activeEntitlements);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('restore rejects unbound identity before restorePurchases', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);

    await expectLater(
      store.restore(),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );

    expect(calls.map((c) => c.method), isNot(contains('restorePurchases')));
  });

  test('grant rejects unbound identity before product lookup', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);

    await expectLater(
      store.grant('full_beard'),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );

    expect(calls.map((c) => c.method), isNot(contains('getProductInfo')));
  });

  test('bindAmiroIdentity rejects empty id', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);

    await expectLater(
      store.bindAmiroIdentity(''),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );
  });

  test('restore calls logIn before restorePurchases', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('amiro-identity-1');
    await store.restore();

    final loginIdx = calls.indexWhere((c) => c.method == 'logIn');
    final restoreIdx = calls.indexWhere((c) => c.method == 'restorePurchases');
    expect(loginIdx, greaterThanOrEqualTo(0));
    expect(restoreIdx, greaterThan(loginIdx));
  });

  test('grant completes purchase after logIn in call order', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('amiro-identity-1');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            return boundAppUserId ?? r'$RCAnonymousID:test';
          }
          if (call.method == 'logIn') {
            boundAppUserId = call.arguments['appUserID'] as String;
            return {
              'customerInfo': _customerInfoJson({}),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfoJson(activeEntitlements);
          }
          if (call.method == 'getProductInfo') {
            return [
              _storeProductJson('amiro_full_beard'),
            ];
          }
          if (call.method == 'purchaseProduct') {
            activeEntitlements = {
              'cosmetic_full_beard': _catalogEntitlement(
                'cosmetic_full_beard',
                'amiro_full_beard',
              ),
            };
            return _purchaseResultJson(activeEntitlements);
          }
          return null;
        });

    await store.grant('full_beard');

    final loginIdx = calls.indexWhere((c) => c.method == 'logIn');
    final lookupIdx = calls.indexWhere((c) => c.method == 'getProductInfo');
    final purchaseIdx = calls.indexWhere((c) => c.method == 'purchaseProduct');
    expect(loginIdx, greaterThanOrEqualTo(0));
    expect(lookupIdx, greaterThan(loginIdx));
    expect(purchaseIdx, greaterThan(lookupIdx));
    expect(await store.ownedCosmeticIds(), contains('full_beard'));
  });

  test('grant rejects anonymous app user id after logIn', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            boundAppUserId = r'$RCAnonymousID:still-anon';
            return {
              'customerInfo': _customerInfoJson({}),
              'created': false,
            };
          }
          if (call.method == 'getAppUserID') {
            return boundAppUserId ?? r'$RCAnonymousID:still-anon';
          }
          return null;
        });

    await store.bindAmiroIdentity('amiro-identity-1');

    await expectLater(
      store.grant('full_beard'),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );
    expect(calls.map((c) => c.method), isNot(contains('getProductInfo')));
  });

  test('grant logIn failure throws before purchaseProduct', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('amiro-identity-1');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            throw PlatformException(code: '1', message: 'login failed');
          }
          if (call.method == 'getAppUserID') return r'$RCAnonymousID:test';
          if (call.method == 'getProductInfo') {
            return [_storeProductJson('amiro_full_beard')];
          }
          return null;
        });

    await expectLater(
      store.grant('full_beard'),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );
    expect(calls.map((c) => c.method), isNot(contains('purchaseProduct')));
  });

  test('grant maps receipt conflict to RestoreOwnershipConflictException',
      () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('user-a');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') return 'user-a';
          if (call.method == 'logIn') {
            return {
              'customerInfo': _customerInfoJson({}),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfoJson({});
          }
          if (call.method == 'getProductInfo') {
            return [_storeProductJson('amiro_full_beard')];
          }
          if (call.method == 'purchaseProduct') {
            throw PlatformException(
              code: '${PurchasesErrorCode.receiptInUseByOtherSubscriberError.index}',
              message: 'Receipt in use',
            );
          }
          return null;
        });

    await expectLater(
      store.grant('full_beard'),
      throwsA(isA<RestoreOwnershipConflictException>()),
    );
  });

  test('grant aborts when appUserID no longer matches before purchase',
      () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('user-a');
    var appUserReads = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            appUserReads++;
            if (appUserReads >= 2) return 'someone-else';
            return 'user-a';
          }
          if (call.method == 'logIn') {
            return {
              'customerInfo': _customerInfoJson({}),
              'created': false,
            };
          }
          if (call.method == 'getProductInfo') {
            return [_storeProductJson('amiro_full_beard')];
          }
          return null;
        });

    await expectLater(
      store.grant('full_beard'),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );
    expect(calls.map((c) => c.method), isNot(contains('purchaseProduct')));
  });

  test('rejects anonymous app user id after logIn', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            boundAppUserId = r'$RCAnonymousID:still-anon';
            return {
              'customerInfo': _customerInfoJson({}),
              'created': false,
            };
          }
          if (call.method == 'getAppUserID') {
            return boundAppUserId ?? r'$RCAnonymousID:still-anon';
          }
          return null;
        });

    await store.bindAmiroIdentity('amiro-identity-1');

    await expectLater(
      store.restore(),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );
    expect(calls.map((c) => c.method), isNot(contains('restorePurchases')));
  });

  test('logIn network error throws RevenueCatOfflineException', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('amiro-identity-1');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            throw PlatformException(
              code: '${PurchasesErrorCode.networkError.index}',
              message: 'offline',
            );
          }
          if (call.method == 'getAppUserID') return r'$RCAnonymousID:test';
          return null;
        });

    await expectLater(
      store.restore(),
      throwsA(isA<RevenueCatOfflineException>()),
    );
  });

  test('logIn failure throws RevenueCatIdentityRequiredException', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('amiro-identity-1');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'logIn') {
            throw PlatformException(code: '1', message: 'login failed');
          }
          if (call.method == 'getAppUserID') return r'$RCAnonymousID:test';
          if (call.method == 'getCustomerInfo') {
            return _customerInfoJson({});
          }
          return null;
        });

    await expectLater(
      store.restore(),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );
    expect(calls.map((c) => c.method), isNot(contains('restorePurchases')));
  });

  test('restore reports nothingToRestore when entitlements stay empty', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('amiro-identity-1');

    final outcome = await store.restore();

    expect(outcome, isA<RestoreNothingToRestore>());
  });

  test('restore reports restored when new entitlements appear', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('amiro-identity-1');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            return boundAppUserId ?? 'amiro-identity-1';
          }
          if (call.method == 'logIn') {
            boundAppUserId = call.arguments['appUserID'] as String;
            return {
              'customerInfo': _customerInfoJson({}),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return _customerInfoJson({});
          }
          if (call.method == 'restorePurchases') {
            return _customerInfoJson({
              'cosmetic_riviera_optics': _catalogEntitlement(
                'cosmetic_riviera_optics',
                'amiro_riviera_optics',
              ),
            });
          }
          return null;
        });

    final outcome = await store.restore();

    expect(outcome, isA<RestoreHadPurchases>());
    final restored = outcome as RestoreHadPurchases;
    expect(restored.newlyOwned, contains('riviera_optics'));
  });

  test('restore maps receipt conflict to RestoreOwnershipConflictException',
      () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('user-a');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getCustomerInfo') {
            return _customerInfoJson({});
          }
          if (call.method == 'getAppUserID') return 'user-a';
          if (call.method == 'logIn') {
            return {
              'customerInfo': _customerInfoJson({}),
              'created': false,
            };
          }
          if (call.method == 'restorePurchases') {
            throw PlatformException(
              code: '${PurchasesErrorCode.receiptAlreadyInUseError.index}',
              message: 'Receipt already in use',
            );
          }
          return null;
        });

    await expectLater(
      store.restore(),
      throwsA(isA<RestoreOwnershipConflictException>()),
    );
  });

  test('logOutAmiroIdentity calls RevenueCat logOut', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('amiro-identity-1');
    await store.restore();
    await store.logOutAmiroIdentity();

    expect(calls.map((c) => c.method), contains('logOut'));
    expect(store.boundAmiroIdentityId, isNull);
  });

  test('off Android, restore is unavailable', () async {
    final store = RevenueCatEntitlementStore(isAndroid: false);

    final outcome = await store.restore();

    expect(outcome, isA<RestoreUnavailable>());
    expect(calls, isEmpty);
  });

  test('off Android, nothing is owned and purchases are refused', () async {
    final store = RevenueCatEntitlementStore(isAndroid: false);

    expect(await store.ownedCosmeticIds(), isEmpty);
    await expectLater(store.grant('full_beard'), throwsStateError);
    expect(calls, isEmpty);
  });

  test('configure runs setupPurchases only once across parallel callers',
      () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('a');
    await Future.wait([store.restore(), store.restore()]);

    expect(
      calls.where((c) => c.method == 'setupPurchases').length,
      1,
    );
  });

  test('identity bind grant and restore share one operation lock', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    await store.bindAmiroIdentity('a');
    var inFlight = 0;
    var maxInFlight = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          inFlight++;
          maxInFlight = maxInFlight < inFlight ? inFlight : maxInFlight;
          try {
            if (call.method == 'setupPurchases') return null;
            if (call.method == 'getAppUserID') return 'a';
            if (call.method == 'logIn') {
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return {
                'customerInfo': _customerInfoJson({}),
                'created': false,
              };
            }
            if (call.method == 'getCustomerInfo') {
              return _customerInfoJson({});
            }
            if (call.method == 'restorePurchases') {
              await Future<void>.delayed(const Duration(milliseconds: 20));
              return _customerInfoJson({});
            }
            if (call.method == 'getProductInfo') {
              return [_storeProductJson('amiro_full_beard')];
            }
            if (call.method == 'purchaseProduct') {
              return _purchaseResultJson({});
            }
            return null;
          } finally {
            inFlight--;
          }
        });

    await Future.wait([
      store.restore(),
      store.bindAmiroIdentity('b'),
    ]);

    expect(maxInFlight, 1);
  });
}