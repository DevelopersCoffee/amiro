#!/usr/bin/env python3
"""Fail if any two files under supabase/migrations/ share the same 14-digit version prefix."""

from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MIGRATIONS_DIR = ROOT / "supabase" / "migrations"
VERSION_PREFIX = re.compile(r"^(\d{14})_")


def main() -> int:
    if not MIGRATIONS_DIR.is_dir():
        print(f"ERROR: missing migrations directory: {MIGRATIONS_DIR}", file=sys.stderr)
        return 2

    by_version: dict[str, list[str]] = defaultdict(list)
    for path in sorted(MIGRATIONS_DIR.glob("*.sql")):
        match = VERSION_PREFIX.match(path.name)
        if not match:
            print(
                f"ERROR: migration filename must start with 14-digit version: {path.name}",
                file=sys.stderr,
            )
            return 2
        by_version[match.group(1)].append(path.name)

    collisions = {v: names for v, names in by_version.items() if len(names) > 1}
    if collisions:
        print(
            "ERROR: duplicate Supabase migration version prefixes "
            "(schema_migrations_pkey / supabase db push will abort):\n",
            file=sys.stderr,
        )
        for version in sorted(collisions):
            print(f"  version {version}:", file=sys.stderr)
            for name in sorted(collisions[version]):
                print(f"    - {name}", file=sys.stderr)
        print(
            "\nResolve by owner-approved rename of the later-merged sibling "
            "or a repair migration before re-running push.",
            file=sys.stderr,
        )
        return 1

    print(f"OK: {len(by_version)} unique migration version prefix(es) under supabase/migrations/")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())