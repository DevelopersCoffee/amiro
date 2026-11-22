#!/usr/bin/env bash
# Apply the pgcrypto repair migration on a Supabase-shaped DB and assert qualified gen_random_bytes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPAIR="${ROOT}/supabase/migrations/20261122130000_web_share_pgcrypto_extensions.sql"

: "${DATABASE_URL:?DATABASE_URL must be set}"

psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${ROOT}/scripts/ci/supabase_like_bootstrap.sql"
psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${REPAIR}"

def="$(psql "${DATABASE_URL}" -tAc \
  "select pg_get_functiondef(p.oid)
   from pg_proc p
   join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = '_web_share_new_token'")"

if [[ -z "${def}" ]]; then
  echo "ERROR: public._web_share_new_token was not created" >&2
  exit 1
fi

if ! grep -q 'extensions\.gen_random_bytes' <<<"${def}"; then
  echo "ERROR: _web_share_new_token must call extensions.gen_random_bytes" >&2
  echo "--- pg_get_functiondef ---" >&2
  echo "${def}" >&2
  exit 1
fi

token="$(psql "${DATABASE_URL}" -tAc "select public._web_share_new_token()")"
token="${token//[[:space:]]/}"
if [[ ${#token} -lt 22 ]]; then
  echo "ERROR: _web_share_new_token() returned too-short token: '${token}'" >&2
  exit 1
fi

if grep -qE '[+/=]' <<<"${token}"; then
  echo "ERROR: token must be base64url (no +, /, or =): '${token}'" >&2
  exit 1
fi

echo "OK: _web_share_new_token uses extensions.gen_random_bytes and mints base64url tokens."