# sharing

Owns the on-wire identity and discovery payloads plus URI codecs the app,
NFC, and QR layers share.

**Primary link (Share tab today):** `amiro://encounter?d=<base64url(payload)>`
with optional `&c=<base64url(contact card)>`. Built by
`encodeEncounterUri` / parsed by `decodeEncounterUri` in
`lib/src/encounter_qr.dart` (`AmiroSharingPayload`, `ContactCard`).

**Legacy profile link:** `amiro://share?d=<base64url(json)>` via
`buildShareUri` / `parseShareUri` in `lib/src/share_payload_codec.dart`
(`SharedProfile`). Still accepted on receive (`app/lib/sharing/scan_result.dart`)
but no longer emitted for new shares.

**NDEF helpers:** `lib/src/ndef_encounter.dart` — decode NFC Forum text
records to an `amiro://` URI without depending on platform plugins.

Wired from `app/lib/sharing/` (identity card, QR scan, NFC receive, deep
links). The PRD's shorter `https://id.amiro.app/u/<id>` web fallback is
not implemented yet.
