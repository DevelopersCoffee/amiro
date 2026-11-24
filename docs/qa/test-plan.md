# QA Test Plan

**Status:** automated unit/widget tests cover identity, avatar, store,
sharing, discovery, and theme components on CI (`melos run test`). Full
device-matrix QA (two-phone NFC tap, iOS parity, real Play purchase flows)
remains manual and is not fully exercised.

## Coverage in CI today

- `rust/core`: `cargo test` — Identity struct validation + serde round-trip.
- `packages/identity_core`: `Identity` model, JSON round-trip,
  `publicFields()` privacy filtering, `IsarIdentityRepository` CRUD.
- `packages/avatar_core`: `AvatarDefinition`, slots, JSON round-trip.
- `packages/avatar_renderer`: asset path resolution and slot-swap bookkeeping
  (engine faked).
- `packages/store`: catalog, entitlements (including RevenueCat channel mocks),
  valuation, rarity/collection helpers.
- `packages/sharing`, `packages/nfc`, `packages/qr`: payload/URI/NDEF and
  emulator channel contracts.
- `packages/discovery`: encounter records, file repository, processor.
- `app`: widget tests under `app/test/` for identity, avatar, store, sharing
  (QR scan, NFC receive, scan routing, identity card), discovery/passport,
  theme components, and related providers. Cloud backup consent, revoke, and
  claim failures are covered with HTTP fakes
  (`app/test/identity/supabase_profile_cloud_*`, `cloud_backup_*`), not only
  against a live project. Analytics and crash ingest have worker tests under
  `workers/revenuecat-webhook/test/` and app tests where present.

## Explicitly not covered (or only partially covered) in CI

- Two-device NFC tap-to-tap and real QR scan against a physical code (see
  `docs/architecture/overview.md` §11).
- Live Play Billing / RevenueCat purchase sheets and receipt edge cases (manual
  script: `docs/qa/restore-purchases-device.md`; automated restore outcomes in
  `packages/store` and `app/test/store/`).
- iOS store, NFC emulate, and full renderer parity on Apple hardware.
- Profile cloud backup against a **live** Supabase project (HTTP fakes cover
  the client; #43/#47/#48). Device restore of purchases:
  `docs/qa/restore-purchases-device.md`.
- A published `https://id.amiro.app/u/<token>` page when the app is not
  installed (`workers/web-profile/`, `docs/protocols/web-profile.md`). The
  Worker can serve that URL; store builds still ship with publish disabled.

Each gap becomes a focused QA pass when its hardware or credentials are
available; device spikes are recorded in the architecture doc rather than
here.
