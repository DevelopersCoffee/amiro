-- Crash reports posted by the app through the Cloudflare Worker.
-- The app does not hold the service-role key. Written only by the Worker.
-- No policies: service role bypasses RLS; anon clients cannot read these rows.

create table if not exists public.crash_reports (
  id bigint generated always as identity primary key,
  message text not null,
  stack text not null default '',
  source text not null,
  app_version text not null,
  platform text,
  occurred_at timestamptz not null default now(),
  received_at timestamptz not null default now()
);

create index if not exists crash_reports_app_version_idx
  on public.crash_reports (app_version, received_at desc);

alter table public.crash_reports enable row level security;
