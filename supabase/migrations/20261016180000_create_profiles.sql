-- The profile the person fills in on Identity. Written by the app with the
-- signed-in user's token (anonymous sign-in). The service role is not in
-- the app.
--
-- Purchased avatar items are not unlocked from this table. Play receipts
-- stay with RevenueCat, and `entitlement_grants` is the server copy of
-- those events. `revenuecat_app_user_id` is recorded so a profile and a
-- purchase can be matched later. Another phone gets the items back with
-- Store → Restore purchases on the same Google account. It gets this
-- profile back by calling `join_profile` with the recovery code.

create table public.profiles (
  identity_id text primary key,
  owner_id uuid not null references auth.users (id) on delete cascade,
  payload jsonb not null,
  revenuecat_app_user_id text,
  recovery_code text not null unique,
  updated_at timestamptz not null default now()
);

create table public.profile_members (
  identity_id text not null references public.profiles (identity_id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  primary key (identity_id, user_id)
);

alter table public.profiles enable row level security;
alter table public.profile_members enable row level security;

revoke all on public.profiles from anon, authenticated;
revoke all on public.profile_members from anon, authenticated;

-- `recovery_code` is not selectable. Claiming goes through `join_profile`.
grant select (identity_id, payload, revenuecat_app_user_id, updated_at)
  on public.profiles to authenticated;
grant insert (identity_id, owner_id, payload, revenuecat_app_user_id, recovery_code)
  on public.profiles to authenticated;
grant update (payload, revenuecat_app_user_id, updated_at)
  on public.profiles to authenticated;

grant select on public.profile_members to authenticated;
grant insert (identity_id, user_id) on public.profile_members to authenticated;

create policy profiles_select_member
  on public.profiles for select
  to authenticated
  using (
    exists (
      select 1 from public.profile_members m
      where m.identity_id = profiles.identity_id
        and m.user_id = auth.uid()
    )
  );

create policy profiles_insert_owner
  on public.profiles for insert
  to authenticated
  with check (owner_id = auth.uid());

create policy profiles_update_member
  on public.profiles for update
  to authenticated
  using (
    exists (
      select 1 from public.profile_members m
      where m.identity_id = profiles.identity_id
        and m.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.profile_members m
      where m.identity_id = profiles.identity_id
        and m.user_id = auth.uid()
    )
  );

create policy members_select_self
  on public.profile_members for select
  to authenticated
  using (user_id = auth.uid());

create policy members_insert_owner
  on public.profile_members for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.profiles p
      where p.identity_id = profile_members.identity_id
        and p.owner_id = auth.uid()
    )
  );

create or replace function public.join_profile(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  found_id text;
  found_payload jsonb;
begin
  if p_code is null or char_length(btrim(p_code)) < 16 then
    return null;
  end if;

  select identity_id, payload
    into found_id, found_payload
  from public.profiles
  where recovery_code = btrim(p_code);

  if found_id is null then
    return null;
  end if;

  insert into public.profile_members (identity_id, user_id)
  values (found_id, auth.uid())
  on conflict do nothing;

  return found_payload;
end;
$$;

revoke all on function public.join_profile(text) from public;
grant execute on function public.join_profile(text) to authenticated;
