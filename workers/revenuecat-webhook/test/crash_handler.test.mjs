import assert from 'node:assert/strict';
import test from 'node:test';

import { handleCrash } from '../src/index.ts';

const baseEnv = {
  WEBHOOK_PATH_TOKEN: 'path-token',
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-key',
  CRASH_PATH_TOKEN: 'crash-token',
};

const validPayload = {
  exceptionType: 'StateError',
  message: 'widget failed',
  frames: ['#0 package:amiro_app/main.dart:10:5'],
  source: 'flutter',
  appVersion: '1.0.6+12',
  platform: 'android',
};

test('handleCrash accepts minimal upload and uses server time', async () => {
  let body;
  const env = { ...baseEnv };
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (_url, init) => {
    assert.match(String(_url), /crash_reports/);
    body = JSON.parse(init.body);
    return new Response('ok', { status: 201 });
  };
  try {
    const before = Date.now();
    const response = await handleCrash(
      new Request('https://example.com/crash/crash-token', {
        method: 'POST',
        body: JSON.stringify(validPayload),
      }),
      env,
      new URL('https://example.com/crash/crash-token'),
    );
    const after = Date.now();

    assert.equal(response.status, 200);
    assert.equal(body.length, 1);
    assert.match(body[0].message, /StateError/);
    assert.ok(body[0].stack.includes('package:amiro_app'));
    assert.ok(body[0].occurred_at);
    const received = Date.parse(body[0].occurred_at);
    assert.ok(received >= before - 1000 && received <= after + 1000);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('handleCrash rejects body over 16 KB', async () => {
  const huge = JSON.stringify({
    ...validPayload,
    message: 'x'.repeat(20_000),
  });
  const response = await handleCrash(
    new Request('https://example.com/crash/crash-token', {
      method: 'POST',
      body: huge,
    }),
    baseEnv,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 413);
});

test('handleCrash rejects disallowed source', async () => {
  const response = await handleCrash(
    new Request('https://example.com/crash/crash-token', {
      method: 'POST',
      body: JSON.stringify({ ...validPayload, source: 'evil' }),
    }),
    baseEnv,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 400);
});

test('handleCrash rejects missing crash token', async () => {
  const response = await handleCrash(
    new Request('https://example.com/crash/wrong', {
      method: 'POST',
      body: JSON.stringify(validPayload),
    }),
    baseEnv,
    new URL('https://example.com/crash/wrong'),
  );
  assert.equal(response.status, 404);
});