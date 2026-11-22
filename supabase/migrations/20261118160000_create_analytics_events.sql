-- Minimal product analytics posted by the app through the Cloudflare Worker.
-- Written only with the service role. No client read policies.

create table if not exists public.analytics_events (
  id bigint generated always as identity primary key,
  event_name text not null,
  event_day date not null,
  app_version text not null,
  platform text,
  install_id uuid not null,
  surface text,
  sku_kind text,
  community_slug text,
  src text,
  received_at timestamptz not null default now()
);

create index if not exists analytics_events_name_day_idx
  on public.analytics_events (event_name, event_day);

create index if not exists analytics_events_install_id_idx
  on public.analytics_events (install_id, received_at desc);

alter table public.analytics_events enable row level security;