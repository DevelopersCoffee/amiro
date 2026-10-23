-- The owner is not a member yet when they insert the membership row, so a
-- select policy that only allows members hides the profile from the check
-- that proves they own it.

drop policy profiles_select_member on public.profiles;
create policy profiles_select_member
  on public.profiles for select
  to authenticated
  using (
    owner_id = (select auth.uid())
    or exists (
      select 1 from public.profile_members m
      where m.identity_id = profiles.identity_id
        and m.user_id = (select auth.uid())
    )
  );

drop policy profiles_update_member on public.profiles;
create policy profiles_update_member
  on public.profiles for update
  to authenticated
  using (
    owner_id = (select auth.uid())
    or exists (
      select 1 from public.profile_members m
      where m.identity_id = profiles.identity_id
        and m.user_id = (select auth.uid())
    )
  )
  with check (
    owner_id = (select auth.uid())
    or exists (
      select 1 from public.profile_members m
      where m.identity_id = profiles.identity_id
        and m.user_id = (select auth.uid())
    )
  );
