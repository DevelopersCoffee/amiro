# qr

QR **generation** for share links. Scanning (camera + `mobile_scanner`) lives
in `app/lib/sharing/qr_scan_screen.dart`.

- **`buildQrWidget(String data, {double size})`** — brass-framed cream card
  wrapping `qr_flutter`. Pass the full URI string (today
  `encodeEncounterUri(...)` from `packages/sharing`, not raw JSON).

The package stays Flutter-dependent but does not import `app/` or
`packages/sharing/` so it can be tested in isolation.
