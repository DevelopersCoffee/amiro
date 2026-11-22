#!/usr/bin/env bash
# Apply all supabase/migrations in filename order, mimicking supabase db push version tracking.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATIONS_DIR="${ROOT}/supabase/migrations"

: "${DATABASE_URL:?DATABASE_URL must be set (e.g. postgresql://postgres:postgres@localhost:5432/postgres)}"

psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${ROOT}/scripts/ci/supabase_like_bootstrap.sql"

shopt -s nullglob
files=("${MIGRATIONS_DIR}"/*.sql)
IFS=$'\n' files=($(sort <<<"${files[*]}"))
unset IFS

apply_one() {
  local file="$1"
  local base version name
  base="$(basename "${file}")"
  if [[ ! "${base}" =~ ^([0-9]{14})_(.+)\.sql$ ]]; then
    echo "ERROR: migration filename must match YYYYMMDDHHMMSS_name.sql: ${base}" >&2
    return 2
  fi
  version="${BASH_REMATCH[1]}"
  name="${BASH_REMATCH[2]}"

  local existing
  existing="$(psql "${DATABASE_URL}" -tAc \
    "select 1 from supabase_migrations.schema_migrations where version = '${version}' limit 1" \
    || true)"
  if [[ "${existing}" == "1" ]]; then
    echo "" >&2
    echo "ERROR: duplicate migration version '${version}' (schema_migrations_pkey)." >&2
    echo "  Already recorded; refusing to apply: ${base}" >&2
    echo "  Earlier file(s) with same prefix:" >&2
    psql "${DATABASE_URL}" -tAc \
      "select name from supabase_migrations.schema_migrations where version = '${version}'" \
      | sed 's/^/    /' >&2
    echo "  Owner must rename the later-merged sibling or add a repair migration." >&2
    return 1
  fi

  echo "Applying ${base} ..."
  if ! err="$(psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${file}" 2>&1)"; then
    echo "" >&2
    echo "ERROR: migration failed: ${base}" >&2
    if grep -qi 'gen_random_bytes' <<<"${err}"; then
      echo "" >&2
      echo "Likely cause: gen_random_bytes is in schema extensions but search_path" >&2
      echo "is public-only (Supabase default). Qualify as extensions.gen_random_bytes" >&2
      echo "or SET search_path = public, extensions on the function." >&2
      echo "Repair migration 20261122130000_web_share_pgcrypto_extensions.sql addresses _web_share_new_token." >&2
    fi
    echo "--- psql output ---" >&2
    echo "${err}" >&2
    return 1
  fi

  psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -c \
    "insert into supabase_migrations.schema_migrations (version, name) values ('${version}', '${name}')"
}

for f in "${files[@]}"; do
  apply_one "${f}"
done

echo "OK: all migrations applied (${#files[@]} files)."