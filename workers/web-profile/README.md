# amiro-web-profile

Cloudflare Worker that serves opt-in public web profiles at `GET /u/<token>`.

## Deploy

```bash
cd workers/web-profile
npm ci
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
npm run deploy
```

Use **dedicated** secrets for this Worker (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`).
Do not reuse `WEBHOOK_PATH_TOKEN` or other values from `workers/revenuecat-webhook`.

Route **only** `https://id.amiro.app/u/*` to this Worker (confirm domain ownership in Cloudflare).

`workers_dev` is **false** — the script is not served on `*.workers.dev`.

## Rate limiting

`wrangler.toml` declares a **Workers Rate Limiting** binding:

- `PROFILE_RATE_LIMITER` — 60 requests / minute **per client IP**
- Missing binding → **503** (fail closed)

Provision a rate-limit namespace in Cloudflare and set `namespace_id` in `wrangler.toml` before production deploy.

## Migrations

Apply web share migrations through `20261122120000_web_share_token_base64url.sql`
before first publish (tokens are base64url without `=` padding).

## Publish limits (server)

`web_share_publish` allows at most **5** active (non-revoked) web profiles per owner.

## App kill-switch

Ship Play builds with `--dart-define=AMIRO_WEB_SHARE_PUBLISH_ENABLED=true` only after this Worker and migrations are live. Default is **off** (no dart-define).