# NFC/QR Sharing Design

**Status:** approved for implementation
**Date:** 2026-09-23
**Owner:** Product owner (Uday) + agent team
**Supersedes:** the "not started" status in `docs/protocols/identity-link.md`

## 1. Purpose

Implement the PRD's core viral loop — "tap phones together, your identity
appears" — as a real, working feature, matching the M4 (Sharing) milestone.
This pass builds the actual sharing mechanics (generate, scan, tap, parse,
display) and defers the pieces that need infrastructure that doesn't exist
yet (a domain, a backend).

## 2. Critical platform constraint (why this isn't symmetric)

NFC "tap to share" requires the *sending* phone to emulate a tag (Host Card
Emulation) that the *receiving* phone reads. Reading is unrestricted on both
platforms. Emulating is not:

- **Android**: HCE has been available to third-party apps for over a decade
  (`HostApduService`). No restrictions relevant to this use case.
- **iOS**: third-party HCE only shipped in iOS 17.4, and only for users in
  the EEA, only with a special Apple entitlement, and only for Apple-approved
  categories (payments, transit, keys, badges, tickets) — general profile
  sharing does not qualify. An iPhone cannot be the sender in a generic
  tap-to-share flow. This is Apple policy, not a technical gap we can code
  around.

Verified via [NFCore's platform comparison](https://nfcore.app/guides/iphone-nfc-vs-android-nfc)
and [HCE guide](https://nfcore.app/guides/what-is-host-card-emulation),
2026-09-23.

**Consequence:** NFC emulate (be the tap target) is Android-only. NFC read
(tap against someone) works on both. QR is therefore the true universal
mechanism — this matches the PRD's own framing of QR as co-equal to NFC, not
a fallback, and the earlier "don't depend on Instant Apps/App Clips"
decision in the same spirit: don't build v1's core loop on a capability one
platform can't have.

## 3. Scope for this pass

**In scope:**
- QR generate + scan, identical on both platforms.
- NFC read (both platforms) and NFC emulate (Android only).
- A self-contained share payload (see §4) — no backend dependency.
- A new "Shared Profile" screen to actually display what was received.

**Explicitly deferred (needs a domain + backend, M5):**
- The PRD's `https://id.amiro.app/u/<id>` short-link format.
- Universal Links / App Links (needs a verified, hosted domain).
- The "app not installed → web profile" fallback (needs a hosted page).
- Server-side identity resolution (payload is self-contained instead, see
  §4 — this is the seam that absorbs the future swap).

## 4. Payload format

Compact JSON, base64url-encoded, carried as a custom-scheme URI:

```
amiro://share?d=<base64url(json)>
```

```json
{
  "v": 1,
  "id": "<identity id>",
  "displayName": "Uday",
  "username": "uday",
  "bio": "Software Engineer",
  "avatarDefinitionJson": "{\"id\":\"default\",\"body\":\"body_superhero_male\",...}",
  "email": "coffee.devloper@gmail.com",
  "mobile": "...",
  "xHandle": "...",
  "instagramHandle": "...",
  "website": "..."
}
```

- Only fields flagged public via `Identity.publicFields()` are included.
  `avatarDefinitionJson` is always included when present (the avatar itself
  isn't a privacy-sensitive field the way contact info is — it's what you
  chose to look like).
- Same payload for QR and NFC. If real-world NFC read speed/reliability
  suffers with the full payload (see §7 risk), trim to essential
  fields (`id`, `displayName`, `username`, `avatarDefinitionJson`) for the
  NFC path specifically — decided empirically during the device spike, not
  guessed now.
- `v: 1` exists so a future backend-lookup payload shape (`v: 2`, just an
  `id` + a resolve step) can be distinguished from this self-contained one
  without breaking old links.

## 5. Package architecture

```
packages/sharing/          # orchestration, no platform imports
  SharedProfile             # parsed receive-side model
  buildShareUri(Identity)   # Identity -> amiro://share?d=...
  parseShareUri(String)     # amiro://share?d=... -> SharedProfile?

packages/qr/                # generate + scan
  buildQrWidget(String uri)          # wraps qr_flutter
  scanQrCode() -> Future<String?>    # wraps mobile_scanner

packages/nfc/                # read (both) + emulate (Android only)
  readIncomingPayload() -> Stream<String>   # wraps nfc_manager
  writeIdentityPayload(String uri)          # Android: custom HCE service
  bool get canEmulate                       # false on iOS, true on Android
```

`app/` composes these: a Share screen (identity → QR always, NFC section
gated on `canEmulate`), a Receive flow (QR scan screen + NFC listener), and
the new Shared Profile screen — all Riverpod-wired the same way the avatar
and identity screens already are.

## 6. Technology choices

| Concern | Choice | Why |
|---|---|---|
| QR generate | `qr_flutter` ^4.1.0 | Stable, simple, low churn despite a 2023 last release |
| QR scan | `mobile_scanner` ^7.4.2 | Actively maintained (Sep 2026), both platforms |
| NFC read/write-to-tag | `nfc_manager` ^4.2.1 | Flutter-org maintained, both platforms, well-adopted |
| NFC emulate (Android) | custom `HostApduService` via platform channel | The one third-party package for this (`nfc_pro_manager`) has 4 likes/48 monthly downloads — HCE itself is a small, well-documented native API; owning it avoids depending on the least-adopted part of the dependency graph for the riskiest capability |
| Deep link URI handling | `app_links` ^7.2.1 | Both platforms; same package becomes the seam for real Universal/App Links later |

## 7. Risks

- **Untested native surface.** The custom Android HCE service has no
  existing pattern in this repo to follow (unlike `avatar_renderer`, which
  had `thermion_flutter` to wrap). Needs a real two-device spike before
  being trusted, same lesson as the avatar renderer's camera/lighting bugs
  that only showed up on real hardware.
- **NFC payload size vs. read reliability.** Untested at real payload size
  with real hardware; may need field-trimming for the NFC path specifically
  (see §4).
- **`qr_flutter` staleness.** Last published 2023. Low risk (QR rendering is
  a stable, narrow problem) but worth a periodic check that it still builds
  against future Flutter versions.
- **iOS has no send-side NFC UI at all this pass.** Intentional (§2), not an
  oversight — flagged here so it isn't "discovered" later as a bug.

## 8. Testing plan

- `packages/sharing`: payload encode/decode round-trip; `publicFields()`
  filtering never leaks private fields into the payload; malformed/foreign
  URI parsing fails closed (returns `null`, doesn't throw).
- `packages/qr`, `packages/nfc`: thin wrappers, tested via the same
  seam-and-fake pattern as `ThermionFilamentSurface` — no real scanner/NFC
  hardware needed for the wrapper logic itself.
- `app/`: widget tests for the Share screen's platform-gated NFC section,
  and the Shared Profile screen rendering from a fixed `SharedProfile`
  fixture.
- **Explicitly not unit-testable:** real camera QR scanning, real NFC
  emulate/read. Needs a device spike (two devices, or one + the product
  owner) before this pass is considered proven, matching the precedent set
  by the avatar renderer's Pixel 9 spike.
