#!/usr/bin/env node
/**
 * Re-runs the Principal Architect mutant list from review 5744469051.
 * Each mutant is a small sed patch; tests must fail when the patch is applied.
 */
import { execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');

const mutants = [
  {
    id: 'C1',
    file: 'app/lib/identity/supabase_profile_cloud.dart',
    from: "if (!supportsRestore || !await backupPreferences.isEnabled()) {",
    to: "if (!supportsRestore) {",
    cmd: 'cd app && flutter test test/identity/supabase_profile_cloud_http_test.dart',
  },
  {
    id: 'C2',
    file: 'app/lib/identity/identity_edit_screen.dart',
    from: 'final backupOn =\n        await ref.read(cloudBackupPreferencesProvider).isEnabled();\n    if (backupOn) {',
    to: 'if (true) {',
    cmd: 'cd app && flutter test test/identity/cloud_backup_consent_widget_test.dart --name autosave',
  },
  {
    id: 'W2',
    file: 'workers/revenuecat-webhook/src/security.ts',
    from: '  if (left.length !== right.length) {\n    return false;\n  }',
    to: '  // length check removed',
    cmd: 'cd workers/revenuecat-webhook && npm test',
  },
  {
    id: 'W4',
    file: 'workers/revenuecat-webhook/src/index.ts',
    from: '  if (env.WEBHOOK_SIGNING_SECRET) {',
    to: '  if (false && env.WEBHOOK_SIGNING_SECRET) {',
    cmd: 'cd workers/revenuecat-webhook && npm test -- --test-name-pattern="missing RevenueCat signature"',
  },
  {
    id: 'W8',
    file: 'workers/revenuecat-webhook/src/index.ts',
    from: '    if (authFailure) {\n      return authFailure;\n    }',
    to: '    // auth ignored',
    cmd: 'cd workers/revenuecat-webhook && npm test -- --test-name-pattern="WEBHOOK_PATH_TOKEN is unset"',
  },
];

function applyMutant(m) {
  const full = path.join(root, m.file);
  const original = fs.readFileSync(full, 'utf8');
  if (!original.includes(m.from)) {
    throw new Error(`${m.id}: pattern not found in ${m.file}`);
  }
  fs.writeFileSync(full, original.replace(m.from, m.to));
  return original;
}

function restore(fullPath, original) {
  fs.writeFileSync(fullPath, original);
}

const results = [];
for (const m of mutants) {
  const full = path.join(root, m.file);
  let original;
  try {
    original = applyMutant(m);
    let failed = false;
    try {
      execSync(m.cmd, { cwd: root, stdio: 'pipe' });
    } catch {
      failed = true;
    }
    results.push({ id: m.id, killed: failed });
  } finally {
    if (original) restore(full, original);
  }
}

console.log(JSON.stringify(results, null, 2));
