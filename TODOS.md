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
PR1 `sharing` canonical payload (**done**, `AmiroSharingPayload`) → PR2 `discovery` EncounterRecord + repository (**done**) → PR3 encounter state machine (**done**) → PR4 QR bridge (**done**) → PR5 NFC boundary (**done**) → PR6 Identity Card (**done**) → PR7 encounter comparison (**done**) → PR8 Discovery Passport (**done**) → PR9 completion engine (**done**).

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

PR7-9 decisions (shipped together as one PR; taken autonomously while the owner was away, so worth a review):
- **Cutover.** The Share screen now emits `amiro://encounter` for both QR and NFC. Every receive path (QR scan, NFC receive, deep link) resolves through one `resolveScannedText` -> `ScanResult`, so encounter links open the comparison screen and **legacy `amiro://share` links from older builds still open the profile** (no passport entry, since they carry no collection). Android's manifest gained the `encounter` host (iOS already covers the whole scheme).
- **NFC.** `ManagerNfcReader` now uses the PR5 adapter (all records, strict UTF-8/UTF-16), fixing the first-record-only and Latin-1 bugs; `decodeNdefTextPayload` and its test were removed as superseded. `nfc` now depends on `sharing`. The native HCE tag (2 KB, UTF-8 text record) fits a 2000-char encounter link. **Not exercised on real hardware.** `ingestNfcReads` (dedupe/dropout) is not used by the app: the receive screen already handles one read per session and errors itself.
- **Encounter screen** is two-phase: showing a card writes nothing; "Save to passport" / "Update passport" commits via `EncounterProcessor.save`. Backing out changes nothing, including a known person's count. Your own card is `SelfEncounter`. The screen waits for the identity to load first so a cold-start deep link can't miss the own-card check.
- **Only their avatar is 3D** on the comparison screen; yours is a text summary. Two live Filament views side by side is unverified on a device.
- **Contact fallback.** If the contact card is what pushes the link past the QR size limit, `buildOwnEncounterUri` drops it and shares the identity alone rather than failing to share (the library's `encodeEncounterUri` still throws; only the app chooses to fall back).
- **Passport**: 5th tab; newest-met first; entry detail shows the latest known look; "Remove from passport" (confirmed) deletes the entry, after which that person counts as new. No 3D thumbnails in the list (too heavy per row). A corrupt ledger file shows "couldn't be opened" and saving fails visibly; it is never overwritten.
- **Completion engine** (`completedSeries`, `isSetComplete`, `SeriesCompletion.isComplete`): derived from catalog + entitlements, never stored, no remote validation. The v1 reward is a 2px brass **collector's frame** on the identity card and passport entries (DESIGN.md's equipped-card border), because no avatar asset exists to unlock. An avatar-level reward stays open until there is an asset.
- **Not built (deliberately):** Sparks / milestones on the unique-encounter count (`EncounterProcessor.uniqueEncounterCount` is the primitive), encounter history snapshots, real scarcity/editions, signed provenance, a rarity filter in the store, an exportable card image.
- **Not eyeballed on a device**: card and encounter screen layout, the 5-item navigation bar, and NFC end to end.

## 11. Design polish PR 1: tokens + shared components — DONE (2026-09-28)
Scope agreed with the owner after an external design critique (see DESIGN.md's 2026-09-28 decision): keep the brass/warm-charcoal/Instrument Serif system, do execution polish only, defer new product behavior.

- `AmiroCard` (`app/lib/theme/amiro_card.dart`): the one elevated-surface treatment (surface fill, radius 16, real offset shadow, neutral hairline border unless overridden). Replaces duplicated `BoxDecoration` in `IdentityCard` and the passport entry card.
- `SectionLabel` / `sectionLabelStyle`: the muted, wide-tracked uppercase caption pattern (AMIRO, DISCOVERED, ...), deduplicated.
- `EmptyState`: title + hint + optional action button. Replaces Passport's ad hoc `_Empty` and the Share screen's bare "Create your identity first" label, which now explains itself and offers a "Create identity" button that opens `IdentityEditScreen`.
- `AmiroSpacing` / `AmiroRadius`: DESIGN.md's 4px/radius scales as named constants.
- Disabled `FilledButton` now actually matches DESIGN.md's spec (40% opacity brass, no shadow) — it never had before; Material's default grey-out was still in effect.
- Bottom nav: outline/filled icon pairs per tab (selected state readable without relying on color, since brass is reserved for equipped/price/primary-action only) and consistent selected/unselected label weight.

**Deliberately not touched this pass (Phase 2/3, separate PRs):**
- Identity screen hierarchy/profile-preview, avatar full-screen/rotate-lighting-preset polish, Store card visual redesign — each is its own screen/workstream per the agreed incremental approach.
- New product behavior: outfit presets, background/lighting picker, before/after preview, unlock/reveal animations, live username availability, dirty-state save gating.

## 12. Design polish PR 2: Store card redesign — DONE (2026-09-29)
Implements DESIGN.md's already-written but never-built "Cosmetic item card" spec: default = surface + hairline border; equipped = 2px brass border + `EQUIPPED` badge (on-primary text on primary fill); purchased-but-unequipped = default, no badge. Rows are now `AmiroCard` instead of `ListTile`. Preview-before-buy is unchanged (the whole card is tappable, including unowned items — see #6).
Not built: locked/premium 55% overlay + lock icon (no "locked" concept distinct from "not owned" exists in the data model — would be a new state, deferred) and SOLD OUT (no supply concept exists — deferred with real scarcity/editions, TODOS #10).

## 13. Design polish PR 3: Avatar screen token consistency — DONE (2026-09-29)
Avatar screen's app-bar chrome and equip-button padding now use `AmiroSpacing.md`/`.sm` instead of hardcoded 16/8. No layout, capability or behavior change — the avatar stage was already full-bleed, three-point-lit and rotatable from earlier commits (`a2f0612`, `6bbcbad`); DESIGN.md's floor shadow and framing are renderer-level (Filament), not something this pass touches.
Not built (explicitly excluded per the 2026-09-28 decision): full-screen/hero treatment beyond what already exists, background/lighting picker, before/after preview, outfit presets, idle animation, equip transition — all new product behavior, deferred.

This closes the agreed Phase 1/2 polish scope (tokens, Store cards, Avatar consistency, Share/Passport empty states from PR 1). Remaining items from the critique — Identity screen hierarchy, and every explicitly-deferred new capability — stay open as separate future work, not folded into this sequence.

## 14. Design polish PR 4: Identity screen hierarchy — DONE (2026-09-29)
Fields grouped under two `AmiroCard`s with `SectionLabel` headers: PROFILE (display name, username, bio) and CONTACT (email, privacy toggle). Pure regrouping/spacing — no new interaction added.
Explicitly not built (new capability, stays deferred): username availability check, live character count, dirty-state save gating, inline validation, success animation, an avatar thumbnail/profile preview (would need this screen to depend on the avatar renderer, which it doesn't today — a bigger change than hierarchy).
This was the last item from the original critique's "include" list; everything remaining is new product behavior and needs its own scoping conversation before starting.

## 15. Real payments: RevenueCat + Play Billing — MOSTLY DONE (2026-09-29)
The Store's mock "demo purchase" dialog is gone; `packages/store/lib/src/revenuecat_entitlement_store.dart` now calls real Play Billing through `purchases_flutter`/RevenueCat. Catalog on the RevenueCat side (project `Amiro`, `proj9768d0fc`) is fully set up via `rc` CLI: Android app registered (`app51bedf1b9c`, package `com.developerscoffee.amiro_app`), 3 one-time products (`amiro_riviera_optics`, `amiro_long_flow`, `amiro_full_beard`) each attached to their own entitlement (`cosmetic_<id>`). A webhook (`whintgrb5c7c2a4a3`) posts purchase events to a Cloudflare Worker (`workers/revenuecat-webhook/`, deployed at `amiro-revenuecat-webhook.developerscoffee.workers.dev`, free tier), which logs every event and upserts entitlement grants into a Supabase Postgres project (`amiro`, `srvhqmfjqmxxvrdctbtf`, free tier) — see `supabase/migrations/20260929060138_create_entitlements.sql`. Verified end-to-end with a synthetic webhook POST (row landed in `entitlement_grants`, then cleaned up).

**The app itself never reads Supabase** — it trusts the RevenueCat SDK's own on-device `CustomerInfo` cache (already receipt-validated against Play). Supabase is purely the server-side audit/support record, written only by the Worker via its service-role key (Worker secret, never in git).

**Not done — blocks real purchases from actually working:**
- **Play Console side**: the 3 products above don't exist yet as real Play Console one-time products with matching IDs. `scripts/play-publish/create_products.mjs` is written and ready (upserts all 3 via `monetization.onetimeproducts.patch`) but still 403s as of the last retry — see "Service account" below.

**RevenueCat ↔ Play server-side link — DONE (2026-09-29).** `amiro-play-publisher`'s key was uploaded to RevenueCat's dashboard (Amiro Android app → App Settings → Service credentials) by the account owner; confirmed via `rc audit` (`app_updated`, `credentials_provided: true`). Needed granting the same service account **View financial data** (Purchases API) in Play Console, and enabling the **Cloud Pub/Sub API** on the `developerscoffee` GCP project (RevenueCat requires it for real-time developer notifications) — both done. RevenueCat's own docs warn new Play credentials can take up to ~36h to start validating receipts; if purchases still fail with a credentials error after that window, re-check the service account's Play Console grants.

**Service account & release automation — DONE (2026-09-29).** `amiro-play-publisher@developerscoffee.iam.gserviceaccount.com` (GCP project `developerscoffee`, key at `.secrets/gcp-play-publisher-key.json`, gitignored) is invited in Play Console with **Release apps to testing tracks**, **Manage testing tracks and edit tester lists**, **Manage store presence**, and **View financial data** on the Amiro app only — deliberately not "Release to production" (a separate, higher-stakes grant for when the app is actually ready to ship). This exists because Play Console's browser upload widget needs a native OS file picker no browser-automation tool available here can drive, and the release AAB (107MB) is well over the 10MB cap on the one upload tool that can bypass the picker (Chrome extension's `file_upload`). `scripts/play-publish/upload.mjs` uploads and publishes to internal testing directly via the Android Publisher API instead — used successfully to ship version code 4 (1.0.0). `scripts/play-publish/create_products.mjs` (same auth) is ready for the 3 IAP products but keeps 403ing on writes even though reads with the same key succeed and the release-upload permission works fine — likely the same Google-side propagation lag RevenueCat's own docs warn about for fresh Play API grants (up to ~36h), not a config bug. Retry later; no code change expected to be needed.
- **iOS**: no App Store Connect credentials in RevenueCat at all — `RevenueCatEntitlementStore` deliberately no-ops on iOS (`Platform.isAndroid` guard) rather than crash. iOS purchases stay unavailable until that's set up.
- **Legal docs updated, Play Console form not re-submitted**: `docs/legal/privacy-policy.{html,md}`, `docs/legal/data-safety.md`, and `docs/legal/store-listing.md` now describe the real purchase pipeline. The Data safety declaration already submitted to Play Console (2026-09-29, pre-payments) needs re-submitting to match.
- The Worker has no request-signature verification from RevenueCat (their dashboard doesn't expose an Authorization-header webhook secret through the `rc` CLI) — secured instead by an unguessable random path segment (`WEBHOOK_PATH_TOKEN`, a Worker secret). Fine for MVP; revisit if RevenueCat later exposes signed webhooks via API.
- No RevenueCat Offering/Paywall configured (not needed for this store's UI — it calls `Purchases.getProducts`/`purchase` directly per catalog item, not RC's paywall UI).
