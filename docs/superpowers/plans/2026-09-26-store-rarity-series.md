<!-- /autoplan restore point: "/Users/udaychauhan/.gstack/projects/udaychauhan/avatar-framing-lighting-autoplan-restore-20260926-091443.md" -->
# Store rarity tiers and numbered cosmetic series

## Implementation plan

**Goal:** Add rarity tiers and numbered cosmetic series to `packages/store`, inspired by the Steam "Egg" market (common $0.03 items next to a $171 grail, "Series #N" drops, meme/cultural skins as the top tier). Purchases stay stubbed. No resale or trading market. Tie rarity into avatar valuation.

**Context (from repo):**
- `packages/store/lib/src/cosmetic_listing.dart`: `CosmeticListing {id, slot, name, assetId, priceCents}` and a const `cosmeticCatalog` of 7 items (hair x3, glasses x2, top x1, beard x1). Only assets that exist as `.glb` are listed.
- `packages/store/lib/src/avatar_valuation.dart`: `avatarValuationCents` sums `priceCents` of equipped items.
- `app/lib/store/store_screen.dart` renders the catalog with a preview and a stubbed Buy button. `app/lib/avatar/avatar_screen.dart` shows valuation in the app bar.
- DESIGN.md (brass on warm charcoal, Instrument fonts) governs all visual choices. Legal policy: original names, no real trademarks (`docs/legal/asset-policy.md`), so real memes (Cheems, Wojak) are out; use original meme-flavored themes.

**Changes:**
1. Add `enum CosmeticRarity { common, uncommon, rare, epic, legendary }` with a display label and a DESIGN.md-token color mapping (in `app/`, not the package).
2. Add `rarity` (required, default `common` at call sites) and optional `series` (`CosmeticSeries {number, name}`) to `CosmeticListing`. Keep `priceCents` as the source of truth for price.
3. Re-tag the 7 existing items with rarity; no new assets are added, so no new items.
4. Extend `avatarValuationCents` unchanged in meaning (sum of price), and add `avatarRarityScore(definition, catalog)` returning the highest rarity equipped plus a per-tier count, so the UI can show "2 rare, 1 common".
5. `StoreScreen`: show a rarity chip on each item, a series header ("Series #1 - Founders") grouping when `series` is set, and sort/filter by rarity.
6. `AvatarScreen`: show the highest equipped rarity next to the valuation.
7. Tests (TDD): catalog invariants (unique ids, every item has a rarity, series numbers are positive and contiguous), rarity score math, widget tests for chip and series grouping.
8. Docs: add a short "Rarity and series" section to `docs/product/requirements.md` Monetization; note the deferred resale market in TODOS.md.

**Out of scope:** resale/trading market, real payments, licensed meme content, new 3D assets, server-side supply caps.

**Test plan:** `melos run test` and `melos run analyze` green; new unit tests in `packages/store/test/`; widget tests in `app/test/store/`.

## Review record

