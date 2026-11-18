-- Post-merge hardening (#80 / Security & Trust).

drop index if exists public.web_share_profiles_identity_unique;

create unique index if not exists web_share_profiles_owner_unique
  on public.web_share_profiles (owner_id);

alter table public.web_share_profiles
  drop constraint if exists web_share_token_format;

alter table public.web_share_profiles
  add constraint web_share_token_format check (
    char_length(token) >= 22 and char_length(token) <= 64
  );

alter table public.web_share_profiles
  drop constraint if exists web_share_display_name_len;

alter table public.web_share_profiles
  add constraint web_share_display_name_len check (
    char_length(display_name) <= 256
  );

alter table public.web_share_profiles
  drop constraint if exists web_share_public_contact_size;

alter table public.web_share_profiles
  add constraint web_share_public_contact_size check (
    pg_column_size(public_contact) <= 4096
  );

alter table public.web_share_profiles
  drop constraint if exists web_share_card_extras_size;

alter table public.web_share_profiles
  add constraint web_share_card_extras_size check (
    pg_column_size(card_extras) <= 8192
  );

alter table public.web_share_profiles
  drop constraint if exists web_share_avatar_size;

alter table public.web_share_profiles
  add constraint web_share_avatar_size check (
    pg_column_size(avatar_png) <= 524288
  );

-- Tombstone rows after revoke may clear avatar bytes.
alter table public.web_share_profiles
  alter column avatar_png drop not null;

alter table public.web_share_profiles
  drop constraint if exists web_share_avatar_required_when_active;

alter table public.web_share_profiles
  add constraint web_share_avatar_required_when_active check (
    revoked_at is not null
    or (avatar_png is not null and octet_length(avatar_png) > 0)
  );