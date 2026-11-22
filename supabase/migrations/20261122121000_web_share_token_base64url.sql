-- Base64url token mint (strip padding; #81 S&T) and active profile cap per owner.

create or replace function public._web_share_new_token()
returns text
language sql
volatile
set search_path = public
as $$
  select rtrim(
    translate(encode(extensions.gen_random_bytes(16), 'base64'), '+/', '-_'),
    '='
  );
$$;

create or replace function public.web_share_publish(
  p_identity_id text,
  p_display_name text,
  p_public_contact jsonb,
  p_card_extras jsonb,
  p_avatar_png bytea
)
returns public.web_share_profiles
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_owner uuid := auth.uid();
  v_row public.web_share_profiles;
  v_token text;
  v_active_count int;
  v_max_active constant int := 5;
begin
  if v_owner is null then
    raise exception 'unauthenticated';
  end if;
  if char_length(btrim(p_identity_id)) = 0 then
    raise exception 'identity_id required';
  end if;
  if char_length(p_display_name) > 256 then
    raise exception 'display_name too long';
  end if;
  if pg_column_size(p_public_contact) > 4096
    or pg_column_size(p_card_extras) > 8192
    or octet_length(p_avatar_png) > 524288 then
    raise exception 'payload too large';
  end if;

  select *
    into v_row
  from public.web_share_profiles
  where owner_id = v_owner
    and identity_id = p_identity_id
    and revoked_at is null
  limit 1
  for update;

  if found then
    update public.web_share_profiles
      set display_name = p_display_name,
          public_contact = p_public_contact,
          card_extras = p_card_extras,
          avatar_png = p_avatar_png,
          updated_at = now()
    where token = v_row.token
    returning * into v_row;
    return v_row;
  end if;

  select count(*)::int
    into v_active_count
  from public.web_share_profiles
  where owner_id = v_owner
    and revoked_at is null;

  if v_active_count >= v_max_active then
    raise exception 'active web profile limit (%) reached', v_max_active;
  end if;

  v_token := public._web_share_new_token();
  insert into public.web_share_profiles (
    token,
    owner_id,
    identity_id,
    display_name,
    public_contact,
    card_extras,
    avatar_png
  )
  values (
    v_token,
    v_owner,
    p_identity_id,
    p_display_name,
    p_public_contact,
    p_card_extras,
    p_avatar_png
  )
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public._web_share_new_token() from public;
revoke execute on function public._web_share_new_token() from anon, authenticated;
