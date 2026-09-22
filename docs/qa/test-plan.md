# QA Test Plan

**Status: this pass covers unit/widget tests only (see below). Full
device-matrix QA (Android phone, iPhone, Android+NFC, iPhone+NFC) is
out of scope until NFC/QR ship in M4.**

## Coverage shipped in this pass

- `rust/core`: `cargo test` — Identity struct validation + serde round-trip.
- `packages/identity_core`: unit tests for `Identity` model, JSON
  round-trip, `publicFields()` privacy filtering, `IsarIdentityRepository`
  CRUD.
- `packages/avatar_core`: unit tests for `AvatarDefinition`, slot
  update, JSON round-trip.
- `packages/avatar_renderer`: unit tests for asset path resolution and
  `ThermionAvatarRenderer` slot-swap bookkeeping (engine calls faked).
- `app`: widget tests for identity create/edit (field entry, privacy
  toggle, save) and avatar screen (initial load, cosmetic swap on/off).

## Explicitly not covered yet

NFC, QR, deep links, purchases, offline/online sync divergence, profile
privacy on the (not-yet-built) web fallback, app-not-installed
experience, cross-device pairing. Each becomes a QA Agent task when its
owning milestone ships.
