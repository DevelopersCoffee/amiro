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
3. Active rows render an HTML profile; revoked rows return **410** with
   `Cache-Control: no-store`.
4. Avatar bytes are served from the same row (`GET .../avatar`).

## Owner controls

- **Publish** upserts the row for the current identity.
- **Revoke** sets `revoked_at`; the link stops working everywhere.
- **Rotate** creates a new token and revokes the previous link.

`amiro://encounter` QR/NFC shares continue unchanged when web publish is off.
When published, the Share tab prefers the HTTPS link on QR and NFC.

## Privacy

- RLS: only `owner_id = auth.uid()` can read/write their rows via the app.
- No analytics or third-party assets on the web page.
- `noindex` on the HTML profile by default.

See also `encounter-share-data.md` and Security & Trust issue #50 section 1.