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
  CosmeticListing(
    id: 'clean_part',
    slot: 'hair',
    name: 'Clean Part',
    assetId: 'hair_simple_parted',
    priceCents: 0,
  ),
  CosmeticListing(
    id: 'buzz_cut',
    slot: 'hair',
    name: 'Buzz Cut',
    assetId: 'hair_buzzed',
    priceCents: 0,
  ),
  CosmeticListing(
    id: 'long_flow',
    slot: 'hair',
    name: 'Long Flow',
    assetId: 'hair_long',
    priceCents: 199,
  ),
  CosmeticListing(
    id: 'full_beard',
    slot: 'facialHair',
    name: 'Full Beard',
    assetId: 'beard_full',
    priceCents: 99,
  ),
  CosmeticListing(
    id: 'village_tunic',
    slot: 'top',
    name: 'Village Tunic',
    assetId: 'top_peasant_shirt',
    priceCents: 0,
  ),
  CosmeticListing(
    id: 'village_trousers',
    slot: 'bottom',
    name: 'Village Trousers',
    assetId: 'bottom_peasant_trousers',
    priceCents: 0,
  ),
  CosmeticListing(
    id: 'leather_boots',
    slot: 'shoes',
    name: 'Leather Boots',
    assetId: 'shoes_peasant_boots',
    priceCents: 0,
  ),
];
