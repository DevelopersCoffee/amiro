# Identity Link Protocol

**Status: not started.** Planned for milestone M4 (Sharing), owned by
the NFC/Sharing agent.

Planned shape (from the PRD): a compact identity URL,
`https://id.amiro.app/u/<id>`, used identically as the NFC payload and
the QR code content. The receiver's app (if installed) resolves it via
Universal Link / App Link to the native profile; otherwise it opens
the web fallback. NFC/QR never carry the full profile — only this
identifier.

See `packages/sharing/README.md`, `packages/nfc/README.md`,
`packages/qr/README.md` for the per-package planned interfaces.
