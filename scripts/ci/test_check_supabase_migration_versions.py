#!/usr/bin/env python3
"""Unit tests for migration version prefix audit."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from check_supabase_migration_versions import audit_migrations_dir, scan_migrations_dir


class TestCheckSupabaseMigrationVersions(unittest.TestCase):
    def test_unique_versions_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "20260101000000_first.sql").write_text("-- one\n")
            (root / "20260102000000_second.sql").write_text("-- two\n")
            by_version, invalid = scan_migrations_dir(root)
            self.assertEqual(invalid, [])
            self.assertEqual(len(by_version), 2)
            self.assertEqual(audit_migrations_dir(root), 0)

    def test_collision_detected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "20261118140000_create_analytics_events.sql").write_text("-- a\n")
            (root / "20261118140000_web_share_security_hardening.sql").write_text("-- b\n")
            (root / "20261122120000_solo.sql").write_text("-- c\n")
            by_version, invalid = scan_migrations_dir(root)
            self.assertEqual(invalid, [])
            self.assertEqual(len(by_version["20261118140000"]), 2)
            self.assertEqual(audit_migrations_dir(root), 1)

    def test_invalid_filename_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "not_a_version.sql").write_text("-- x\n")
            self.assertEqual(audit_migrations_dir(root), 2)


if __name__ == "__main__":
    unittest.main()
