/// How scarce a cosmetic is, ordered from most to least common.
enum CosmeticRarity {
  common('Common'),
  uncommon('Uncommon'),
  rare('Rare'),
  epic('Epic'),
  legendary('Legendary');

  final String label;
  const CosmeticRarity(this.label);

  /// Upper-case name used on the sharing wire (`RARE`).
  String get wireName => name.toUpperCase();

  /// The tier for a wire name, or null for anything unrecognised (a newer
  /// app's tier must not be guessed at).
  static CosmeticRarity? fromWireName(String wireName) {
    for (final rarity in values) {
      if (rarity.wireName == wireName) return rarity;
    }
    return null;
  }
}

/// A numbered drop, e.g. "Series #1 Founders". Items sharing a [number]
/// must share a [name]; numbers are contiguous from 1 across the catalog.
class CosmeticSeries {
  final int number;
  final String name;

  const CosmeticSeries(this.number, this.name);

  /// Stable id used on the sharing wire (`series_1`).
  String get id => 'series_$number';

  String get label => 'Series #$number \u00b7 $name';
}

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
  final CosmeticRarity rarity;
  final CosmeticSeries? series;

  const CosmeticListing({
    required this.id,
    required this.slot,
    required this.name,
    required this.assetId,
    required this.priceCents,
    this.rarity = CosmeticRarity.common,
    this.series,
  });

  bool get isFree => priceCents == 0;
}

/// The full Amiro cosmetic catalog.
///
/// Scoped to the cosmetic `.glb` assets that actually exist today in
/// `packages/avatar_renderer/assets/cosmetics/` — see that package's
/// pubspec for the asset list. Names are original (brand-inspired, not
/// real trademarks) per `docs/legal/asset-policy.md`.
const _founders = CosmeticSeries(1, 'Founders');

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
    rarity: CosmeticRarity.rare,
    series: _founders,
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
    rarity: CosmeticRarity.uncommon,
    series: _founders,
  ),
  CosmeticListing(
    id: 'full_beard',
    slot: 'facialHair',
    name: 'Full Beard',
    assetId: 'beard_full',
    priceCents: 99,
    rarity: CosmeticRarity.uncommon,
    series: _founders,
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
