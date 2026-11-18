# Analytics event inventory

Consent-first, minimal events for the traction funnel (#53, #54, #63). No
third-party SDK. Sent only after the user turns on **Product analytics** in
Identity → **Privacy & diagnostics**.

**Install id:** random UUID, install-scoped, regenerated when analytics is
turned off. Not linked to identity, contacts, RevenueCat, or Supabase backup.

**Retention:** 24 months in `analytics_events`, then aggregate or delete
(manual ops until #63 reporting ships).

| Event | Trigger | Properties | Metric |
|---|---|---|---|
| `setup_complete` | First save with non-empty display name and avatar loaded | common only | 40% setup completion |
| `first_share` | First NFC emulate start or web profile publish | common only | 25% share once |
| `paywall_shown` | Store tab or buy tap after first share | `surface` | Free-to-paid funnel |
| `purchase` | RevenueCat purchase succeeds (not restore) | `sku_kind` | 5–10% conversion |
| `second_encounter` | Unique passport count reaches 2 | common only | 10% second encounter |
| `invite_sent` | First web link copy | common only | Invite / share growth |
| `export_shared` | First “Made in Amiro” export (#59) | common only | Share growth |

### Common fields (every event)

| Field | Purpose |
|---|---|
| `event` | Allow-listed name |
| `event_day` | Coarse UTC day (`YYYY-MM-DD`) |
| `app_version` | Build label |
| `platform` | `android` / `ios` / … |
| `install_id` | Pseudonymous de-duplication |

### `surface` (paywall_shown)

`store_tab`, `payment_ask`, `store_item`

### `sku_kind` (purchase)

`cosmetic`, `plus`, `pack`

### Reserved for #62 (attribution)

Optional `community_slug` from `beta`, `launch`, `organic` and `src` from
`share`, `export`, `store_listing`. Not sent until install attribution ships.

### Ingest

`POST https://<worker>/analytics/<ANALYTICS_PATH_TOKEN>` on the same
`amiro-revenuecat-webhook` Worker as crash ingest (separate path token).
Build flag: `--dart-define=AMIRO_ANALYTICS_INGEST_URL=...`