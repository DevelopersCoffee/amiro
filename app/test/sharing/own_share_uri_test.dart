import 'package:flutter_test/flutter_test.dart';
import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';

import 'package:amiro_app/sharing/own_share_uri.dart';

void main() {
  final identity = Identity(id: 'id-1', displayName: 'Uday', username: 'uday');

  test('shares free items plus purchases', () {
    final shared = parseShareUri(
      buildOwnShareUri(identity, {'riviera_optics'}),
    )!.ownedCosmeticIds;

    expect(shared, contains('riviera_optics'));
    expect(shared, contains('classic_frame')); // a free item
  });

  test('does not share a paid item that was not bought', () {
    final shared = parseShareUri(
      buildOwnShareUri(identity, {'riviera_optics'}),
    )!.ownedCosmeticIds;

    expect(shared, isNot(contains('long_flow')));
  });

  test('stays under the payload cap with the full catalog owned', () {
    final shared = parseShareUri(
      buildOwnShareUri(identity, {'riviera_optics', 'long_flow', 'full_beard'}),
    )!.ownedCosmeticIds;

    expect(shared.length, lessThanOrEqualTo(maxSharedCosmeticIds));
  });
}
