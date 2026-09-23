# Third-Party Asset Licenses

Tracks the license terms for every non-original 3D asset shipped in the
app. Every entry here is an **interim** asset per
`docs/product/avatar-asset-brief.md` — the plan is to replace these with
commissioned original art; this file exists so nobody forgets what's
borrowed in the meantime and what its terms are.

## Universal Base Characters (Quaternius)

- **Source:** https://quaternius.itch.io/universal-base-characters
- **License:** CC0 1.0 Universal (public domain) — free to use in
  personal, educational, and commercial projects, no attribution
  required.
- **What we use:** `Superhero_Male_FullBody` base model, converted from
  the pack's `.gltf` + `.bin` + textures into a single binary-embedded
  `.glb` via `gltf-pipeline -b` (npm). Two textures referenced by the
  source `.gltf` under mismatched filenames (`T_Hair_1_Normal_png.png`,
  `T_Eye_Normal_png.png` vs. the actual `..._Normal.png` files on disk —
  a Godot-export artifact in the pack itself) were copied to the
  expected names before conversion so nothing is silently missing.
  (An earlier attempt via `pygltflib` produced a `.glb` with 2 of 7
  textures embedded as empty data — `pygltflib`'s own image-to-buffer
  embedding is unsupported per its source; `gltf-pipeline` embeds all
  textures correctly.)
- **Shipped as:** `packages/avatar_renderer/assets/avatars/body_superhero_male.glb`
- **Not yet addressed:** file size (~15MB) is far above the asset
  brief's mobile budget (§3.2) — fine for on-device testing, needs
  texture compression/downscaling before any release build.

## Glasses Pack (iPoly3D, via Poly Pizza)

- **Source:** https://poly.pizza/bundle/Glasses-Pack-gPz05eJm9w
- **License:** Public Domain (CC0) — no attribution required.
- **What we use:** one model (`Glasses.glb`) from the 28-model pack.
  Its own baked node scale renders at ~2.2m wide. `loadGltf()` DOES
  respect a corrected node-level TRS transform (confirmed via a 25x-scale
  diagnostic test that rendered clearly oversized, ruling out the
  earlier theory that transforms were ignored) — the initial "barely
  visible" result was simply a miscalculated target scale (raw mesh
  extent doesn't map to real-world meters the way its own min/max
  values suggest). Final correction — scale ≈16.5x, positioned at
  approximate eye height/depth on the Quaternius body — is baked
  directly into the mesh's `POSITION` accessor data (leaving `NORMAL`
  untouched) rather than left as a node transform, since it's simpler
  to reason about and matches how the body asset ships. Calibrated by
  iterative on-device screenshots against the actual eye position, not
  computed analytically. Not rigged to the body's skeleton, just placed
  at a fixed world position, so it will only look right on this
  specific body at this specific pose.
- **Shipped as:** `packages/avatar_renderer/assets/cosmetics/glasses_realistic.glb`
