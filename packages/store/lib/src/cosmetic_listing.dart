/// A single cosmetic item in the Amiro store catalog.
///
/// `assetId` matches the id `AvatarRenderer.updateSlot`/`AvatarDefinition`
/// expect for `slot` — e.g. `slot: 'glasses', assetId: 'glasses_realistic'`.
class CosmeticListing {
  final String id;
  final String slot;
  final String name;
  final String assetId;
  final int priceCents;

  const CosmeticListing({
    required this.id,
    required this.slot,
    required this.name,
    required this.assetId,
    required this.priceCents,
  });

  bool get isFree => priceCents == 0;
}

/// The full Amiro cosmetic catalog.
///
/// Scoped to the cosmetic `.glb` assets that actually exist today in
/// `packages/avatar_renderer/assets/cosmetics/` — see that package's
/// pubspec for the asset list. Names are original (brand-inspired, not
/// real trademarks) per `docs/legal/asset-policy.md`.
const List<CosmeticListing> cosmeticCatalog = [
  CosmeticListing(
    id: 'classic_frame',
    slot: 'glasses',
    name: 'Classic Frame',
    assetId: 'glasses_placeholder',
    priceCents: 0,
  ),
  CosmeticListing(
    id: 'signature_tee',
    slot: 'top',
    name: 'Signature Tee',
    assetId: 'top_placeholder',
    priceCents: 0,
  ),
  CosmeticListing(
    id: 'riviera_optics',
    slot: 'glasses',
    name: 'Riviera Optics',
    assetId: 'glasses_realistic',
    priceCents: 299,
  ),
];
