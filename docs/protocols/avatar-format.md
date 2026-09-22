# Avatar Definition Format

`AvatarDefinition` (see `packages/avatar_core/lib/src/avatar_definition.dart`)
is the platform-independent avatar identity. Same definition renders
identically on Android and iOS via `packages/avatar_renderer`.

## Schema

```json
{
  "id": "string, required, unique per avatar",
  "body": "string | null — asset id, e.g. body_001",
  "face": "string | null",
  "skin": "string | null",
  "hair": "string | null",
  "eyes": "string | null",
  "eyebrows": "string | null",
  "facialHair": "string | null",
  "top": "string | null",
  "bottom": "string | null",
  "shoes": "string | null",
  "glasses": "string | null",
  "earrings": "string | null",
  "necklace": "string | null",
  "goldChain": "string | null",
  "watch": "string | null",
  "hat": "string | null",
  "background": "string | null",
  "effects": "string | null"
}
```

## Asset resolution

An asset id resolves to a packaged glTF/GLB file via
`packages/avatar_renderer/lib/src/avatar_asset_resolver.dart`:
`body` slot → `packages/avatar_renderer/assets/avatars/<id>.glb`; every
other slot → `packages/avatar_renderer/assets/cosmetics/<id>.glb`. The
assets are packaged inside `avatar_renderer`, not at the repository root,
so the renderer package is self-contained.

## Persistence

A definition is persisted as its JSON encoding in
`Identity.avatarDefinitionJson`, stored in the single-row Isar
`IdentityRecord` alongside the identity's other fields. `identity_core`
treats it as opaque text — it does not depend on `avatar_core`.

## Current status (as of the foundation pass)

Only `body`, `top`, `glasses` are populated with real (placeholder)
assets. The remaining 15 slots are defined in the schema but have no
shipped assets yet — that's Agent 6/Asset Content's future work.
