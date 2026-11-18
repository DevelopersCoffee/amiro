# Web recipient profile (https share link)

When the owner opts in, Amiro publishes a **public web profile** at an HTTPS
URL of the form `https://id.amiro.app/u/<token>`.

## What leaves the device

Publishing is consent-first and separate from QR/NFC `amiro://encounter`
links. Only after explicit publish does data go to Supabase:

| Data | Source |
| --- | --- |
| Opaque `token` | 128-bit random, server-generated on insert |
| `display_name` | Identity display name |
| `public_contact` | Fields the user marked public (`ContactCard` rules) |
| `card_extras` | Equipped cosmetics / collection progress when share toggles are on |
| `avatar_png` | Re-encoded PNG with EXIF and metadata stripped |

Email, phone, bio, and username never appear in the URL. The URL carries **only**
the token (no query, no `#` fragment).

## Resolution

1. Browser requests `GET https://id.amiro.app/u/<token>` on the **web-profile**
   Cloudflare Worker.
2. Worker looks up `public.web_share_profiles` by token (service role).
3. Active rows render an HTML profile with `Cache-Control: private, no-store`,
   a strict CSP (`frame-ancestors 'none'`), and related security headers.
   Revoked or tombstoned rows return **410** with the same cache policy.
4. Avatar bytes are served from the same row (`GET .../avatar`).

## Owner controls

- **Publish** upserts the row for the signed-in owner (`owner_id` is unique).
- **Revoke** wipes PII columns, sets `revoked_at`, and keeps a tombstone so the
  URL still returns 410.
- **Rotate** issues a new token and clears `revoked_at` on upsert.

Play builds ship with web publish UI hidden until
`AMIRO_WEB_SHARE_PUBLISH_ENABLED=true` is set at compile time **and** the
Worker plus migrations are deployed.

`amiro://encounter` QR/NFC shares continue unchanged when web publish is off.
When published, the Share tab prefers the HTTPS link on QR and NFC.

## Privacy

- RLS: only `owner_id = auth.uid()` can read/write their rows via the app.
- No analytics or third-party assets on the web page.
- `noindex` on the HTML profile by default.

See also `encounter-share-data.md` and Security & Trust issue #50 section 1.