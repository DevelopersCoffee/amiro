import assert from 'node:assert/strict';
import test from 'node:test';

import { handleCrash } from '../src/crash_handler.ts';

const rateLimiter = {
  limit: async () => ({ success: true }),
};

const baseEnv = {
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-key',
  CRASH_PATH_TOKEN: 'crash-token',
  CRASH_RATE_LIMITER: rateLimiter,
};

const validPayload = {
  runtimeType: 'StateError',
  message: 'StateError: hello',
  stack: '#0      main (package:amiro_app/main.dart:1:9)\n',
  appVersion: '1.0.6+12',
  source: 'flutter',
  platform: 'android',
};

function crashRequest(body, init = {}) {
  return new Request('https://example.com/crash/crash-token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...init.headers,
    },
    body: typeof body === 'string' ? body : JSON.stringify(body),
    ...init,
  });
}

test('handleCrash scrubs allowlisted payload before insert', async () => {
  let rows;
  const env = { ...baseEnv };
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (_url, init) => {
    rows = JSON.parse(init.body);
    return new Response('ok', { status: 201 });
  };
  try {
    const response = await handleCrash(
      crashRequest({
        ...validPayload,
        message:
          'StateError: token eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.sig',
      }),
      env,
      new URL('https://example.com/crash/crash-token'),
    );
    assert.equal(response.status, 200);
    assert.equal(rows.length, 1);
    assert.ok(rows[0].message.includes('[redacted-jwt]'));
    assert.ok(rows[0].stack.includes('package:amiro_app'));
    assert.equal(rows[0].occurred_at != null, true);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('handleCrash returns 415 for non-JSON content type', async () => {
  const response = await handleCrash(
    crashRequest('hello', {
      headers: { 'Content-Type': 'text/plain' },
    }),
    baseEnv,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 415);
});

test('handleCrash returns 400 for null JSON body', async () => {
  const response = await handleCrash(
    crashRequest('null'),
    baseEnv,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 400);
});

test('handleCrash returns 400 for non-string message', async () => {
  const response = await handleCrash(
    crashRequest({ message: 42, appVersion: '1.0.6+12', source: 'flutter' }),
    baseEnv,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 400);
});

test('handleCrash returns 413 when Content-Length exceeds cap', async () => {
  const response = await handleCrash(
    crashRequest(JSON.stringify(validPayload), {
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': '20000',
      },
    }),
    baseEnv,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 413);
});

test('handleCrash returns generic 502 when Supabase fails', async () => {
  const env = { ...baseEnv };
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response('secret detail', { status: 500 });
  try {
    const response = await handleCrash(
      crashRequest(validPayload),
      env,
      new URL('https://example.com/crash/crash-token'),
    );
    assert.equal(response.status, 502);
    assert.equal(await response.text(), 'Ingest unavailable');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('handleCrash rejects missing crash token', async () => {
  const response = await handleCrash(
    crashRequest(validPayload),
    baseEnv,
    new URL('https://example.com/crash/wrong'),
  );
  assert.equal(response.status, 404);
});

test('handleCrash returns 429 when rate limiter denies', async () => {
  const env = {
    ...baseEnv,
    CRASH_RATE_LIMITER: { limit: async () => ({ success: false }) },
  };
  const response = await handleCrash(
    crashRequest(validPayload),
    env,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 429);
  assert.equal(await response.text(), 'Too many requests');
});

test('handleCrash returns 413 when streamed body exceeds cap', async () => {
  const big = 'x'.repeat(20_000);
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(new TextEncoder().encode(big));
      controller.close();
    },
  });
  const response = await handleCrash(
    new Request('https://example.com/crash/crash-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: stream,
      duplex: 'half',
    }),
    baseEnv,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 413);
});

test('handleCrash rejects invalid appVersion source and platform', async () => {
  for (const body of [
    { ...validPayload, appVersion: 'not-a-version' },
    { ...validPayload, source: 'native' },
    { ...validPayload, platform: 'windows' },
  ]) {
    const response = await handleCrash(
      crashRequest(body),
      baseEnv,
      new URL('https://example.com/crash/crash-token'),
    );
    assert.equal(response.status, 400);
  }
});

test('handleCrash normalizes invalid runtimeType before insert', async () => {
  let rows;
  const env = { ...baseEnv };
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (_url, init) => {
    rows = JSON.parse(init.body);
    return new Response('ok', { status: 201 });
  };
  try {
    const response = await handleCrash(
      crashRequest({
        ...validPayload,
        runtimeType: 'Rahul Verma',
        message: 'Rahul Verma: controlled',
      }),
      env,
      new URL('https://example.com/crash/crash-token'),
    );
    assert.equal(response.status, 200);
    assert.equal(rows.length, 1);
    assert.ok(rows[0].message.startsWith('Error:'));
    assert.equal(rows[0].message.includes('Rahul Verma'), false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('handleCrash returns 503 when rate limiter binding is missing', async () => {
  const env = { ...baseEnv };
  delete env.CRASH_RATE_LIMITER;
  const response = await handleCrash(
    crashRequest(validPayload),
    env,
    new URL('https://example.com/crash/crash-token'),
  );
  assert.equal(response.status, 503);
  assert.equal(await response.text(), 'Ingest unavailable');
});