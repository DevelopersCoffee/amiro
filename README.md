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
| `app/` | Flutter shell: Identity, Avatar, Store, Share, Passport tabs |
| `packages/identity_core/` | Identity model, privacy flags, local persistence |
| `packages/avatar_core/` | Avatar definition model |
| `packages/avatar_renderer/` | 3D avatar rendering (Filament via thermion_flutter) |
| `packages/store/` | Cosmetic catalog, RevenueCat entitlements, valuation |
| `packages/sharing/` | Share payloads, `amiro://encounter` / legacy `amiro://share` codecs |
| `packages/nfc/` | NFC read (NDEF) and Android HCE emulate |
| `packages/qr/` | QR widget for share URIs; scan UI lives in `app/` |
| `packages/discovery/` | Encounter ledger, passport, encounter state machine |
| `rust/core/` | Rust identity domain struct + serialization (not wired to Dart yet) |

License: MIT.
