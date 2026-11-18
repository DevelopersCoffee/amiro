# amiro-web-profile

Cloudflare Worker that serves opt-in public web profiles at `GET /u/<token>`.

## Why Worker + Supabase

- Matches the existing `revenuecat-webhook` pattern and keeps PII off URLs.
- Supabase holds rows behind RLS; only the Worker (service role) resolves tokens
  for anonymous browsers.
- Revoke returns **410** with `Cache-Control: no-store` at the edge.

## Deploy

```bash
cd workers/web-profile
npm ci
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_SERVICE_ROLE_KEY
npm run deploy
```

Route `id.amiro.app/u/*` (or your chosen host) to this Worker in Cloudflare.

Apply migration `20261118120000_web_share_profiles.sql` to Supabase before first
publish.