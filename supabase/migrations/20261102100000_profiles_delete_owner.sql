-- Let the profile owner delete their cloud backup row (revoke consent).

grant delete on public.profiles to authenticated;

create policy profiles_delete_owner
  on public.profiles for delete
  to authenticated
  using (owner_id = (select auth.uid()));
