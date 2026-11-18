import assert from 'node:assert/strict';
import test from 'node:test';

import { handleCrash } from '../src/index.ts';

const baseEnv = {
  WEBHOOK_PATH_TOKEN: 'path-token',
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-key',
  CRASH_PATH_TOKEN: 'crash-token',
};

test('handleCrash scrubs and size-caps payload before Supabase insert', async () => {
  let body;
  const env = { ...baseEnv };
  const payload = {
    message: `dev@test.com ${'x'.repeat(3000)}`,
    stack: `/home/a.dart ${'y'.repeat(9000)}`,
    appVersion: '1.0.6+12',
    source: 'flutter',
  };
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (_url, init) => {
    assert.match(String(_url), /crash_reports/);
    body = JSON.parse(init.body);
    return new Response('ok', { status: 201 });
  };
  try {
    const response = await handleCrash(
      new Request('https://example.com/crash/crash-token', {
        method: 'POST',
        body: JSON.stringify(payload),
      }),
      env,
      new URL('https://example.com/crash/crash-token'),
    );

    assert.equal(response.status, 200);
    assert.equal(body.length, 1);
    assert.ok(!String(body[0].message).includes('dev@test.com'));
    assert.ok(body[0].message.includes('[redacted-email]'));
    assert.ok(body[0].message.length <= 2000);
    assert.ok(body[0].stack.length <= 8000);
    assert.ok(body[0].stack.includes('[redacted-path]'));
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('handleCrash rejects missing crash token', async () => {
  const response = await handleCrash(
    new Request('https://example.com/crash/wrong', {
      method: 'POST',
      body: JSON.stringify({ message: 'x', appVersion: '1' }),
    }),
    baseEnv,
    new URL('https://example.com/crash/wrong'),
  );
  assert.equal(response.status, 404);
});