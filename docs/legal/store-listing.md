# Amiro — Store Listing Draft

Draft copy for the Play Console / App Store Connect store listing. Fill in
the actual forms from this; nothing here is auto-published.

## App name

Amiro

## Short description (Play: 80 characters max)

Your digital identity, made wearable. Tap or scan to share.

(60 characters)

## Full description (Play: 4000 characters max)

Amiro is your personal digital identity — a 3D avatar you build once and
share everywhere.

**Build your avatar**
Choose a hairstyle, outfit, and accessories. Rotate it a full 360° to see
every angle. Your avatar is yours: it lives on your device, not on a
server.

**Share it instantly**
Show a QR code, or — on Android — just tap phones together. Whoever you
share with sees your avatar and whichever profile details you've chosen
to make public: your name, bio, social handles, whatever you decide.

**You control what's public**
Every field in your profile — email, phone, social handles, website — has
its own privacy toggle. Nothing you mark private ever leaves your device.

**No account needed**
There's no sign-up, no password, and no Amiro server. Your identity and
avatar are stored locally. Uninstalling the app removes them.

**A growing wardrobe**
Visit the Store to unlock new hairstyles, outfits, and accessories for
your avatar — some free, some purchasable.

Amiro is a novelty identity app for a simple moment: "This is me." Tap or
scan, and your digital identity appears.

## Category

Play: Social (or Lifestyle, depending on final policy classification)

## Contact details

- Email: coffee.devloper@gmail.com
- Privacy policy: https://developerscoffee.github.io/amiro/legal/privacy-policy.html

## Screenshots

4 captured 2026-09-28 on a real Pixel 9, from the actual release-signed
build (not debug — no compatibility ribbon), full device resolution
(1080x2424). Also published, downscaled to WebP, on the product page's
screenshot strip (`docs/index.html#screenshots`,
`docs/assets/screenshots/`):

1. Avatar screen, front-facing, chrome visible (name/valuation bar) —
   `avatar.webp`
2. Avatar mid-rotation (three-quarter view) — shows the 360° feature —
   `avatar-rotate.webp`
3. Store screen with the catalog visible — `store.webp`
4. Share screen — QR code shown, NFC section visible (Android) —
   `share.webp`

Play requires at least 2 phone screenshots (recommend 4-8) at 16:9 or
9:16, 320-3840px on the long edge — the full-resolution originals (not
the downscaled web copies) satisfy this; re-export from the device if
Play's upload rejects the web-sized copies.

**Not captured:** a Shared Profile screenshot (needs a second device or
person to actually send a profile to scan/receive) — the identity used
for these shots ("Alex" / "alex") is a generic placeholder, not a real
person's data.

## Feature graphic (1024x500, required for Play)

Not yet produced. Needs a simple background + the Amiro avatar + a
tagline, e.g. "Your identity, made wearable."

## App icon

Current icon (`app/assets/icon/icon.png`) is a placeholder generated for
internal testing (purple background, white person glyph) — not
production-ready. Needs a real icon before a production listing.

## Content rating questionnaire — draft answers

(Google's IARC questionnaire; answer inside Play Console, this is a guide)

- Violence: None
- Sexuality: None
- Profanity: None
- Controlled substances: None
- Gambling: None (no real-money mechanics; cosmetic purchases are
  cosmetic-only, not loot boxes/randomized)
- User-generated content / user interaction: shares identity data with
  other users (peer-to-peer, not via a server) — answer "Yes" to
  "shares user's location" → **No**; "users can interact" → **Yes**
  (via QR/NFC share, not in-app messaging); "shares personal info with
  other users" → **Yes** (only fields the user marks public)
- Digital purchases: **Yes** (cosmetic items in the Store) — real Play
  Billing via RevenueCat as of 2026-09-29 (see
  `packages/store/lib/src/revenuecat_entitlement_store.dart`). The 3
  priced catalog items (`amiro_riviera_optics`, `amiro_long_flow`,
  `amiro_full_beard`) must still be created as in-app products in Play
  Console — Monetize → Products → In-app products — with matching product
  IDs before a release build can actually sell them; RevenueCat's catalog
  side is already set up (`rc products list`).

## Data safety form — draft answers

See `docs/legal/data-safety.md` for the full field-by-field draft.
