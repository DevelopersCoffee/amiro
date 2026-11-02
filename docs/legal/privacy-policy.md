# Amiro Privacy Policy

**Last updated:** 2026-11-03

This policy describes what Amiro ("the App") does with your information.
Amiro is local-first: your identity, avatar, and passport (people you've
met) live on your device by default. There is no email-and-password Amiro
account, and no analytics or advertising SDK in the App. The App does use
the network for (1) optional profile backup/restore and (2) verifying
real-money Store purchases — see those sections below. Sharing with another
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

- On first launch (and when your identity changes), the App may create an
  anonymous Supabase session and upload a copy of your identity fields and
  avatar definition JSON. Row access is protected by Supabase row-level
  security; the App uses Supabase's public ("anon") key, not a root
  password.
- The App gives you a **recovery code** (stored on your device) you can use
  on another install to pull that profile back.
- The backup may also store RevenueCat's anonymous purchase user id next to
  your profile so purchases and identity can be reconciled after restore —
  not your name, email, or phone from the profile form.
- Your passport / encounter history stays **local only** (not uploaded).

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

## What the App does not do

- No traditional account (no email sign-up, no password login).
- No analytics or advertising SDKs.
- No selling of your data.
- No location data is collected.
- Sharing and passport data are not uploaded to our servers (only the
  optional profile backup and purchase audit paths described above use
  the network).

## Your control over your data

- Editing or clearing a field in your identity removes it on your device
  immediately; the next successful backup sync updates the cloud copy.
- Uninstalling the App removes local Amiro data, subject to your device's
  own OS behavior (for example, an OS-level backup you created yourself).
- There is no password-based Amiro account to delete. To remove a cloud
  profile backup or purchase audit row, email
  coffee.devloper@gmail.com — these are not always removed automatically
  on uninstall because they exist to support restore.

## Children's privacy

Amiro is not directed at children and we do not knowingly collect
information from children. We do not ask for age. Profile backup and
purchases are initiated by whoever uses the App on the device.

## Changes to this policy

If Amiro's data practices change materially, this policy will be updated
and the "Last updated" date above will change.

## Contact

Questions about this policy: coffee.devloper@gmail.com
