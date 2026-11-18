import assert from 'node:assert/strict';
import test from 'node:test';

import { scrubCrashText } from '../src/crash_scrub.ts';

test('scrubCrashText redacts email, phone, query URLs, and paths', () => {
  const raw =
    'contact dev@test.com or +1 (555) 123-4567 ' +
    'at https://example.com/path?q=secret ' +
    'file:///data/user/0/com.amiro/app/crash ' +
    'C:\\Users\\alice\\secret.txt ' +
    'stack /home/alice/proj/lib/main.dart:42';
  const scrubbed = scrubCrashText(raw);

  assert.ok(!scrubbed.includes('dev@test.com'));
  assert.ok(scrubbed.includes('[redacted-email]'));
  assert.ok(!scrubbed.includes('555'));
  assert.ok(scrubbed.includes('[redacted-phone]'));
  assert.ok(!scrubbed.includes('q=secret'));
  assert.ok(scrubbed.includes('[redacted-url]'));
  assert.ok(!scrubbed.includes('/home/alice'));
  assert.ok(scrubbed.includes('[redacted-path]'));
  assert.ok(!scrubbed.includes('C:\\Users'));
});