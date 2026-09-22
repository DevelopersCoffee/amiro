# sharing

**Status: stub — not implemented.**

Owns the orchestration between `nfc`, `qr`, and deep-link resolution:
picking which channel to use, building the compact identity payload
(`https://id.amiro.app/u/<id>`), and routing an incoming tap/scan to
either the native profile screen (app installed) or a signal to open
the web fallback.

Planned interface (from `docs/superpowers/specs/2026-09-22-amiro-foundation-design.md`
and the product PRD's NFC/QR sections):

- `ShareableIdentityLink buildShareLink(String identityId)`
- `Stream<IncomingShare> listenForIncomingShares()`

Implemented in a future milestone (M4, Sharing), by the Sharing agent.
