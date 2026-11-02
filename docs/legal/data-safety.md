# Amiro — Play Console "Data safety" form, draft answers

Fill the actual Play Console form from this. Re-check against the code
before submitting — this reflects the app as of **2026-11-03**, after:

- Real Play Billing via RevenueCat + Cloudflare Worker + Supabase entitlement
  audit (`workers/revenuecat-webhook/`,
  `packages/store/lib/src/revenuecat_entitlement_store.dart`).
- Optional profile backup/restore to Supabase (#43,
  `app/lib/identity/supabase_profile_cloud.dart`,
  `supabase/migrations/20261016180000_create_profiles.sql`).

If data handling changes again, update both this file and the live form
together.

**The form was re-submitted for real payments on 2026-09-29.** Profile
backup shipped later — re-check Play Console if you add new declared data
types for cloud-stored identity fields.

## Does your app collect or share any of the required user data types?

**Yes** — for purchases and optional profile backup (HTTPS to Supabase and
RevenueCat). Identity sharing (QR/NFC) and passport data remain
device-local / peer-to-peer and are documented below for Play's broader
wording.

## Data types

### Personal info

| Field | Collected? | Shared? | Processing | Purpose | Optional? |
|---|---|---|---|---|---|
| Name (display name) | Yes | Yes (device-to-device when user shares; optional Supabase backup) | Local Isar; may sync to Supabase over HTTPS with anon auth | App functionality | No (required at identity creation) |
| Email address | Yes | Yes, if marked public on share; optional Supabase backup | Local; optional HTTPS backup | App functionality | Yes (field optional) |
| Phone number | Yes | Yes, if marked public on share; optional Supabase backup | Local; optional HTTPS backup | App functionality | Yes |
| Other user IDs (username, social handles) | Yes | Yes, if marked public on share; optional Supabase backup | Local; optional HTTPS backup | App functionality | Yes |

Avatar definition JSON (cosmetic choices) follows the same pattern: local
always; included in optional Supabase backup, not in QR/NFC unless the
user shares their card.

### Photos or videos

- None. The camera is used transiently to detect a QR code
  (`mobile_scanner`); no image or video is captured, stored, or
  transmitted by the app.

### App activity / App info and performance

- None. No analytics SDKs. Optional local crash log file; HTTP upload only
  when built with `AMIRO_CRASH_INGEST_URL` (empty in default release builds).

### Device or other identifiers

| Field | Collected? | Shared? | Processing | Purpose | Optional? |
|---|---|---|---|---|---|
| RevenueCat `$RCAnonymousID` | Yes | Yes (RevenueCat) | SDK-generated on purchase | App functionality (IAP) | No when buying |
| Supabase auth user id | Yes | Yes (Supabase) | Anonymous session for profile backup | App functionality (restore) | Effectively required for cloud restore |

These identifiers are not used for advertising.

### Purchase history / financial info

RevenueCat's own SDK integration handles part of this disclosure category
in Play Console. In our own words:

| Field | Collected? | Shared? | Processing | Purpose | Optional? |
|---|---|---|---|---|---|
| Purchase history (product id, timestamp) | Yes | Yes (RevenueCat, Google Play) | HTTPS to RevenueCat; webhook to Worker → Supabase | App functionality (purchase verification, restore) | No — only when user buys a paid Store item |
| App-set installation identifier (RevenueCat's `$RCAnonymousID`) | Yes | Yes (RevenueCat) | Generated on-device by the RevenueCat SDK | App functionality | No, same as above |

Purchase audit rows in Supabase are separate from the optional profile
backup table; they do not include profile contact fields.

## Is all of the user data collected by your app encrypted in transit?

- **Identity/profile sharing (QR/NFC):** peer-to-peer; no Developer's Coffee
  server in the path.
- **Profile backup, purchases (Supabase/RevenueCat/Worker):** **Yes** — all
  HTTPS/TLS.

## Do you provide a way for users to request that their data be deleted?

**Partially.** Uninstalling removes local data. Cloud profile backup and
purchase audit rows may remain until the user emails
coffee.devloper@gmail.com (see `docs/legal/privacy-policy.md`). An in-app
"clear my data" control is not shipped yet (`IdentityRepository.clear()`
exists in code but is not exposed in UI).

## Data safety summary line (shown on the store listing)

Work through Play's actual flow question-by-question against this draft;
taxonomy for "collected" vs on-device-only fields changes over time.
