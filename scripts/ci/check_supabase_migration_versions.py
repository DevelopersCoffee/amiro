#!/usr/bin/env python3
"""Fail if any two files under supabase/migrations/ share the same 14-digit version prefix."""

from __future__ import annotations

import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MIGRATIONS_DIR = ROOT / "supabase" / "migrations"
VERSION_PREFIX = re.compile(r"^(\d{14})_")


def scan_migrations_dir(migrations_dir: Path) -> tuple[dict[str, list[str]], list[str]]:
    """Group migration filenames by 14-digit prefix; return invalid filenames separately."""
    by_version: dict[str, list[str]] = defaultdict(list)
    invalid: list[str] = []
    for path in sorted(migrations_dir.glob("*.sql")):
        match = VERSION_PREFIX.match(path.name)
        if not match:
            invalid.append(path.name)
            continue
        by_version[match.group(1)].append(path.name)
    return dict(by_version), invalid


def audit_migrations_dir(migrations_dir: Path) -> int:
    if not migrations_dir.is_dir():
        print(f"ERROR: missing migrations directory: {migrations_dir}", file=sys.stderr)
        return 2

    by_version, invalid = scan_migrations_dir(migrations_dir)
    if invalid:
        for name in invalid:
            print(
                f"ERROR: migration filename must start with 14-digit version: {name}",
                file=sys.stderr,
            )
        return 2

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

    print(
        f"OK: {len(by_version)} unique migration version prefix(es) under {migrations_dir}/"
    )
    return 0


def main() -> int:
    return audit_migrations_dir(DEFAULT_MIGRATIONS_DIR)


if __name__ == "__main__":
    raise SystemExit(main())
