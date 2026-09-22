# qr

**Status: stub — not implemented.**

Owns generating a QR code for the identity share link and scanning an
incoming QR code. Planned interface:

- `Widget buildIdentityQrCode(String url)`
- `Future<String?> scanQrCode()`

Implemented in a future milestone (M4, Sharing), by the NFC/Sharing agent.
