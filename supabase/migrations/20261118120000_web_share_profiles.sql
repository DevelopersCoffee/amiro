-- Opt-in public web profiles resolved by unguessable token (issue #55).
-- Recipients fetch HTML from the Cloudflare Worker using the service role;
-- anon has no direct read access.

create table public.web_share_profiles (
  token text primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  identity_id text not null,
  display_name text not null,
  public_contact jsonb not null default '{}'::jsonb,
  card_extras jsonb not null default '{}'::jsonb,
  avatar_png bytea not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint web_share_token_format check (
    char_length(token) >= 16 and char_length(token) <= 64
  )
);

create index web_share_profiles_owner_idx
  on public.web_share_profiles (owner_id);

create index web_share_profiles_identity_idx
  on public.web_share_profiles (identity_id);

create unique index web_share_profiles_identity_unique
  on public.web_share_profiles (identity_id);

alter table public.web_share_profiles enable row level security;

revoke all on public.web_share_profiles from anon, authenticated;

grant select, insert, update, delete on public.web_share_profiles to authenticated;

create policy web_share_select_owner
  on public.web_share_profiles for select
  to authenticated
  using (owner_id = auth.uid());

create policy web_share_insert_owner
  on public.web_share_profiles for insert
  to authenticated
  with check (owner_id = auth.uid());

create policy web_share_update_owner
  on public.web_share_profiles for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy web_share_delete_owner
  on public.web_share_profiles for delete
  to authenticated
  using (owner_id = auth.uid());