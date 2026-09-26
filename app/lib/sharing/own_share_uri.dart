import 'package:identity_core/identity_core.dart';
import 'package:sharing/sharing.dart';
import 'package:store/store.dart';

/// The URI behind this user's QR code / NFC tag: their public identity plus
/// the cosmetics they've collected (free items and purchases), so the person
/// scanning sees their identity card, not just a name.
String buildOwnShareUri(Identity identity, Set<String> purchasedCosmeticIds) {
  return buildShareUri(
    identity,
    ownedCosmeticIds: collectedCosmeticIds(
      cosmeticCatalog,
      purchasedCosmeticIds,
    ),
  );
}
