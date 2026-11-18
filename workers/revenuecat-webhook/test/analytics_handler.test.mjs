import assert from 'node:assert/strict';
import test from 'node:test';

import { handleAnalytics } from '../src/analytics_handler.ts';

const baseEnv = {
  WEBHOOK_PATH_TOKEN: 'path-token',
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-key',
  ANALYTICS_PATH_TOKEN: 'analytics-token',
};

function validEvent(name, extra = {}) {
  return {
    event: name,
    event_day: '2026-11-18',
    app_version: '1.0.6+12',
    platform: 'android',
    install_id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    ...extra,
  };
}

test('handleAnalytics rejects oversized body with 413', async () => {
  const big = 'x'.repeat(9000);
  const response = await handleAnalytics(
    new Request('https://example.com/analytics/analytics-token', {
      method: 'POST',
      body: JSON.stringify({ events: [validEvent('setup_complete', { note: big })] }),
    }),
    baseEnv,
    new URL('https://example.com/analytics/analytics-token'),
  );
  assert.equal(response.status, 413);
});

test('handleAnalytics rejects unknown event name with 400', async () => {
  const response = await handleAnalytics(
    new Request('https://example.com/analytics/analytics-token', {
      method: 'POST',
      body: JSON.stringify({
        events: [validEvent('mystery_event')],
      }),
    }),
    baseEnv,
    new URL('https://example.com/analytics/analytics-token'),
  );
  assert.equal(response.status, 400);
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
      new Request('https://example.com/analytics/analytics-token', {
        method: 'POST',
        body: JSON.stringify({
          events: [
            validEvent('paywall_shown', {
              surface: 'store_tab',
              email: 'dev@test.com',
            }),
          ],
        }),
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