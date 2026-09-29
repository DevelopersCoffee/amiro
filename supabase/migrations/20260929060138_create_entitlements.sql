-- RevenueCat webhook event log and entitlement grants.
--
-- The Flutter app never queries this table directly — it trusts the
-- RevenueCat SDK's own on-device entitlement cache (which RevenueCat
-- validates against Play/App Store receipts). This table is the
-- server-side record of truth for support, fraud review, and reconciling
-- store data if the SDK cache is ever wiped or disputed. Written only by
-- the Cloudflare Worker webhook receiver, using the service role key.

create table if not exists public.revenuecat_events (
  id bigint generated always as identity primary key,
  event_id text not null unique,
  event_type text not null,
  app_user_id text not null,
  product_id text,
  entitlement_ids text[] not null default '{}',
  store text,
  received_at timestamptz not null default now(),
  raw_event jsonb not null
);

create index if not exists revenuecat_events_app_user_id_idx
  on public.revenuecat_events (app_user_id);

create table if not exists public.entitlement_grants (
  app_user_id text not null,
  entitlement_key text not null,
  product_id text,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  primary key (app_user_id, entitlement_key)
);

alter table public.revenuecat_events enable row level security;
alter table public.entitlement_grants enable row level security;

-- No policies: only the service role (used by the Worker) can read or
-- write, since service role bypasses RLS. Anonymous/public clients get
-- nothing from these tables.
