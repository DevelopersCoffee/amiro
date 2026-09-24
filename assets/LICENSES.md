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
  Refitted for the head-and-shoulders camera on 2026-09-25: the close-up
  showed the earlier fit was ~2x too wide and sat at the cheeks, so the
  mesh was rescaled 0.55x about its own center and shifted +0.05 up /
  +0.08 forward (baked into `POSITION` again, original left untouched in
  git history).

## Hairstyles and beard (Quaternius, Universal Base Characters [Standard])

- **Source:** https://quaternius.itch.io/universal-base-characters
  (free "Standard" download, `Universal Base Characters[Standard].zip`,
  ~122 MB; the same pack the body comes from).
- **License:** CC0 1.0 Universal (per the pack's `License_Standard.txt`) —
  no attribution required.
- **What we use:** the "Origin at 0" glTF hairstyles that share the male
  body's coordinates — `Hair_SimpleParted`, `Hair_Buzzed`, `Hair_Long`,
  `Hair_Beard`. (`Hair_Buns` and `Hair_BuzzedFemale` use a different
  origin/units for the female body and are not shipped.)
- **Processing:** the pack's hair textures are un-tinted grey; textures
  downscaled to 512x512 (each file ~0.6-0.8 MB instead of ~6 MB) and
  embedded with `gltf-pipeline -b`. Hair, brow and beard color is applied
  at load time by multiplying the material `baseColorFactor` (linear
  0.35, 0.17, 0.08 = dark chestnut) in `ThermionFilamentSurface`. The
  body's own built-in eyebrow mesh is tinted the same way.
- **Shipped as:** `packages/avatar_renderer/assets/cosmetics/`
  `hair_simple_parted.glb`, `hair_buzzed.glb`, `hair_long.glb`,
  `beard_full.glb`.
- **Not used:** the separate "Modular Character Outfits - Fantasy" pack
  (280 MB of armor/robes; wrong style for a casual avatar).

## Village outfit (Quaternius, Modular Character Outfits - Fantasy [Standard])

- **Source:** https://quaternius.itch.io/modular-character-outfits-fantasy
  (free "Standard" download, ~280 MB; only the three Male Peasant parts
  were extracted).
- **License:** CC0 1.0 Universal — no attribution required.
- **What we use:** `Male_Peasant_Body` (tunic + belt), `Male_Peasant_Legs`,
  `Male_Peasant_Feet` from the "Modular Parts" glTF export. The pack's
  Peasant/Ranger outfits are the only ones in the free version, and are
  fantasy-styled, not modern casual.
- **Fit:** the parts are modeled for the pack's "Regular" build; the free
  Base Characters pack only contains the muscular "Superhero" build we
  use, so the meshes clipped through the chest and back. Positions are
  scaled outward and baked into the `POSITION` data (tunic 1.15x wide,
  1.35x deep about z=-0.06; trousers 1.15x/1.2x; boots 1.1x), tuned by
  on-device screenshots from front, side and back. Textures downscaled
  from 4096 to 512 px. Not rigged to the body's animation, static pose
  only, like the body.
- **Shipped as:** `packages/avatar_renderer/assets/cosmetics/`
  `top_peasant_shirt.glb`, `bottom_peasant_trousers.glb`,
  `shoes_peasant_boots.glb`.
- **Not used:** the Ranger outfits, and the separate `Arms` part (the
  tunic body already covers the visible upper sleeves).
