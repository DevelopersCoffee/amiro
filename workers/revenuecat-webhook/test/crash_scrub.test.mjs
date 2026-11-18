import assert from 'node:assert/strict';
import test from 'node:test';

import { redactCrashSecrets } from '../src/crash_allowlist.ts';

test('64 KB adversarial scrub finishes within 50ms', () => {
  const payload = '!'.repeat(64 * 1024);
  const start = performance.now();
  const out = redactCrashSecrets(payload);
  const elapsed = performance.now() - start;
  assert.equal(out.length, payload.length);
  assert.ok(elapsed < 50);
});