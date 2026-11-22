import assert from 'node:assert/strict';
import test from 'node:test';

import { handleAnalytics } from '../src/analytics_handler.ts';

const rateLimiter = {
  limit: async () => ({ success: true }),
};

const baseEnv = {
  WEBHOOK_PATH_TOKEN: 'path-token',
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-key',
  ANALYTICS_PATH_TOKEN: 'analytics-token',
  ANALYTICS_RATE_LIMITER: rateLimiter,
};

function validEvent(name, extra = {}) {
  return {
    event: name,
    event_day: '2026-11-18',
    app_version: '1.0.6+12',
    platform: 'android',
    install_id: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
    ...extra,
  };
}

function analyticsRequest(body, init = {}) {
  return new Request('https://example.com/analytics/analytics-token', {
    method: 'POST',
    body: typeof body === 'string' ? body : JSON.stringify(body),
    ...init,
  });
}

test('handleAnalytics rejects oversized body with 413', async () => {
  const big = 'x'.repeat(9000);
  const response = await handleAnalytics(
    analyticsRequest({ events: [validEvent('setup_complete', { note: big })] }),
    baseEnv,
    new URL('https://example.com/analytics/analytics-token'),
  );
  assert.equal(response.status, 413);
});

test('handleAnalytics returns 413 when streamed body exceeds cap', async () => {
  const big = 'x'.repeat(20_000);
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(new TextEncoder().encode(big));
      controller.close();
    },
  });
  const response = await handleAnalytics(
    new Request('https://example.com/analytics/analytics-token', {
      method: 'POST',
      body: stream,
      duplex: 'half',
    }),
    baseEnv,
    new URL('https://example.com/analytics/analytics-token'),
  );
  assert.equal(response.status, 413);
});

test('handleAnalytics rejects unknown event name with 400', async () => {
  const response = await handleAnalytics(
    analyticsRequest({ events: [validEvent('mystery_event')] }),
    baseEnv,
    new URL('https://example.com/analytics/analytics-token'),
  );
  assert.equal(response.status, 400);
});

test('handleAnalytics rejects non-UUID install_id with 400', async () => {
  const response = await handleAnalytics(
    analyticsRequest({
      events: [validEvent('setup_complete', { install_id: 'not-a-uuid' })],
    }),
    baseEnv,
    new URL('https://example.com/analytics/analytics-token'),
  );
  assert.equal(response.status, 400);
  assert.equal(await response.text(), 'Invalid install_id');
});

test('handleAnalytics returns generic 502 when Supabase fails', async () => {
  const env = { ...baseEnv };
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response('secret detail', { status: 500 });
  try {
    const response = await handleAnalytics(
      analyticsRequest({ events: [validEvent('setup_complete')] }),
      env,
      new URL('https://example.com/analytics/analytics-token'),
    );
    assert.equal(response.status, 502);
    assert.equal(await response.text(), 'Ingest unavailable');
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('handleAnalytics returns 503 when rate limiter binding is missing', async () => {
  const env = { ...baseEnv };
  delete env.ANALYTICS_RATE_LIMITER;
  const response = await handleAnalytics(
    analyticsRequest({ events: [validEvent('setup_complete')] }),
    env,
    new URL('https://example.com/analytics/analytics-token'),
  );
  assert.equal(response.status, 503);
  assert.equal(await response.text(), 'Ingest unavailable');
});

test('handleAnalytics strips extra fields before Supabase insert', async () => {
  let body;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (_url, init) => {
    body = JSON.parse(init.body);
    return new Response('ok', { status: 201 });
  };
  try {
    const response = await handleAnalytics(
      analyticsRequest({
        events: [
          validEvent('paywall_shown', {
            surface: 'store_tab',
            email: 'dev@test.com',
          }),
        ],
      }),
      baseEnv,
      new URL('https://example.com/analytics/analytics-token'),
    );
    assert.equal(response.status, 200);
    assert.equal(body.length, 1);
    assert.equal(body[0].surface, 'store_tab');
    assert.equal(body[0].email, undefined);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('handleAnalytics DELETE revokes by install_id', async () => {
  let deleteUrl;
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    deleteUrl = url;
    assert.equal(init.method, 'DELETE');
    return new Response('ok', { status: 200 });
  };
  try {
    const response = await handleAnalytics(
      new Request('https://example.com/analytics/analytics-token', {
        method: 'DELETE',
        body: JSON.stringify({
          install_id: 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
        }),
      }),
      baseEnv,
      new URL('https://example.com/analytics/analytics-token'),
    );
    assert.equal(response.status, 200);
    assert.ok(String(deleteUrl).includes('install_id=eq.aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee'));
  } finally {
    globalThis.fetch = originalFetch;
  }
});