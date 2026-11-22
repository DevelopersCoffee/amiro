# Data that leaves the device — product analytics

## When it runs

Only if the user opts in under **Privacy & diagnostics → Product analytics**
and the build defines `AMIRO_ANALYTICS_INGEST_URL`. Default store builds omit
the URL.

## What is sent

Allow-listed fields documented in `docs/analytics/event-inventory.md`. No
display names, usernames, emails, avatar JSON, encounter records, share tokens,
or purchase amounts.

## What is not sent

- The other person in an encounter (any field)
- RevenueCat or Supabase user ids
- Advertising id or hardware serial
- IP address or User-Agent (Worker does not log them with events)

## Server enforcement

The Worker rejects unknown event names, caps body size (streamed, fail at 8 KiB),
rate-limits per client IP, validates `install_id` as a UUID, limits batch size,
and drops properties outside the allow-list before inserting into Supabase
(`analytics_events`, RLS on, no client read). Opting out triggers
`DELETE` by `install_id`. The path token is a **public URL gate** (same as
crash ingest), not a secret — it ships in release builds.