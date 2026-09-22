# nfc

**Status: stub — not implemented.**

Owns reading and writing the compact identity deep-link payload over
NFC (tap-to-share). Planned interface:

- `Future<void> writeIdentityPayload(String url)`
- `Stream<String> readIncomingPayload()`

Implemented in a future milestone (M4, Sharing), by the NFC/Sharing agent.
