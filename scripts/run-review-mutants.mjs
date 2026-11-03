#!/usr/bin/env node
/**
 * Principal Architect mutant list (review 5744469051).
 * KILLED = tests fail when the mutant is applied.
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
    cmd: 'cd app && flutter test test/identity/supabase_profile_cloud_http_test.dart test/identity/cloud_backup_flow_test.dart --name "prefs disabled"',
  },
  {
    id: 'C2',
    file: 'app/lib/identity/identity_edit_screen.dart',
    from: '    final backupOn =\n        _cloudBackupEnabled ||\n        await ref.read(cloudBackupPreferencesProvider).isEnabled();\n    if (backupOn) {',
    to: '    if (true) {',
    cmd:
      'cd app && flutter test test/identity/identity_edit_cloud_push_gate_widget_test.dart',
  },
  {
    id: 'C3',
    file: 'app/lib/identity/supabase_profile_cloud.dart',
    from: "if (!supportsRestore || !await backupPreferences.isEnabled()) {",
    to: "if (true) {",
    cmd: 'cd app && flutter test test/identity/cloud_backup_flow_test.dart --name "prefs enabled"',
  },
  {
    id: 'C5',
    file: 'app/lib/identity/cloud_backup_preferences.dart',
    from: '    return false;',
    to: '    return true;',
    cmd: 'cd app && flutter test test/identity/cloud_backup_test.dart --name corrupt',
  },
  {
    id: 'C6',
    file: 'app/lib/identity/identity_edit_screen.dart',
    from: '    if (enabled && !_cloudBackupEnabled) {\n      final accepted = await confirmCloudBackupEnable(',
    to: '    if (false && enabled && !_cloudBackupEnabled) {\n      final accepted = await confirmCloudBackupEnable(',
    cmd: 'cd app && flutter test test/identity/cloud_backup_consent_widget_test.dart --name "C6"',
  },
  {
    id: 'C7',
    file: 'app/lib/identity/cloud_backup_enable.dart',
    from: '  return accepted == true;',
    to: '  return accepted != false;',
    cmd:
      'cd app && flutter test test/identity/cloud_backup_enable_test.dart test/identity/cloud_backup_consent_widget_test.dart --name "C7|C6: enable requires"',
  },
  {
    id: 'A2',
    file: 'app/lib/identity/profile_cloud.dart',
    from: "  for (final entry in identity.publicFields().entries) {",
    to: "  for (final entry in identity.toJson().entries) {",
    cmd: 'cd app && flutter test test/identity/profile_cloud_test.dart test/identity/supabase_profile_cloud_http_test.dart --name allowlist',
  },
  {
    id: 'R3',
    file: 'app/lib/app.dart',
    from: '  return StoreScreen(isActive: index == 2);',
    to: '  return StoreScreen(isActive: true);',
    cmd: 'cd app && flutter test test/app_launch_revenuecat_test.dart',
  },
  {
    id: 'S1',
    file: 'app/lib/sharing/encounter_share_options.dart',
    from: '    this.includeEquippedCosmetics = true,',
    to: '    this.includeEquippedCosmetics = false,',
    cmd:
      'cd app && flutter test test/sharing/own_encounter_test.dart --name "defaults include equipped"',
  },
  {
    id: 'S4',
    file: 'app/lib/sharing/encounter_share_options.dart',
    from: '    this.includeCollectionProgress = false,',
    to: '    this.includeCollectionProgress = true,',
    cmd: 'cd app && flutter test test/sharing/own_encounter_test.dart --name "defaults include equipped"',
  },
  {
    id: 'W2',
    file: 'workers/revenuecat-webhook/src/security.ts',
    from: '  if (left.length !== right.length) {\n    return false;\n  }',
    to: '  // length check removed',
    cmd: 'cd workers/revenuecat-webhook && npm test -- --test-name-pattern="constantTimeEqual"',
  },
  {
    id: 'W4',
    file: 'workers/revenuecat-webhook/src/index.ts',
    from: '  if (env.WEBHOOK_SIGNING_SECRET) {',
    to: '  if (false && env.WEBHOOK_SIGNING_SECRET) {',
    cmd: 'cd workers/revenuecat-webhook && npm test -- --test-name-pattern="missing RevenueCat signature"',
  },
  {
    id: 'W6',
    file: 'workers/revenuecat-webhook/src/security.ts',
    from: '  if (Math.abs(now - ts) > maxSkewSeconds) return false;',
    to: '  // skew check removed',
    cmd: 'cd workers/revenuecat-webhook && npm test -- --test-name-pattern="timestamps outside skew"',
  },
  {
    id: 'W8',
    file: 'workers/revenuecat-webhook/src/index.ts',
    from: '    if (authFailure) {\n      return authFailure;\n    }',
    to: '    // auth ignored',
    cmd: 'cd workers/revenuecat-webhook && npm test -- --test-name-pattern="WEBHOOK_PATH_TOKEN is unset"',
  },
  {
    id: 'W9',
    file: 'workers/revenuecat-webhook/src/index.ts',
    from: "  if (!env.CRASH_PATH_TOKEN || !constantTimeEqual(token, env.CRASH_PATH_TOKEN)) {",
    to: '  if (false) {',
    cmd: 'cd workers/revenuecat-webhook && npm test -- --test-name-pattern="CRASH_PATH_TOKEN is unset"',
  },
  {
    id: 'W11',
    file: 'workers/revenuecat-webhook/src/security.ts',
    from: '  return constantTimeEqual(expected, parsed.signature);',
    to: '  return parsed.signature.startsWith(expected.slice(0, 16));',
    cmd: 'cd workers/revenuecat-webhook && npm test -- --test-name-pattern="W11"',
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
    let killed = false;
    try {
      execSync(m.cmd, { cwd: root, stdio: 'pipe' });
    } catch {
      killed = true;
    }
    results.push({ id: m.id, killed });
  } catch (e) {
    results.push({ id: m.id, error: String(e) });
  } finally {
    if (original) restore(full, original);
  }
}

console.log(JSON.stringify(results, null, 2));
