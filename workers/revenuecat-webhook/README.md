# amiro-revenuecat-webhook

Cloudflare Worker (free tier) that receives RevenueCat webhook events and
writes them to Supabase. See `TODOS.md` #15 for the full picture of what's
wired up and what's still pending (Play Console products, RC↔Play service
account link, iOS).

The Flutter app never calls this Worker. Entitlements on-device come from
the RevenueCat SDK's `CustomerInfo` cache
(`packages/store/lib/src/revenuecat_entitlement_store.dart`). Since #43 the
app **does** talk to the same Supabase project for optional **profile**
backup/restore (`SupabaseProfileCloud` in `app/lib/identity/`), using the
public anon key and row-level security — not this Worker's service-role
path. This Worker exists for purchase-event audit (support, fraud review,
restoring purchase history if the SDK cache is ever lost).

## Request flow

```
Play Billing purchase
  -> RevenueCat SDK (packages/store/lib/src/revenuecat_entitlement_store.dart)
  -> RevenueCat backend validates the receipt
  -> RevenueCat webhook POSTs the event to this Worker
  -> Worker verifies the URL's secret path segment, then writes to Supabase
     (revenuecat_events: full event log; entitlement_grants: current state)
```

## Crash report ingest (`POST /crash/<token>`)

Optional opt-in crash uploads from the Flutter app (see
`docs/protocols/crash-report-data.md`). Configure:

- `CRASH_PATH_TOKEN` — **public, not a secret.** It is compiled into release
  builds via `--dart-define=AMIRO_CRASH_INGEST_URL=https://…/crash/<token>`;
  anyone with the APK can extract it. It only reduces drive-by spam together
  with rate limiting. Rotate by deploying a new token with `wrangler secret put
  CRASH_PATH_TOKEN`, updating the dart-define, and shipping a new app build.
- `CRASH_RATE_LIMITER` — required binding in `wrangler.toml` (10 requests /
  minute **per client IP** via Cloudflare Rate Limiting). If the binding is
  missing at runtime, crash ingest returns **503** (fail closed).

**Retention:** `supabase/migrations/20261118130000_crash_reports_retention.sql`
schedules a `pg_cron` job to delete rows older than 90 days. Supabase must have
the `pg_cron` extension enabled for your project (`create extension if not exists
pg_cron with schema extensions` in the migration). If cron is unavailable, rows
remain until you run an equivalent purge manually.

## Secrets

Set with `wrangler secret put <NAME>` (never commit these):

- `WEBHOOK_PATH_TOKEN` — random token; the webhook URL is
  `https://amiro-revenuecat-webhook.developerscoffee.workers.dev/webhook/<token>`.
  Regenerate with `openssl rand -hex 16` if it's ever exposed, then update
  the webhook URL in RevenueCat (`rc webhooks update <id> --url ...`).
- `SUPABASE_URL` — `https://<project-ref>.supabase.co`.
- `SUPABASE_SERVICE_ROLE_KEY` — from `supabase projects api-keys
  --project-ref <ref>`. This bypasses Row Level Security — treat it like
  a root DB password. The migration
  (`supabase/migrations/20260929060138_create_entitlements.sql`) enables
  RLS with no policies, so only the service role can read/write these
  tables; nothing else should ever be given this key.

## Deploy

```bash
cd workers/revenuecat-webhook
npm install
npx wrangler deploy
```

## RevenueCat project reference

RevenueCat project `Amiro` (`proj9768d0fc`), set up via the `rc` CLI:

- App: `app51bedf1b9c` (Play Store, package `com.developerscoffee.amiro_app`)
- Products (one-time, non-consumable): `amiro_riviera_optics`,
  `amiro_long_flow`, `amiro_full_beard` — store IDs must match Play
  Console's in-app product IDs exactly once those are created there.
- Entitlements: `cosmetic_<catalog id>`, one per product, 1:1.
- Webhook: `whintgrb5c7c2a4a3` → this Worker.

Re-run `rc apps keys app51bedf1b9c` to get the public Android SDK key if
`packages/store/lib/src/revenuecat_keys.dart` is ever regenerated — it's
safe to commit (RevenueCat's client-facing keys are public by design), but
avoid printing the value into a shell transcript out of habit; pipe it
straight into the target file instead.
