# nfc

NFC transport for whatever `amiro://…` URI the Share flow builds (today
`amiro://encounter`, see `packages/sharing`).

- **`NfcReader` / `ManagerNfcReader`** — starts an NDEF read session and
  emits the first `amiro://` link found in tag records (strict UTF-8/UTF-16).
  Used from `app/lib/sharing/nfc_receive_screen.dart`.
- **`NfcEmulator` / `AndroidNfcEmulator`** — Android-only HCE: writes the
  URI to the native `AmiroHceService` over `MethodChannel('amiro/nfc_hce')`.
  iOS cannot emulate a general-purpose tag; the Share screen gates emulate UI
  on Android.

End-to-end tap-between-two-phones behavior is implemented but not fully
device-verified; see `docs/architecture/overview.md` §11.
