# Amiro Privacy Policy

**Last updated:** 2026-11-25

This policy describes what Amiro ("the App") does with your information.
Amiro is local-first: your identity, avatar, and passport (people you've
met) live on your device by default. There is no email-and-password Amiro
account, and no third-party analytics or advertising SDK in the App. The App
does use the network for (1) optional profile backup/restore, (2) verifying
real-money Store purchases, and (3) optional, consent-gated diagnostics —
see those sections below. Sharing with another
person (QR/NFC) still goes directly device-to-device and does not pass
through our servers.

## Who this covers

Amiro is published by Developer's Coffee. This policy applies to the Amiro
mobile app on Android and iOS. It does not cover any third-party app,
website, or service you reach by tapping a link inside Amiro (for example,
a link you added to your own profile).

## What information the App handles

When you set up your Amiro identity, you may enter:

- Display name and username
- A short bio
- Mobile number, email address
- Social handles (X/Twitter, Instagram) and a personal website URL

This is stored **on your device** in a local database. Your avatar (body,
hair, outfit, and other cosmetic choices) is stored the same way.

### Optional profile backup (Supabase)

To help you recover your identity after reinstalling or moving to a new
phone, the App can back up your profile to a [Supabase](https://supabase.com/privacy)
database we operate:

- **Off until you turn it on.** Identity settings show a cloud-backup
  switch. Turning it on asks you to confirm (`cloud_backup_consent_dialog.dart`).
  The App does not upload a profile on first launch just because you opened
  it. After you accept, it creates an anonymous Supabase session and uploads
  your id, display name, username, avatar gender, avatar definition JSON, and
  privacy flags. Contact fields (bio, email, phone, socials, website) are
  included only when you marked them public. Row access is protected by
  Supabase row-level security; the App uses Supabase's public ("anon") key,
  not a service-role key.
- The App gives you a **recovery code** (stored on your device) you can use
  on another install to pull that profile back. The code is not a password
  for a Developer's Coffee account.
- The backup may also store RevenueCat's anonymous purchase user id next to
  your profile so purchases and identity can be reconciled after restore —
  not your name, email, or phone from the profile form.
- Your passport / encounter history stays **local only** (not uploaded).
- **Turning backup off** sends a delete for that profile row when this
  device's anonymous session is the owner that created it, then clears the
  recovery code and session stored on the device. It also deletes web-profile
  rows for that same Supabase user. If this device is not the owner session
  (another phone that only joined with the recovery code, a session that no
  longer matches, or a backup that was already removed), the App does **not**
  pretend the server copy is gone. It shows an error and points you at email
  deletion. There is no code-based server delete RPC; that option is
  documented in `docs/decisions/backup-delete-o1-o2.md` and is not shipped.
- Some installs from before the opt-in switch may already have a server row
  while the switch shows off. Turning backup on and then off again is the
  in-app path that issues the owner delete. Otherwise email
  coffee.devloper@gmail.com.

If backup fails (no network), the App keeps working from local storage only.

### Sharing with another person

Amiro's core feature is sharing your profile with someone else, by:

- **Showing them a QR code**, or **scanning theirs**
- **Tapping phones together (NFC)**, on Android

Before you share, you choose which fields are public. Only the fields you
mark public are included in what you show or send — anything you leave
private is not included in the QR/NFC payload. The other person's phone
reads that information directly from the QR code or NFC tap; it does not
pass through Developer's Coffee servers.

If you scan someone else's QR code or receive their NFC tap, whatever
public profile information they chose to share is stored on **your**
device, the same way your own profile is. You control that data (including
deleting it) on your device.

### Camera and NFC

- The App requests camera access only to scan a QR code someone shows you.
  No photo or video is captured, stored, or transmitted — the camera feed
  is used solely to detect a QR code.
- The App requests NFC access only to read an incoming tap-to-share, and
  (Android only) to let your phone emulate a tag so someone else can read
  your shared profile via NFC. No other NFC use.

## Purchases

The Store lets you buy optional cosmetic items with real money through
Google Play Billing. Purchases are processed by
[RevenueCat](https://www.revenuecat.com/privacy), which we use to verify a
purchase actually happened before unlocking the item.

What that involves:

- The App SDK sends RevenueCat a random per-install identifier (not your
  name, email, or anything from your Amiro profile) and the product you're
  buying. RevenueCat validates the purchase with Google Play and reports
  the result back to the App.
- RevenueCat notifies our backend (a Cloudflare Worker) when a purchase
  completes. We record the event — the random per-install identifier, the
  product bought, and the timestamp — in a Supabase database, so we can
  look up and restore your purchases if needed (for example, after
  reinstalling). This record never includes your name, email, phone
  number, or any other profile field from the identity form.
- None of this is used for advertising, and we don't sell or share it with
  anyone beyond RevenueCat and Google Play, who process it to complete the
  purchase.

If you don't use the Store's paid items, none of the purchase network
traffic applies to you — free cosmetics unlock without a purchase request.

### Optional crash reports

Some release builds can send error summaries to help us fix bugs:

- Crashes are always logged locally on your device first.
- **Upload is off by default.** In Identity settings you can turn on
  **Share crash reports** to send scrubbed error text (message and stack) to
  our Cloudflare Worker, which stores it in Supabase for engineering review.
- Only a short message (error type plus the **scrubbed first line** of the
  error text), allowlisted Dart `package:` / `dart:` stack frames, app version,
  and platform are uploaded. Known secret patterns (JWTs, tokens, paths, etc.)
  are stripped on device and again on the server; **other incidental words in
  that line may still be present.** Your profile, passport, and purchase fields
  are not sent as structured data.
- Cloudflare may process your IP address in transit for DDoS protection and
  rate limiting; we do not store IP in the crash database.
- Server copies are deleted automatically after **90 days**.
- Turn the setting off any time — uploads stop immediately. Uninstalling
  removes the local log. See `docs/protocols/crash-report-data.md`.

### Optional product analytics

You can help us understand whether setup, sharing, and the Store are working:

- **Off by default.** In Identity settings, **Privacy & diagnostics → Product
  analytics** sends a small set of anonymous counts (for example, setup
  finished, first share, purchase completed).
- Events include only coarse day, app version, platform, and a random
  install-scoped id we regenerate when you turn analytics off. See
  `docs/analytics/event-inventory.md`.
- No names, contacts, avatar data, encounter details, share links, or prices.
- Data goes to the same Cloudflare Worker → Supabase path as crash reports,
  with server-side allow-lists. We do not store your IP or browser User-Agent
  with analytics rows.

## What the App does not do

- No traditional account (no email sign-up, no password login).
- No third-party analytics or advertising SDKs.
- No selling of your data.
- No location data is collected.
- Passport data is not uploaded to our servers.
- **Opt-in web profile** (`https://id.amiro.app/u/…`): only if you publish
  from Share settings (hidden in store builds until explicitly enabled).
  Published name, public contact fields, avatar PNG, and optional cosmetic
  summary are stored in Supabase and served by our Cloudflare Worker.
  Revoking wipes those fields server-side and the link returns gone (410).
- Other sharing (QR/NFC `amiro://encounter`) stays device-to-device unless
  you choose the HTTPS link on QR/NFC after publishing.
- Optional profile backup and purchase audit still use the network as
  described above.

## Your control over your data

- Editing or clearing a field in your identity removes it on your device
  immediately; the next successful backup sync updates the cloud copy.
- Uninstalling the App removes local Amiro data, subject to your device's
  own OS behavior (for example, an OS-level backup you created yourself).
- There is no password-based Amiro account to delete.
- **Deleted when an owner device turns backup off successfully:** the
  `profiles` row for that identity, and that user's `web_share_profiles`
  rows. The recovery code and anonymous session are cleared on the device.
- **Kept:** the anonymous Supabase Auth user is not deleted by that toggle.
  Purchase audit rows (`revenuecat_events`, `entitlement_grants`) are not
  deleted by turning backup off. Crash and analytics rows, when you opted
  in, follow their own retention (90 days) and are not your profile.
- To remove a leftover cloud profile, an anonymous auth user, or a purchase
  audit row, email coffee.devloper@gmail.com. These are not always removed
  on uninstall because they exist to support restore.
- What you share by QR or NFC is described in
  `docs/protocols/encounter-share-data.md` (`amiro://encounter`, optional
  `c=` contact card). Bundled fonts and meshes are listed in
  `assets/LICENSES.md` (SIL Open Font License where noted).

## Children's privacy

Amiro is not directed at children and we do not knowingly collect
information from children. We do not ask for age. Profile backup and
purchases are initiated by whoever uses the App on the device.

## Changes to this policy

If Amiro's data practices change materially, this policy will be updated
and the "Last updated" date above will change.

## Contact

Questions about this policy: coffee.devloper@gmail.com
