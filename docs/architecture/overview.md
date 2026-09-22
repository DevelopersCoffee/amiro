This is the living architecture doc: it describes the code **as it actually
stands** after the foundation pass. The original pre-implementation design
rationale is preserved unchanged at
`../superpowers/specs/2026-09-22-amiro-foundation-design.md`; where the two
disagree, this document is correct and the spec is history.

# Amiro Architecture (M0 + M1 + thin avatar-render slice)

**Status:** foundation pass implemented
**Date:** 2026-09-22
**Owner:** Product owner (Uday) + agent team

## 1. Purpose

Amiro is a wearable digital identity app (Flutter, local-first, NFC/QR
sharing, 3D avatar, virtual cosmetics store). The foundation pass does
**not** build the full product. It built:

1. The monorepo skeleton (packages, Rust core, CI, docs) that every later
   milestone builds on without restructuring.
2. M1: local identity create/edit with per-field privacy toggles, persisted
   on-device via Isar.
3. A thin end-to-end avatar slice: one renderable 3D avatar (base body + 2
   swappable cosmetic slots) exercising the pipeline — definition JSON →
   render → swap → persist.

Everything NFC/QR/store/backend/purchases-related is a stub package with a
`README.md` describing its future contract, so package boundaries exist now
and later milestones fill them in without moving files.

## 2. Explicit non-goals for this pass

- No NFC, no QR generation/scanning (packages exist as empty stubs only).
- No backend, no network calls, no auth, no accounts.
- No purchases/StoreKit/Play Billing.
- No real cosmetic catalog or store UI — only 2 placeholder cosmetic assets
  to exercise the render/swap pipeline.
- No trading/marketplace/NFT/crypto (permanently out of scope).
- No production-quality avatar art — placeholder/blockout meshes only.

## 3. Repository layout (actual)

```
amiro/
├── app/                           # Flutter application (thin — composes packages)
│   ├── android/  ios/             # Platform scaffolds (generated, never device-run)
│   ├── lib/{main,app}.dart
│   ├── lib/identity/              # identity_providers.dart, identity_edit_screen.dart
│   ├── lib/avatar/                # avatar_providers.dart, avatar_screen.dart
│   └── test/
├── packages/
│   ├── identity_core/             # Identity model, privacy flags, Isar repository (pure Dart)
│   ├── avatar_core/               # AvatarDefinition model (pure Dart) — data only, no rendering
│   ├── avatar_renderer/           # Renderer interface + ThermionAvatarRenderer impl
│   │   └── assets/{avatars,cosmetics}/   # placeholder .glb files live HERE, not at repo root
│   ├── sharing/  nfc/  qr/  store/       # STUBS — pubspec + README + empty lib only
├── rust/core/                     # Rust: Identity struct, validation, serde
├── docs/
│   ├── product/requirements.md
│   ├── architecture/overview.md   # this file
│   ├── protocols/identity-link.md # stub — not started
│   ├── protocols/avatar-format.md # AvatarDefinition JSON schema (real)
│   ├── legal/asset-policy.md
│   ├── legal/third-party-licenses.md
│   └── qa/test-plan.md            # stub — not started
├── .github/workflows/ci.yml
├── pubspec.yaml                   # workspace root: pub `workspace:` list + `melos:` config
├── LICENSE (MIT)
└── README.md
```

Two things that differ from the original spec's sketch:

- **There is no repository-root `assets/` directory.** The placeholder glTF
  assets are packaged inside `avatar_renderer` and resolve as
  `packages/avatar_renderer/assets/{avatars,cosmetics}/<id>.glb`, so the
  renderer package is self-contained and callers never reference a path
  outside it.
- **There is no `melos.yaml`.** Melos 7 removed the `packages:` key in
  favour of Dart's pub workspaces; the Melos config now lives under the
  `melos:` key in the root `pubspec.yaml`, next to the `workspace:` member
  list. Every package carries `resolution: workspace`.

## 4. Package boundaries and contracts (actual)

- **identity_core** (pure Dart): `Identity { id, displayName, username, bio,
  mobile, email, xHandle, instagramHandle, website, avatarDefinitionJson,
  privacy: Map<String, PrivacyFlag> }`, plus `copyWith`, `publicFields()`,
  and a JSON round-trip. Privacy is a per-field `PrivacyFlag(bool isPublic)`
  map, not a wrapper around each field; a field with no flag defaults to
  private. `IdentityRepository { getCurrent, save, clear }` with one
  Isar-backed impl, `IsarIdentityRepository`, over a single-row
  `IdentityRecord` collection (one identity per device — no multi-profile).

  Note the field names: `avatarDefinitionJson` (not `avatarRef`), and there
  is no `otherLinks` field.

- **avatar_core** (pure Dart): `AvatarDefinition` with an **18-slot** schema —
  `body, face, skin, hair, eyes, eyebrows, facialHair, top, bottom, shoes,
  glasses, earrings, necklace, goldChain, watch, hat, background, effects` —
  all nullable asset-id strings, plus `copyWithSlot(slot, assetId)` (throws
  `ArgumentError` on an unknown slot) and a JSON round-trip. Only `body`,
  `top`, `glasses` are populated in this pass. (Parts of the older
  documentation called this "17 slots"; the schema has always had 18.)

- **avatar_renderer**: the engine swap boundary.
  ```dart
  abstract class AvatarRenderer {
    AvatarDefinition? get current;
    Future<void> load(AvatarDefinition definition);
    Widget buildView();
    Future<void> updateSlot(String slot, String? assetId);
    Future<void> dispose();          // Future<void>, not void
  }
  ```
  One impl, `ThermionAvatarRenderer`, plus `ThermionAvatarRenderer.create()`
  — a static async factory that builds the live Filament viewer. **Nothing
  outside this package imports `thermion_flutter`**, including `app`: that
  factory exists precisely so engine construction never leaks into
  `main.dart`. A `FilamentSurface` seam sits under the renderer so slot
  bookkeeping is unit-testable without a live platform view.

- **rust/core**: `Identity` struct + validation + serde round-trip, exercised
  only by `cargo test`.

## 5. Technology choices

| Concern | Choice | Why |
|---|---|---|
| App framework | Flutter | Per PRD; single Android+iOS codebase |
| State management | Riverpod | Testable, no BuildContext coupling |
| Local storage | Isar `^3.1.0+1` | Fast local-first NoSQL; JSON-in-field keeps evolving shapes migration-free |
| Monorepo tooling | Melos `^8.9.0` on pub workspaces | Manages the multi-package workspace |
| Rust↔Dart bridge | flutter_rust_bridge | **Not wired — see §7** |
| 3D renderer | `thermion_flutter` 0.5.0 wrapping Filament | Code-only workflow (glTF + Dart/C++), same engine both platforms, no Unity licensing exposure, no GUI-editor step |
| Asset format | glTF/GLB | Matches Filament's native format |
| License | MIT | Matches `airo`/`airo_core` convention |

### Build constraints worth knowing

Resolving all packages together under a pub workspace forces two
accommodations, both documented inline where they live:

- `cli_util` is pinned by a workspace-root `dependency_overrides` entry.
  Melos needs `>=0.5.0`; `thermion_flutter → thermion_dart → ffigen_js`
  pins `^0.4.2`. `ffigen_js` only generates thermion's *web* FFI bindings,
  which Amiro never invokes.
- `isar_generator`/`build_runner` are **not** dependencies of
  `identity_core`. `isar_generator 3.1.0+1` requires `analyzer <6.0.0`,
  which cannot coexist with the `matcher` the current Flutter SDK pins into
  `flutter_test`. Consequently `identity_isar_schema.g.dart` is committed to
  the repo (with a `.gitignore` exception) and nothing in CI regenerates it.
  `packages/identity_core/pubspec.yaml` documents the manual out-of-workspace
  regeneration recipe.

## 6. Data flow (actual)

```
User input (Flutter form)
   → identity_core.Identity
   → IsarIdentityRepository.save() → single-row IdentityRecord

AvatarDefinition (avatar_core)
   → AvatarRenderer.load()
   → ThermionAvatarRenderer → Filament engine → rendered view in app
   → user taps cosmetic → updateSlot() → re-render
   → jsonEncode(definition) → Identity.avatarDefinitionJson → same Isar row
```

**The persist step is closed.** `AvatarScreen` writes the current definition
onto the current `Identity` after the initial load and after every slot swap,
and on mount it restores the persisted definition in preference to the
hardcoded placeholder default. `identity_core` stores it as opaque JSON and
deliberately does not depend on `avatar_core`. If no identity has been
created yet there is nothing to attach the avatar to, and the persist is a
no-op.

The renderer is an app-lifetime singleton provided via Riverpod, so
`AvatarScreen` loads at most once across the app's lifetime even though its
`State` is recreated on every tab switch.

No network calls anywhere in this pass. No data leaves the device.

## 7. Deliberate deferrals (not done, on purpose)

- **The Rust↔Dart bridge is not wired.** `rust/core` owns the `Identity`
  struct, validation and serde, and is verified by `cargo test` +
  `cargo clippy -D warnings` in CI — but no `flutter_rust_bridge` codegen
  runs and no Dart code calls into it. Dart's `identity_core` is the
  implementation the app actually uses; the Rust struct is currently a
  parallel definition, kept honest by its own tests. Wiring the bridge adds
  a codegen build step disproportionate to what M1 needed. **Anyone changing
  either `Identity` must change both by hand until the bridge lands.**
- **The render path has not been device-verified.** `app/android/` and
  `app/ios/` exist and the project is structurally complete and analyzable,
  but no build, run, or launch on a simulator, emulator, or physical device
  has ever been attempted. Every guarantee below §8 comes from unit and
  widget tests against a faked `FilamentSurface`. **That Thermion actually
  renders a body and swaps a cosmetic on real hardware is untested and
  unproven.** The spike recommended in §8 remains outstanding.
- **`docs/protocols/identity-link.md` and `docs/qa/test-plan.md` are
  stubs.** Not started.

## 8. Risks

- **thermion_flutter is young (v0.5.0)**: real risk of API instability or
  missing features once real cosmetic layering (multi-mesh compositing
  across all 18 slots) is attempted. Its API already diverged from what the
  plan assumed — `loadGltf`/`destroyAsset` on an asset handle, not
  `loadGlb`/`removeAsset` on a path — which is why
  `ThermionFilamentSurface` keeps a path→handle map. The `AvatarRenderer`
  interface exists specifically to contain this risk: if thermion proves
  inadequate, only `avatar_renderer/` changes. A spike rendering base body +
  1 swap on real Android and iOS targets should happen before treating this
  as load-bearing for M2+.
- **Placeholder art is not final art and is not necessarily "original" in
  the legal sense.** Must be replaced before any public release;
  `docs/legal/asset-policy.md` captures this.
- **No accounts/auth** means identity is device-local only — acceptable per
  the PRD's "create temporary local identity" flow, but this pass alone
  cannot demonstrate the NFC share → second device loop from the PRD's
  Definition of Done. That is M4 (sharing).

## 9. Testing (actual)

| Scope | Command | Covers |
|---|---|---|
| `identity_core` | `dart test` | `Identity` construction/copyWith/publicFields, JSON round-trip, Isar repository CRUD, avatar-JSON round-trip |
| `avatar_core` | `dart test` | 18-slot list, `copyWithSlot` including the unknown-slot error, JSON round-trip |
| `avatar_renderer` | `flutter test` | Asset-path resolution, `current` tracking, slot load/remove bookkeeping against a fake surface |
| `app` | `flutter test` | Identity edit screen (entry, privacy toggle, save), identity providers, avatar screen (render, swap, persist-after-load/swap, restore-on-mount) |
| `rust/core` | `cargo test`, `cargo clippy -- -D warnings` | Struct validation + serde round-trip |

The workspace sweep is `melos bootstrap && melos run analyze && melos run
test`, plus the Rust commands. `melos run test` fans out to two scripts:
`test:dart` (`identity_core`, `avatar_core` — pure Dart, `package:test`) and
`test:flutter` (everything else). A single `flutter test` cannot run the
pure-Dart packages.

## 10. Milestones this pass maps to

PRD M0 (architecture) fully, M1 (identity) fully, and a thin vertical slice
of M2 (avatar) — base body + 2 cosmetic slots only, no animation, no camera
controls. Full M2 (all 18 slots, animation, camera) and everything from M3
onward (real store, NFC, QR, backend) are deferred and tracked via the stub
package READMEs.
