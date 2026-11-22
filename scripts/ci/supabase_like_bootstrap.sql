-- Minimal Supabase-shaped database for CI migration apply:
-- pgcrypto lives in extensions; default search_path is public only (no extensions).

\set ON_ERROR_STOP on

create schema if not exists extensions;
create schema if not exists supabase_migrations;

-- Roles referenced in migrations (Supabase-compatible names).
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
end
$$;

create table if not exists supabase_migrations.schema_migrations (
  version text primary key,
  statements text[],
  name text
);

-- Supabase installs pgcrypto in extensions, not public.
create extension if not exists pgcrypto with schema extensions;

-- pg_cron retention migrations (same layout as hosted Supabase).
create extension if not exists pg_cron with schema extensions;

-- auth.users FK target for profile / web-share tables.
create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);

create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select null::uuid;
$$;

alter database postgres set search_path to public;
set search_path to public;