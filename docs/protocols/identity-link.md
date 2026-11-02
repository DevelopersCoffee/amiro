# Identity Link Protocol

**Status:** implemented on-device (custom scheme). The PRD's shorter
`https://id.amiro.app/u/<id>` App Link / web fallback is **not** built yet.

## Primary: encounter links (current Share tab)

```
amiro://encounter?d=<base64url(AmiroSharingPayload JSON)>
amiro://encounter?d=...&c=<base64url(ContactCard JSON)>   # optional
```

- Encoded/decoded in `packages/sharing/lib/src/encounter_qr.dart`
  (`encodeEncounterUri`, `decodeEncounterUri`). Max URI length 2000
  characters for QR/NFC.
- Payload schema: `packages/sharing/lib/src/amiro_sharing_payload.dart`
  (`schemaVersion`, collection, equipped cosmetics, etc.).
- App routing: `app/lib/sharing/scan_result.dart` → encounter comparison →
  optional save to passport (`packages/discovery`).

## Legacy: profile links (older builds)

```
amiro://share?d=<base64url(json)>
```

- Built/parsed by `packages/sharing/lib/src/share_payload_codec.dart`
  (`buildShareUri`, `parseShareUri`) as a `SharedProfile` (username, contact
  fields, avatar JSON, owned cosmetic ids).
- Still **received** (QR, NFC, deep link) and open
  `SharedProfileScreen`; new shares emit `amiro://encounter` instead
  (`app/lib/sharing/own_encounter.dart`).

## Transport

| Channel | Package | Notes |
|---|---|---|
| QR generate | `packages/qr` | `buildQrWidget(fullUri)` |
| QR scan | `app/lib/sharing/qr_scan_screen.dart` | camera → `resolveScannedText` |
| NFC emulate | `packages/nfc` | Android HCE, URI as NDEF text |
| NFC read | `packages/nfc` | NDEF → first `amiro://` link |
| Cold/warm deep link | `app/lib/sharing/sharing_providers.dart` (`incomingShareLinkProvider`) | `app_links`; UI in `incoming_share_listener.dart` |

See each package's `README.md` for interfaces; historical design notes remain
in `docs/superpowers/specs/2026-09-23-nfc-sharing-design.md`.
