# Amiro

Your digital identity, made wearable. Local-first Flutter app: create a
3D identity, customize it with virtual cosmetics, share it by tapping
phones or showing a QR code.

Monorepo managed with [Melos](https://melos.invertase.dev/). See
[docs/](docs/) for product requirements, architecture, and protocols.

## Getting started

```bash
dart pub global activate melos
melos bootstrap
melos run analyze
melos run test
```

## Repository map

| Path | Owns |
|---|---|
| `app/` | Flutter application shell |
| `packages/identity_core/` | Identity model, privacy flags, local persistence |
| `packages/avatar_core/` | Avatar definition model |
| `packages/avatar_renderer/` | 3D avatar rendering (Filament via thermion_flutter) |
| `packages/sharing/`, `nfc/`, `qr/`, `store/` | Stubs — future milestones |
| `rust/core/` | Rust identity domain struct + serialization |

License: MIT.
