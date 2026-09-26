# TODOS

Design debt surfaced by `/plan-design-review` (2026-09-23), branch diff review
of `app/lib/avatar/avatar_screen.dart` + cosmetic asset swap.

## 1. Branded loading state for avatar screen — DONE (2026-09-23)
[avatar_loading_indicator.dart](app/lib/avatar/avatar_loading_indicator.dart): a silhouette shape (DESIGN.md tokens, no glow) with an opacity pulse + "Waking up your Amiro…", shown while `ensureAvatarLoaded` is in flight. `AvatarScreen` tracks `_loading` and swaps it for `renderer.buildView()` once the load resolves. TDD'd with a gated fake renderer (`_GatedLoadRenderer` in `avatar_screen_test.dart`) so the test controls exactly when the load resolves.

## 2. Reveal ceremony on first avatar creation — DONE (2026-09-23)
`ensureAvatarLoaded` now returns `AvatarLoadResult` (`{definition, isFirstReveal}`) — `isFirstReveal` is true only when no `avatarDefinitionJson` was persisted yet. `AvatarScreen`'s new `_AvatarReveal` widget fades+scales the avatar in (ease-out, 500ms) before chrome (equip button, valuation) appears; a returning user with a saved avatar skips straight to chrome. TDD'd: one test asserts chrome is absent immediately after load and present after `pumpAndSettle`; another confirms a returning user gets no ceremony at all.
**Known gap:** no explicit "skip" affordance if a user somehow re-triggers first-reveal (shouldn't happen in practice since `isFirstReveal` is one-shot per persisted definition, but worth a look once real users hit this path).

## 3. DESIGN.md — DONE (2026-09-23)
`/design-consultation` ran the same day; `DESIGN.md` and `CLAUDE.md`'s Design System section are written. Final tokens: Instrument Serif display / Instrument Sans body / JetBrains Mono numerals, warm charcoal ground `#161510`, brass accent `#C08A3E` (not Space Grotesk/Inter as first drafted — swapped because Space Grotesk is an overused display face). Tablet/landscape layout remains an open gap, not yet specified.

## 4. Bottom tab navigation (Profile / Avatar / Store / Share) — MOSTLY DONE (2026-09-23)
3 of 4 tabs wired in `app/lib/app.dart`'s `_RootTabs`: Identity, Avatar, Store. **Share tab still missing** — no Share screen exists yet, so the nav shell has 3 destinations, not 4. Add the 4th destination once a Share screen exists.

## 6. Store: browsable catalog with on-avatar preview + valuation — v1 DONE (2026-09-23)
`packages/store/` (catalog, entitlements, valuation) and `app/lib/store/` (StoreScreen, providers) built with TDD, wired into the nav shell as the Store tab. Catalog matches assets that actually exist today: 2 free items (Classic Frame glasses, Signature Tee) + 1 paid item (Riviera Optics glasses, $2.99) — original brand-inspired naming, no real trademarks, per the design review's legal call. Tapping any item previews it live on the avatar (`AvatarRenderer.updateSlot`) and persists it, regardless of ownership; priced+unowned items show a "Buy" button that grants a **local, stubbed entitlement** — no real money moves, this is a placeholder for StoreKit/Play Billing (a separate milestone per `docs/product/requirements.md`'s Monetization section). Avatar valuation (sum of equipped items' catalog price) now shows in the AvatarScreen app bar.

**Known gaps, deliberately deferred:**
- Valuation counts whatever's *equipped*, not what's *owned* — because the existing glasses-toggle button on AvatarScreen equips `glasses_realistic` unconditionally, bypassing the store's buy gate entirely (pre-existing behavior, not touched here). Once that debug toggle is replaced by the store being the only way to equip cosmetics, valuation should be re-scoped to owned-and-equipped only.
- No "cancel preview" — tapping an item both previews AND persists it immediately (matches the existing AvatarScreen toggle's behavior), so browsing the store changes your live avatar/identity as you go. A true try-before-you-commit preview needs a revert path in `AvatarRenderer`.
- Only 3 cosmetic items exist because only 3 `.glb` assets exist. More catalog items need new assets, not more code.

**Entitlement persistence — DONE (2026-09-23).** `FileEntitlementStore` (`packages/store/lib/src/file_entitlement_store.dart`) persists owned cosmetic ids as a JSON file under the app's support directory (`entitlements.json`, alongside the Isar identity DB) — deliberately *not* a new Isar collection or an `Identity` field, to avoid touching `identity_core`'s hand-maintained Isar codegen (see that package's pubspec comment) for an unrelated feature. Wired into `main.dart`'s `entitlementStoreProvider` override; TDD'd (4 tests, including a real restart-simulating "fresh instance, same file" round trip).

## 5. Disable "Save look" when nothing changed
**What:** Once a multi-slot cosmetic tray exists with an explicit save action, disable/grey that button until an equip action actually changes the definition from what's persisted.
**Why:** Prevents dead taps and silently communicates "nothing to save" without needing a toast.
**Pros:** Small, cheap affordance; matches platform conventions for save buttons.
**Cons:** None significant — needs a dirty-state flag on the avatar definition.
**Context:** Raised in Pass 7 (Unresolved Decisions) against the review mockup's "Save look" button. Still not applicable — both `AvatarScreen` and the new `StoreScreen` auto-persist on every equip/preview action (no separate save button exists anywhere yet).
**Depends on:** A screen with an explicit (not auto-persisting) save action — doesn't exist yet.

## 5. Disable "Save look" when nothing changed
**What:** Once a multi-slot cosmetic tray exists with an explicit save action, disable/grey that button until an equip action actually changes the definition from what's persisted.
**Why:** Prevents dead taps and silently communicates "nothing to save" without needing a toast.
**Pros:** Small, cheap affordance; matches platform conventions for save buttons.
**Cons:** None significant — needs a dirty-state flag on the avatar definition.
**Context:** Raised in Pass 7 (Unresolved Decisions) against the review mockup's "Save look" button. Not yet applicable to shipped code — `avatar_screen.dart` currently auto-persists on every toggle via `_persist()`, with no separate save action; this applies once the tray/multi-slot UI (item #4/mockup direction) is actually built.
**Depends on:** Multi-slot cosmetic tray UI (not yet built).

## 7. Store: rarity tiers + numbered series — v1 DONE (2026-09-26)
Inspired by the Steam "Egg" market (rarity ladder, Series #N drops). `CosmeticListing` now has `rarity` (`CosmeticRarity`: common..legendary) and optional `series` (`CosmeticSeries`); the 3 paid items are Series #1 "Founders" (Rare / Uncommon / Uncommon), free items stay Common. `avatarRarityScore` reports the highest equipped tier + per-tier counts; StoreScreen shows a rarity label per row and groups series under a header; AvatarScreen shows the highest equipped tier beside the valuation. Plan: `docs/superpowers/plans/2026-09-26-store-rarity-series.md`.

**Known gaps, deliberately deferred:**
- No rarity filter/sort in the store (7 items don't need it; add once the catalog grows).
- Epic/Legendary tiers exist but no item uses them yet; they need new assets.
- No resale/trading market (Egg's market is a Steam feature; Amiro's purchases are stubbed). A real secondary market needs its own payments, fraud and legal decision.
- Meme/cultural skins: original themes only. No real memes or trademarks (`docs/legal/asset-policy.md`).
- `docs/product/requirements.md` not updated with a rarity section.

## 8. Collections: series progress — v1 DONE (2026-09-26)
`collectionProgress(catalog, ownedIds)` (`packages/store/lib/src/collection_progress.dart`) returns per-series owned/total; StoreScreen series headers show "1 / 3" and "Complete" (brass) once every item is owned. Local-first: uses the existing series data and entitlements only.

**Known gaps, deliberately deferred:**
- No completion *reward*. A visual reward (aura, frame) needs new avatar assets; today completion is only a state.
- Progress is per-series inside the Store list; there's no standalone Collections screen yet.
- Next per the agreed sequence: Identity Card (QR first, then NFC), then Founding Identity. Real scarcity/editions and drops need server-authoritative issuance and are not started.
