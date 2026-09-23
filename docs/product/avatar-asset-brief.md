# Avatar Asset Brief v1

**Status:** ready to hand to an artist/agency
**Owner:** Agent 6 (Asset/Content), per `docs/product/requirements.md`
**Date:** 2026-09-23

## 1. Why this exists

The foundation pass (see `docs/architecture/overview.md`) proved the render
pipeline end-to-end on real hardware (Pixel 9) using placeholder primitive
meshes — plain colored boxes. This brief specifies what a commissioned 3D
artist or studio needs to deliver so their work drops into that same
pipeline with no rendering-code changes.

**Context that shaped this decision:** we evaluated integrating a
third-party avatar service (Ready Player Me) instead of commissioning
original art. RPM shut down entirely on 2026-01-31 following a Netflix
acquisition — its avatar creator, API, and developer accounts are all
offline, with no public successor. The remaining alternative we priced
(MetaPerson/Avatar SDK) costs $800/month at production volume with no
meaningful free tier, and offers no Flutter SDK (would require a WebView
integration). Commissioned original art has a real one-time cost but no
recurring vendor dependency, no shutdown risk, full ownership, and is the
only path that cleanly satisfies the PRD's "original, not copied from
Bitmoji/Snapchat" requirement (`docs/legal/asset-policy.md`).

## 2. Style direction

- **Semi-stylized humanoid, not photoreal, not a licensed character
  likeness.** Proportions and styling should read as an original
  character design in the same *genre* as customizable social avatars
  (Bitmoji, Genies, VRoid) — approachable, slightly stylized proportions —
  **without copying** any specific competitor's model topology,
  textures, facial proportions, or signature visual style. See
  `docs/legal/asset-policy.md` for the binding constraint.
- Target audience is a general social app (not a specific game genre) —
  keep the base characters neutral enough to carry any cosmetic without
  looking out of place.

## 3. Technical requirements

### 3.1 File format

- **glTF 2.0 binary (`.glb`)**, single file per asset, matching every
  placeholder asset already in the repo (`packages/avatar_renderer/assets/`).
- PBR metallic-roughness material workflow. The renderer
  (`thermion_flutter`/Filament) uses a default ubershader material
  provider unless we configure otherwise — deliver standard
  baseColor/metallic/roughness/normal maps, no exotic shader graphs.
- No embedded animations required for v1 (the PRD's "basic animation" is
  a later milestone) — a bind-pose rig is sufficient for now, but **rig
  it properly anyway** (see 3.3) so animation can be added later without
  re-rigging.

### 3.2 Budget (mobile target)

- **Body base mesh:** ≤ 15,000 triangles.
- **Each cosmetic item** (hair, top, bottom, shoes, glasses, jewelry,
  hat, etc.): ≤ 2,000 triangles.
- **Textures:** 2048×2048 max, 1024×1024 preferred where it doesn't cost
  visible quality. Power-of-two dimensions.
- These are ceilings, not targets — lower is better as long as it doesn't
  look cheap. We're a mobile app rendering a live 3D scene on a phone GPU,
  not a cutscene renderer.

### 3.3 Rig (critical — this is what makes cosmetics attachable)

Use a **Mixamo-compatible humanoid skeleton** with standard bone names,
even though v1 ships no animation. Our cosmetic system attaches items to
named bones/sockets, so the names below are load-bearing, not cosmetic
preference:

```
Hips
├── Spine → Spine1 → Spine2 → Neck → Head
│                              ├── LeftShoulder → LeftArm → LeftForeArm → LeftHand
│                              └── RightShoulder → RightArm → RightForeArm → RightHand
├── LeftUpLeg → LeftLeg → LeftFoot
└── RightUpLeg → RightLeg → RightFoot
```

Every cosmetic mesh must be either:
- **Skinned to the same skeleton** (preferred for clothing — top, bottom,
  shoes — so it deforms naturally if/when animation is added), or
- **Rigid-parented to a single named bone** (for accessories — glasses →
  `Head`, earrings → `Head`, necklace/gold chain → `Neck`, watch →
  `LeftHand` or `RightHand`, hat → `Head`).

## 4. What maps to what (the 18 `AvatarDefinition` slots)

Reference: `packages/avatar_core/lib/src/avatar_definition.dart`,
`docs/protocols/avatar-format.md`.

| Slot | What's delivered | Attachment |
|---|---|---|
| `body` | Full base mesh: body + face + skin baked in as material variants (see 4.1) | — (this IS the skeleton root) |
| `face`, `skin` | Reserved for future material/blend-shape variants on the base body — **not separate meshes for v1**, see 4.1 | n/a |
| `hair` | Separate mesh | Skinned to `Head`/`Neck` region, or rigid-parented to `Head` |
| `eyes`, `eyebrows`, `facialHair` | Reserved for future — texture/material variants on the base face, **not separate meshes for v1** | n/a |
| `top`, `bottom`, `shoes` | Separate clothing mesh | Skinned to the shared skeleton |
| `glasses`, `earrings` | Separate mesh | Rigid-parented to `Head` |
| `necklace`, `goldChain` | Separate mesh | Rigid-parented to `Neck` |
| `watch` | Separate mesh | Rigid-parented to `LeftHand` (or `RightHand` — pick one convention, document it) |
| `hat` | Separate mesh | Rigid-parented to `Head` |
| `background`, `effects` | Not character assets — scene/environment, out of scope for this brief | n/a |

### 4.1 Why `face`/`skin`/`eyes`/`eyebrows`/`facialHair` aren't separate meshes yet

`AvatarDefinition`'s schema reserves these slots (matches the PRD's
full component list exactly), but for v1 the cheapest way to get real
visual variety is **material/texture variants on the single base body
mesh** (a handful of skin tones, a couple of face textures) rather than
swappable geometry — swappable face geometry is real character-rigging
complexity (blend shapes, face-specific bone rigs) that's out of scope
for a first art pass. If the artist delivers 2-3 base body variants
(different skin tone materials, same mesh/rig), that's enough to prove
the slots aren't dead — full customization of these slots is a later
iteration.

## 5. v1 delivery scope (start small, not the PRD's full catalog)

The PRD's long-term target (`docs/product/requirements.md`) is 10
hairstyles, 10 tops, 10 bottoms, 10 glasses, 10 chains, 10 shoes, 10
accessories, 5 backgrounds. **Do not commission all of that up front.**
Start with enough to prove the real pipeline end-to-end and replace the
placeholder boxes, then expand once the look is validated:

- 1 base body (1 skin-tone material variant to start)
- 1 hairstyle
- 2 tops
- 1 pair of glasses
- 1 pair of shoes

That's enough to exercise every attachment point in §4 and give a real
first impression, without over-committing budget before the art
direction is validated.

## 6. File naming and delivery location

Match the existing placeholder naming convention exactly — the renderer
resolves `packages/avatar_renderer/assets/{avatars|cosmetics}/<assetId>.glb`
(`packages/avatar_renderer/lib/src/avatar_asset_resolver.dart`):

- Body → `packages/avatar_renderer/assets/avatars/body_<variant>.glb`
  (e.g. `body_001.glb`)
- Everything else → `packages/avatar_renderer/assets/cosmetics/<slot>_<variant>.glb`
  (e.g. `hair_001.glb`, `top_001.glb`, `glasses_001.glb`)

Deliverables must also include: source files (`.blend`/`.ma`/`.fbx` or
equivalent, whatever the artist's tool produces) kept outside the repo's
shipped assets, plus a completed entry in `assets/LICENSES.md` and
`assets/ATTRIBUTIONS.md` (create these per the PRD's Agent 6 responsibility
if they don't exist yet) confirming original authorship and commercial
usability.

## 7. Acceptance check (before merging into the repo)

- [ ] Opens and validates as glTF 2.0 in a standard validator
      (e.g. https://github.khronos.org/glTF-Validator/)
- [ ] Triangle/texture budgets from §3.2 respected
- [ ] Bone names match §3.3 exactly (case-sensitive)
- [ ] Renders correctly through the existing pipeline
      (`ThermionAvatarRenderer` — load, verify visible, verify lit; the
      camera/light setup already in
      `packages/avatar_renderer/lib/src/thermion_avatar_renderer.dart`
      should work unchanged, adjust if the model's scale/origin differs
      significantly from the placeholder boxes)
- [ ] No third-party/unlicensed likeness per `docs/legal/asset-policy.md`
- [ ] File named and placed per §6
