import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:store/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('purchases_flutter');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'getProductInfo') return <dynamic>[];
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // The catalog's paid items are Play one-time products. The SDK looks up
  // subscriptions unless told otherwise, and Play then returns nothing.
  test('grant looks the product up as a one-time product', () async {
    final store = RevenueCatEntitlementStore(isAndroid: true);

    await expectLater(store.grant('full_beard'), throwsStateError);

    final lookup = calls.singleWhere((c) => c.method == 'getProductInfo');
    expect(lookup.arguments['productIdentifiers'], ['amiro_full_beard']);
    expect(lookup.arguments['type'], 'nonSubscription');
  });

  test('off Android, nothing is owned and purchases are refused', () async {
    final store = RevenueCatEntitlementStore(isAndroid: false);

    expect(await store.ownedCosmeticIds(), isEmpty);
    await expectLater(store.grant('full_beard'), throwsStateError);
    expect(calls, isEmpty);
  });
}
