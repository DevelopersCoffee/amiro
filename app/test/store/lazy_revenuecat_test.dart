import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:identity_core/identity_core.dart';

import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/store/revenue_cat_activation.dart';
import 'package:amiro_app/store/store_providers.dart';
import 'package:store/store.dart';

import '../identity/in_memory_identity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            return r'$RCAnonymousID:test';
          }
          if (call.method == 'logIn') {
            return {
              'customerInfo': <String, dynamic>{
                'entitlements': {
                  'all': {},
                  'active': {},
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
              },
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return <String, dynamic>{
              'entitlements': {
                'all': {},
                'active': {},
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
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  ProviderContainer testContainer() {
    return ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(
          InMemoryIdentityRepository(
            const Identity(id: 't', displayName: 'T', username: 't'),
          ),
        ),
        entitlementStoreProvider.overrideWithValue(
          RevenueCatEntitlementStore(isAndroid: true),
        ),
      ],
    );
  }

  test('owned cosmetics stay empty until RevenueCat is activated', () async {
    final container = testContainer();
    addTearDown(container.dispose);

    expect(await container.read(ownedCosmeticsProvider.future), isEmpty);
    expect(calls.where((c) => c.method == 'setupPurchases'), isEmpty);
  });

  test('StoreScreen with isActive false never calls setupPurchases', () async {
    final container = testContainer();
    addTearDown(container.dispose);

    await container.read(ownedCosmeticsProvider.future);
    expect(calls.where((c) => c.method == 'setupPurchases'), isEmpty);
  });

  test('ensureLoaded configures RevenueCat and fetches entitlements', () async {
    final container = testContainer();
    addTearDown(container.dispose);

    await container.read(ownedCosmeticsProvider.notifier).ensureLoaded();

    expect(container.read(revenueCatActivatedProvider), isTrue);
    expect(calls.any((c) => c.method == 'setupPurchases'), isTrue);
    expect(calls.any((c) => c.method == 'getCustomerInfo'), isTrue);
    expect(calls.any((c) => c.method == 'logIn'), isTrue);
  });
}
