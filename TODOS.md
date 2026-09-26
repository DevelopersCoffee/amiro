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

## 9. Identity card: collection on the shared profile — v1 DONE (2026-09-26)
The share URI (QR and NFC) now carries the sender's collected cosmetic ids (`owned`, sorted, capped at `maxSharedCosmeticIds` = 32; free items plus purchases via `collectedCosmeticIds`). `SharedProfileScreen` shows a Collection section: rarest item with its rarity label, and per-series progress (`SeriesProgressRow`, shared with the store list). Older payloads without the field, malformed fields, and ids this app version doesn't know all degrade to "no collection section" instead of rejecting the profile. Still payload v1: the field is additive.

**Known gaps, deliberately deferred:**
- The collection is self-reported and unverified. It is a show-off surface, not proof of ownership; real provenance needs server-authoritative issuance.
- No privacy toggle for the collection (only contact fields have flags). Decide before real users scan strangers.
- No "Create your Amiro" call to action on the received card, no encounter history, no discovery rewards (Sparks: one unique person counts once). Next items in the agreed sequence, then Founding Identity.
- No exportable card image (wallpaper/story); QR/NFC only.

## 10. vNext lib-first sequence — PR 1 DONE (2026-09-26)
Agreed order (library before UI, protocol tests as the gate before any transport):
PR1 `sharing` canonical payload (**done**, `AmiroSharingPayload`) → PR2 `discovery` EncounterRecord + repository (**done**) → PR3 encounter state machine (**done**) → PR4 QR bridge (**done**) → PR5 NFC boundary (**done**) → PR6 Identity Card (**done**) → PR7 encounter comparison → PR8 Discovery Passport → PR9 completion engine.

PR1 decisions worth remembering:
- `AmiroSharingPayload` is JSON with a required integer `schemaVersion` (1); unknown extra fields are ignored, unsupported versions are rejected as `PayloadErrorKind.unsupportedVersion`, and `discovery` must only ever receive a payload that passed `validate()`. Cap 4096 bytes, 32 entries per list.
- The spec's `CollectionProgress` is named `SeriesCompletion` in `sharing`: `store` already exports a `CollectionProgress`, and the app imports both.
- `EquippedCosmeticInfo.seriesId` is nullable (free items sit outside any series).
- Cosmetic name/rarity on the wire are sender-claimed. A receiver that knows the id should prefer its own catalog and treat the wire values as a fallback; this is not proof of ownership.
- **Two formats coexist until PR4:** the existing `amiro://share?d=` URI (`SharedProfile`, has username and contact fields) still drives the app; `AmiroSharingPayload` is not wired in yet. The QR bridge must decide how contact fields and `username` map across (they are absent from the new payload).

PR2 decisions (`packages/discovery`, library only, not wired into the app):
- `EncounterRecord` is immutable (spec had mutable fields); an encounter yields a new record via `copyWith`. `localRecordId` (ULID-style, `newLocalRecordId`) is independent of `remoteIdentityId`.
- `DiscoveryRepository` is storage only (`getAll`, `findByRemoteIdentityId`, `save`, `delete`). The spec's `registerEncounter` belongs to the PR3 state machine, not the store.
- The repository enforces one record per `remoteIdentityId` (`save` throws `ArgumentError` otherwise), so unique encounters = `getAll().length` cannot double-count a person.
- `FileDiscoveryRepository`: atomic temp-file-and-rename writes, serialised writes, and a corrupt file throws `FormatException` and is never overwritten (losing the passport silently is worse than failing loudly). The app must decide how to surface that when it wires this in.

PR3 decisions (`EncounterProcessor` in `packages/discovery`, library only):
- Two-phase, matching the spec's explicit "save to passport" gate: `receive`/`receivePayload` validate and classify (`NewEncounter`, `KnownEncounter`, `SelfEncounter`, `EncounterRejected`) and write nothing; `save(PendingEncounter)` commits. A dismissed encounter changes nothing, including the repeat count.
- `save` is idempotent (a double tap counts once), serialised, and recomputes from the ledger if it changed since the preview (two previews of the same new person saved in order make one record met twice). A record deleted between preview and save becomes a first contact again.
- `ownIdentityId`: scanning your own card returns `SelfEncounter`, so it can't inflate the unique count that Sparks will later be derived from.
- `lastEncountered` never moves backwards if the device clock does.
- Only validated payloads reach the ledger: `receive` decodes and `receivePayload` re-validates.

PR4 decisions (`sharing`: `encodeEncounterUri` / `decodeEncounterUri`, `ContactCard`, library only):
- Decision (2026-09-26): keep the discovery payload minimal and carry contact details on a separate `c` parameter of the same link, `amiro://encounter?d=<payload>[&c=<contact card>]`. Adding optional contact fields to the payload later stays open (additive under schema v1); nothing here prevents it.
- `ContactCard` follows `Identity.publicFields()` strictly (`username` only if flagged public, unlike the legacy `amiro://share` codec which always sends it); fields capped at 256 characters.
- Links over 2000 characters are refused on encode and decode. Encode throws rather than silently dropping the contact card. A malformed contact card on receive is dropped without rejecting the identity.
- The legacy `amiro://share` link is untouched; the scanner should try encounter first, then legacy, until the app is migrated.

PR5 decisions (`sharing`: `NdefRecordData`, `decodeEncounterFromNdef`, `ingestNfcReads`, library only):
- The boundary is plugin-independent bytes in, validated `EncounterQr` out. The `nfc` package should convert its platform records to `NdefRecordData` when wired.
- **Existing `nfc` reader bugs the adapter fixes (not yet migrated):** `ManagerNfcReader` reads only the first record (an Android Application Record first would hide the card) and decodes text with `String.fromCharCodes` (Latin-1, and it ignores the UTF-16 flag). The adapter scans all records, decodes strict UTF-8/UTF-16, and skips URI records with abbreviation prefixes.
- `ingestNfcReads`: reads become `NfcEncounterRead` or `NfcReadRejected`; a hardware dropout (stream error) becomes a rejection instead of an exception and the stream survives; identical reads within a 3 s window are reported once (continuous contact refreshes the window).
- Remaining before NFC works end to end: wire `ManagerNfcReader` into this adapter and have the emulator write the encounter link (`encodeNdefTextPayload`), both in the app-wiring PRs.

PR6 decisions (Identity Card, `app/lib/sharing/`):
- `IdentityCard` is purely presentational (no providers, no discovery): it draws an `AmiroSharingPayload` plus an avatar widget and a QR string, so what the card shows is exactly what the payload carries. `buildOwnEncounterPayload` composes that payload from identity, the live avatar and purchases; `progressFromCompletion` resolves series for display and skips series this app version doesn't know.
- Card content follows DESIGN.md: serif name, up to 3 standout (above-Common) items with rarity labels (brass from Rare up), series progress in mono, real offset shadow, no glow. Common items are deliberately not listed.
- **The QR/NFC link is still the legacy `amiro://share` link.** The card describes the identity with the encounter payload, but switching the emitted link to `amiro://encounter` waits for PR7, when the scanner, NFC receive and deep links learn to read it (otherwise a new build's QR would be unreadable by the current scanner). PR7 must also migrate the NFC emulator/reader onto `encodeNdefTextPayload` / `decodeEncounterFromNdef`.
- `CosmeticSeries.id` (`series_1`) and `CosmeticRarity.wireName` / `fromWireName` are the wire spellings; an unknown rarity is ignored, never guessed.
- Not eyeballed on a device yet.
