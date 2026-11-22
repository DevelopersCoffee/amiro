-- Repair (#93): Supabase hosts pgcrypto in schema extensions; idempotent qualification and revokes.

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

revoke all on function public._web_share_new_token() from public;
revoke execute on function public._web_share_new_token() from anon, authenticated;

