import 'dart:io';

import 'package:store/store.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late File file;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('entitlement_store_test');
    file = File('${tempDir.path}/entitlements.json');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('starts empty when no file exists yet', () async {
    final store = FileEntitlementStore(file);
    expect(await store.ownedCosmeticIds(), isEmpty);
  });

  test('a granted cosmetic is owned', () async {
    final store = FileEntitlementStore(file);
    await store.grant('riviera_optics');
    expect(await store.ownedCosmeticIds(), {'riviera_optics'});
  });

  test('granting the same cosmetic twice does not duplicate it', () async {
    final store = FileEntitlementStore(file);
    await store.grant('riviera_optics');
    await store.grant('riviera_optics');
    expect(await store.ownedCosmeticIds(), {'riviera_optics'});
  });

  test('a grant survives a fresh store instance pointed at the same file', () async {
    await FileEntitlementStore(file).grant('riviera_optics');

    final reopened = FileEntitlementStore(file);
    expect(await reopened.ownedCosmeticIds(), {'riviera_optics'});
  });
}
