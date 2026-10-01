import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store/store.dart';

import 'package:amiro_app/store/store_providers.dart';

void main() {
  test('entitlementStoreProvider defaults to the RevenueCat store', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(entitlementStoreProvider),
      isA<RevenueCatEntitlementStore>(),
    );
  });

  // Build 4 shipped with main.dart overriding the provider with a local
  // file store, so Buy granted paid items without opening Play Billing.
  test('main.dart does not override entitlementStoreProvider', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(source, isNot(contains('entitlementStoreProvider.override')));
  });
}
