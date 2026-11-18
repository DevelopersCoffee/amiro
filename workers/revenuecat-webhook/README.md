# amiro-revenuecat-webhook

Cloudflare Worker for RevenueCat webhooks and consent-gated crash ingest (`POST /crash/<token>`).

## Secrets

```bash
npx wrangler secret put WEBHOOK_PATH_TOKEN
npx wrangler secret put CRASH_PATH_TOKEN
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
```

## Crash ingest rate limiting (owner)

The crash path token is embedded in the app build (`AMIRO_CRASH_INGEST_URL`). Configure a **Cloudflare Rate Limiting** rule on `POST /crash/*` (e.g. 30 requests/minute per IP) in addition to the secret path token.