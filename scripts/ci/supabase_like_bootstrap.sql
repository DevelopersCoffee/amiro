-- Supabase-shaped database for CI migration apply:
-- pgcrypto in extensions; default search_path is public only (no extensions).
-- Idempotent on vanilla Postgres and on supabase/postgres (auth schema is protected).

\set ON_ERROR_STOP on

create schema if not exists extensions;
create schema if not exists supabase_migrations;

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

create extension if not exists pgcrypto with schema extensions;
create extension if not exists pg_cron with schema extensions;

do $$
begin
  if not exists (
    select 1
    from information_schema.tables
    where table_schema = 'auth' and table_name = 'users'
  ) then
    execute $sql$
      create schema if not exists auth;
      create table auth.users (
        id uuid primary key default gen_random_uuid(),
        created_at timestamptz not null default now()
      );
    $sql$;
  end if;
exception
  when insufficient_privilege then
    raise notice 'auth.users already managed by Supabase image; skipping stub';
end
$$;

do $$
begin
  create or replace function auth.uid()
  returns uuid
  language sql
  stable
  as $fn$
    select null::uuid;
  $fn$;
exception
  when insufficient_privilege then
    raise notice 'auth.uid() not replaced (Supabase image); using existing definition';
end
$$;

alter database postgres set search_path to public;
set search_path to public;