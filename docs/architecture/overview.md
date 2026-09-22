This is the living architecture doc; the original design rationale is preserved at `../superpowers/specs/2026-09-22-amiro-foundation-design.md`.

# Amiro Foundation Design (M0 + M1 + thin avatar-render slice)

**Status:** approved for implementation
**Date:** 2026-09-22
**Owner:** Product owner (Uday) + agent team

## 1. Purpose

Lay the foundation for Amiro — a wearable digital identity app (Flutter,
local-first, NFC/QR sharing, 3D avatar, virtual cosmetics store). This pass
does **not** build the full product. It builds:

1. The monorepo skeleton (packages, Rust core, CI, docs) that every later
   agent/milestone builds on without restructuring.
2. M1: local identity create/edit with per-field privacy toggles, persisted
   on-device.
3. A thin end-to-end avatar slice: one renderable 3D avatar (base body + 2
   swappable cosmetic slots) proving the full pipeline — definition JSON →
   render → swap → persist — without building the real store, catalog,
   purchases, NFC, QR, or backend yet.

Everything NFC/QR/store/backend/purchases-related is stubbed as an empty
package with a `README.md` describing its future contract, so package
boundaries exist now and later agents fill them in without moving files.

## 2. Explicit non-goals for this pass

Per the PRD's "out of scope for v1" list, and further narrowed for this
pass specifically:

- No NFC, no QR generation/scanning (packages exist as empty stubs only).
- No backend, no network calls, no auth, no accounts.
- No purchases/StoreKit/Play Billing.
- No real cosmetic catalog or store UI — only 2 placeholder cosmetic
  assets to exercise the render/swap pipeline.
- No trading/marketplace/NFT/crypto (permanently out of scope, not just
  this pass).
- No production-quality avatar art — placeholder/blockout meshes only.
  Real asset production is Agent 6's job, tracked separately.

## 3. Repository layout

```
amiro/
├── app/                          # Flutter application (thin — composes packages)
├── packages/
│   ├── identity_core/            # Identity model, privacy flags, storage contracts (Dart)
│   ├── avatar_core/               # AvatarDefinition model (Dart) — pure data, no rendering
│   ├── avatar_renderer/           # Renderer interface + ThermionAvatarRenderer impl
│   ├── sharing/                   # STUB — future: orchestrates nfc/qr/deep-link flows
│   ├── nfc/                       # STUB — future: NFC read/write
│   ├── qr/                        # STUB — future: QR generate/scan
│   └── store/                     # STUB — future: catalog, entitlements, purchase flows
├── rust/
│   └── core/                      # Rust: identity struct, serde, storage-abstraction trait
├── assets/
│   ├── avatars/                   # 1 placeholder base body glTF/GLB
│   └── cosmetics/                 # 2 placeholder cosmetic glTF/GLB (e.g. top, glasses)
├── docs/
│   ├── product/requirements.md    # Seeded from the PRD (both drafts) provided
│   ├── architecture/overview.md   # This design, promoted to living doc
│   ├── protocols/identity-link.md # Stub — not started
│   ├── protocols/avatar-format.md # AvatarDefinition JSON schema (real, from this pass)
│   ├── legal/asset-policy.md      # Stub rules: original assets only, no Bitmoji-alikes
│   ├── legal/third-party-licenses.md # Stub, tracks thermion_flutter/Isar/etc licenses
│   └── qa/test-plan.md            # Stub — not started
├── .github/workflows/ci.yml
├── melos.yaml
├── LICENSE (MIT)
└── README.md
```

Stub packages contain a `pubspec.yaml`, empty `lib/`, and a `README.md`
stating: purpose, planned public interface (from the PRD sections), and
"not implemented — placeholder for package boundary." This lets later
milestones fill them in-place with zero restructuring.

## 4. Package boundaries and contracts

- **identity_core**: `Identity` model (displayName, username, avatarRef,
  bio, mobile, email, xHandle, instagramHandle, website, otherLinks —
  each wrapped with a `PrivacyFlag { public, private }`), a
  `IdentityRepository` abstract interface, one impl backed by Isar.
  Pure Dart, no Flutter widget dependencies — testable standalone.
- **avatar_core**: `AvatarDefinition { body, hair, top, bottom, shoes,
  glasses, earrings, necklace, goldChain, watch, hat, background,
  effects }` — all slots nullable strings (asset ids), matches PRD's
  conceptual JSON format exactly so no later migration is needed when
  slots gain real content. This pass only populates `body`, `top`,
  `glasses`.
- **avatar_renderer**: `abstract class AvatarRenderer { Future<void>
  load(AvatarDefinition def); Widget buildView(); Future<void>
  updateSlot(String slot, String? assetId); void dispose(); }`. One
  concrete impl: `ThermionAvatarRenderer`. This is the swap boundary —
  nothing outside this package imports `thermion_flutter` directly.
- **rust/core**: `Identity` struct mirrored via serde + bridged through
  `flutter_rust_bridge`; a `StorageBackend` trait (not implemented in
  Rust — Dart/Isar is the actual storage; Rust stays storage-agnostic and
  only owns the domain struct + (de)serialization + validation).

## 5. Technology choices

| Concern | Choice | Why |
|---|---|---|
| App framework | Flutter | Per PRD; single Android+iOS codebase |
| State management | Riverpod | Matches common Airo-family pattern, testable, no BuildContext coupling |
| Local storage | Isar | Fast local-first NoSQL, handles evolving avatar/identity JSON shape well without migrations |
| Monorepo tooling | Melos | Same tool the `airo` monorepo convention would use; manages multi-package pub workspace |
| Rust↔Dart bridge | flutter_rust_bridge | Standard bridge; codegen from Rust structs |
| 3D renderer | `thermion_flutter` (pub.dev, v0.5.0) wrapping Filament | Verified to exist and be actively published (checked pub.dev API directly, 2026-09-22). Code-only workflow (glTF + Dart/C++), same engine both platforms, no Unity licensing/runtime-fee exposure, no GUI-editor step that fights agent-driven development. See §7 risk note. |
| Asset format | glTF/GLB | Per PRD, matches Filament's native format |
| License | MIT | Matches `airo`/`airo_core` convention |

## 6. Data flow (this pass)

```
User input (Flutter form)
   → identity_core.Identity (validated)
   → Isar (local persist)

AvatarDefinition (Dart, avatar_core)
   → avatar_renderer.AvatarRenderer.load()
   → ThermionAvatarRenderer → Filament engine → rendered view in app
   → user taps cosmetic → updateSlot() → re-render
   → AvatarDefinition persisted alongside Identity (as part of the same Isar record)
```

No network calls anywhere in this pass. No data leaves the device.

## 7. Risks / things flagged while laying the foundation

- **thermion_flutter is young (v0.5.0)**: real risk of API instability,
  platform gaps (web support listed but Android/iOS are the targets we
  care about), or missing features once real cosmetic layering
  (multi-mesh compositing per PRD's 17-slot avatar) is attempted. The
  `AvatarRenderer` interface exists specifically to contain this risk —
  if thermion proves inadequate later, only `avatar_renderer/` changes.
  Recommend a short spike (render base body + 1 swap on both a
  physical/simulated Android and iOS target) before treating this as
  load-bearing for M2+.
- **Placeholder art is not final art and is not necessarily "original"
  in the legal sense** — using engine sample primitives/blockout shapes
  for this pass only. Agent 6/Legal must replace before any public
  release; `docs/legal/asset-policy.md` stub captures this so it isn't
  forgotten.
- **No accounts/auth in this pass** means identity is device-local only
  — acceptable per PRD's "create temporary local identity" flow, but
  means this pass alone cannot demonstrate the NFC share → second device
  loop from the PRD's Definition of Done. That remains for a later
  milestone (M4, sharing).
- **GitHub repo creation + first push**: creating `DevelopersCoffee/amiro`
  as a public repo and pushing is a publish action — will ask for
  explicit confirmation at that step rather than assuming it from the
  earlier "public" design answer.

## 8. Testing plan (this pass)

- `identity_core`: unit tests for `Identity` validation, privacy-flag
  serialization round-trip, `IdentityRepository` (Isar) CRUD.
- `avatar_core`: unit tests for `AvatarDefinition` JSON round-trip.
- `avatar_renderer`: smoke test that `ThermionAvatarRenderer` loads a
  definition and swaps a slot without throwing (widget/integration
  test, not pixel-comparison).
- `app`: widget test for identity create/edit screen (field entry,
  privacy toggle, save) and for avatar screen (renders, cosmetic tap
  swaps slot).
- `rust/core`: `cargo test` for struct validation + serde round-trip.
- CI (`ci.yml`): `melos exec -- flutter analyze`, `melos exec -- flutter
  test`, `cargo test`, `cargo clippy -- -D warnings`.

## 9. Milestones this pass maps to

Maps to PRD M0 (architecture) fully, M1 (identity) fully, and a thin
vertical slice of M2 (avatar) — base body + 2 cosmetic slots only, no
full 17-slot system, no animation, no camera controls beyond a static/
orbit default. Full M2 (all slots, animation, camera) and everything
from M3 onward (real store, NFC, QR, backend) are explicitly deferred to
future passes and tracked via the stub package READMEs.
