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

Route **only** `https://id.amiro.app/u/*` to this Worker (confirm domain ownership in Cloudflare).

`workers_dev` is **false** — the script is not served on `*.workers.dev`.

## Rate limiting (owner)

In-memory limits were removed. Configure a **Cloudflare Rate Limiting** rule (Security → WAF → Rate limiting), for example:

- URI path starts with `/u/`
- Threshold: 60 requests per minute per IP
- Action: block for 1 minute

Alternatively use the Workers Rate Limiting API binding when namespace IDs are provisioned.

## Migrations

Apply `20261118120000_web_share_profiles.sql` and `20261118140000_web_share_security_hardening.sql` before first publish.

## App kill-switch

Ship Play builds with `--dart-define=AMIRO_WEB_SHARE_PUBLISH_ENABLED=true` only after this Worker and migrations are live.