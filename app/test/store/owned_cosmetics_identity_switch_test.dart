import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';
import 'package:store/store.dart';

import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/store/store_providers.dart';

import '../identity/in_memory_identity_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');

  test('switching identity clears owned cosmetics from memory', () async {
    const identityA = Identity(
      id: 'identity-a',
      displayName: 'A',
      username: 'a',
    );
    const identityB = Identity(
      id: 'identity-b',
      displayName: 'B',
      username: 'b',
    );

    final entitlementsByUser = <String, Map<String, dynamic>>{
      'identity-a': {
        'cosmetic_riviera_optics': {
          'identifier': 'cosmetic_riviera_optics',
          'isActive': true,
          'willRenew': false,
          'latestPurchaseDate': '2026-10-01T00:00:00Z',
          'originalPurchaseDate': '2026-10-01T00:00:00Z',
          'productIdentifier': 'amiro_riviera_optics',
          'isSandbox': true,
          'ownershipType': 'PURCHASED',
          'store': 'PLAY_STORE',
          'periodType': 'NORMAL',
        },
      },
      'identity-b': {},
    };
    String? appUserId;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            return appUserId ?? r'$RCAnonymousID:test';
          }
          if (call.method == 'logIn') {
            appUserId = call.arguments['appUserID'] as String;
            return {
              'customerInfo': _info(entitlementsByUser[appUserId] ?? {}),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return _info(entitlementsByUser[appUserId ?? 'identity-a'] ?? {});
          }
          if (call.method == 'restorePurchases') {
            return _info(entitlementsByUser[appUserId ?? 'identity-a'] ?? {});
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final repo = InMemoryIdentityRepository(identityA);
    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repo),
        entitlementStoreProvider.overrideWithValue(
          RevenueCatEntitlementStore(isAndroid: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(ownedCosmeticsProvider.notifier).ensureLoaded();
    expect(
      container.read(ownedCosmeticsProvider).value,
      contains('riviera_optics'),
    );

    await container.read(currentIdentityProvider.notifier).save(identityB);
    await Future<void>.value();

    expect(container.read(ownedCosmeticsProvider).value, isEmpty);
  });

  test('identity required before restore on RevenueCat store', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);
    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(
          InMemoryIdentityRepository(null),
        ),
        entitlementStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(ownedCosmeticsProvider.notifier).restore(),
      throwsA(isA<RevenueCatIdentityRequiredException>()),
    );
  });
}

Map<String, dynamic> _info(Map<String, dynamic> active) => {
      'entitlements': {
        'all': active,
        'active': active,
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