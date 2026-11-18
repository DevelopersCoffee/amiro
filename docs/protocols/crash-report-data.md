# Crash report upload (opt-in)

**When it applies:** only in builds made with
`AMIRO_CRASH_INGEST_URL`, and only after the user turns on **Share crash
reports** in Identity settings.

## What leaves the device

| Field | Content |
|---|---|
| `runtimeType` | Dart type name of the error (e.g. `StateError`) |
| `message` | Error type plus the **first line** of the error text, scrubbed (≤300 chars) |
| `stack` | Only Dart `package:` / `dart:` stack frames (no file paths or native frames) |
| `source` | `flutter` or `platform` |
| `appVersion` | Build version (e.g. `1.0.6+12`) |
| `platform` | `android` or `ios` |

The client does **not** send profile fields, purchase IDs, recovery codes, or
device advertising identifiers. Before upload, only the first line of the
message is considered; that line is scrubbed for JWTs, bearer tokens, UUIDs,
URLs (including query/fragment tokens), **32-character hex strings**, **Google
Play **order IDs** (`GPA.…`) and explicit `purchaseToken` fields, emails, phone numbers, and file paths
(Unix, `file://`, and Windows-shaped). **Scrubbing is pattern-based:** incidental
free text (for example a `displayName` inside a JSON fragment) may still appear
if it does not match a redaction rule.

## Where it goes

1. **Device:** full `error.toString()` / stack may be appended to
   `crashes.jsonl` locally (unchanged on revoke).
2. **HTTPS POST** to the Cloudflare Worker path `/crash/<CRASH_PATH_TOKEN>`
   (token is compiled into the app; it gates abuse, not secrecy).
3. **Cloudflare** may process the client IP for rate limiting and DDoS
   protection; that IP is not stored in our application database.
4. **Supabase** table `crash_reports` (service role only): scrubbed fields
   above plus server `occurred_at` / `received_at`. Rows are deleted
   automatically after **90 days**.

## Encryption

TLS in transit. No crash report encryption at rest beyond Supabase platform
defaults.