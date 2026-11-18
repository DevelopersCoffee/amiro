import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';
import 'package:store/store.dart';

import 'package:amiro_app/identity/identity_providers.dart';
import 'package:amiro_app/store/revenue_cat_activation.dart';
import 'package:amiro_app/store/store_providers.dart';

import '../identity/in_memory_identity_repository.dart';

Future<void> waitUntil(
  bool Function() condition, {
  String? reason,
}) async {
  for (var i = 0; i < 200; i++) {
  await Future<void>.delayed(const Duration(milliseconds: 5));
    if (condition()) return;
  }
  fail(reason ?? 'condition not met before timeout');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');

  Map<String, dynamic> entitlement(String key, String productId) => {
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

  ProviderContainer containerWithMocks({
    required InMemoryIdentityRepository repo,
    required void Function(MethodCall call) onCall,
    Map<String, Map<String, dynamic>>? entitlementsByUser,
  }) {
  String? appUserId;
    final entitlements =
        entitlementsByUser ??
        <String, Map<String, dynamic>>{
          'identity-a': {
            'cosmetic_riviera_optics': entitlement(
              'cosmetic_riviera_optics',
              'amiro_riviera_optics',
            ),
          },
          'identity-b': {
            'cosmetic_full_beard': entitlement(
              'cosmetic_full_beard',
              'amiro_full_beard',
            ),
          },
        };
    final calls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          onCall(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            return appUserId ?? r'$RCAnonymousID:test';
          }
          if (call.method == 'logIn') {
            appUserId = call.arguments['appUserID'] as String;
            return {
              'customerInfo': _info(entitlements[appUserId] ?? {}),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            final uid = appUserId;
            return _info(entitlements[uid] ?? {});
          }
          if (call.method == 'logOut') {
            appUserId = r'$RCAnonymousID:logged-out';
            return _info({});
          }
          if (call.method == 'restorePurchases') {
            final uid = appUserId;
            return _info(entitlements[uid] ?? {});
          }
          return null;
        });

    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repo),
        entitlementStoreProvider.overrideWithValue(
          RevenueCatEntitlementStore(isAndroid: true),
        ),
      ],
    );

    return container;
  }

  test('switching identity clears owned cosmetics from memory', () async {
    final repo = InMemoryIdentityRepository(
      const Identity(id: 'identity-a', displayName: 'A', username: 'a'),
    );
    final container = containerWithMocks(repo: repo, onCall: (_) {});
    addTearDown(() {
      container.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await container.read(ownedCosmeticsProvider.notifier).ensureLoaded();
    expect(
      container.read(ownedCosmeticsProvider).value,
      contains('riviera_optics'),
    );

    await container
        .read(currentIdentityProvider.notifier)
        .save(const Identity(id: 'identity-b', displayName: 'B', username: 'b'));

    await waitUntil(
      () => container.read(ownedCosmeticsProvider).value?.contains('full_beard') ?? false,
      reason: 'expected identity-b entitlements after switch',
    );
    expect(
      container.read(ownedCosmeticsProvider).value,
      isNot(contains('riviera_optics')),
    );
  });

  test('identity switch calls logIn for the new identity id', () async {
    final calls = <MethodCall>[];
    final repo = InMemoryIdentityRepository(
      const Identity(id: 'identity-a', displayName: 'A', username: 'a'),
    );

    String? appUserId;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            return appUserId ?? r'$RCAnonymousID:test';
          }
          if (call.method == 'logIn') {
            appUserId = call.arguments['appUserID'] as String;
            return {
              'customerInfo': _info({}),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') return _info({});
          return null;
        });

    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repo),
        entitlementStoreProvider.overrideWithValue(
          RevenueCatEntitlementStore(isAndroid: true),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await container.read(ownedCosmeticsProvider.notifier).ensureLoaded();

    await container.read(currentIdentityProvider.notifier).save(
          const Identity(id: 'identity-b', displayName: 'B', username: 'b'),
        );
    await waitUntil(
      () => calls.any(
        (c) => c.method == 'logIn' && c.arguments['appUserID'] == 'identity-b',
      ),
      reason: 'expected logIn(identity-b) on switch',
    );
  });

  test('failed logIn on identity switch clears owned and deactivates RC',
      () async {
    var failBLogin = false;
    final repo = InMemoryIdentityRepository(
      const Identity(id: 'identity-a', displayName: 'A', username: 'a'),
    );

    String? appUserId;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'setupPurchases') return null;
          if (call.method == 'getAppUserID') {
            return appUserId ?? r'$RCAnonymousID:test';
          }
          if (call.method == 'logIn') {
            final id = call.arguments['appUserID'] as String;
            if (id == 'identity-b' && failBLogin) {
              throw PlatformException(code: '1', message: 'login failed');
            }
            appUserId = id;
            return {
              'customerInfo': _info(
                id == 'identity-a'
                    ? {
                        'cosmetic_riviera_optics': entitlement(
                          'cosmetic_riviera_optics',
                          'amiro_riviera_optics',
                        ),
                      }
                    : {},
              ),
              'created': false,
            };
          }
          if (call.method == 'getCustomerInfo') {
            return _info(
              appUserId == 'identity-a'
                  ? {
                      'cosmetic_riviera_optics': entitlement(
                        'cosmetic_riviera_optics',
                        'amiro_riviera_optics',
                      ),
                    }
                  : {},
            );
          }
          return null;
        });

    final container = ProviderContainer(
      overrides: [
        identityRepositoryProvider.overrideWithValue(repo),
        entitlementStoreProvider.overrideWithValue(
          RevenueCatEntitlementStore(isAndroid: true),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await container.read(ownedCosmeticsProvider.notifier).ensureLoaded();
    expect(
      container.read(ownedCosmeticsProvider).value,
      contains('riviera_optics'),
    );

    failBLogin = true;
    await container.read(currentIdentityProvider.notifier).save(
          const Identity(id: 'identity-b', displayName: 'B', username: 'b'),
        );
    await waitUntil(
      () => container.read(revenueCatActivatedProvider) == false,
      reason: 'expected RC deactivated after failed logIn',
    );
    expect(container.read(ownedCosmeticsProvider).value, isEmpty);
  });

  test('switching to null identity calls logOut and clears owned', () async {
    final calls = <MethodCall>[];
    final repo = InMemoryIdentityRepository(
      const Identity(id: 'identity-a', displayName: 'A', username: 'a'),
    );
    final container = containerWithMocks(
      repo: repo,
      onCall: calls.add,
    );
    addTearDown(() {
      container.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await container.read(ownedCosmeticsProvider.notifier).ensureLoaded();
    expect(
      container.read(ownedCosmeticsProvider).value,
      contains('riviera_optics'),
    );

    await repo.clear();
    container.invalidate(currentIdentityProvider);
    await container.read(currentIdentityProvider.future);

    await waitUntil(
      () => calls.any((c) => c.method == 'logOut'),
      reason: 'expected logOut on identity clear',
    );
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