import assert from 'node:assert/strict';
import test from 'node:test';
import worker from '../src/index.ts';
import { hmacSha256Hex } from '../src/security.ts';

const baseEnv = {
  WEBHOOK_PATH_TOKEN: 'path-token',
  WEBHOOK_AUTHORIZATION: 'Bearer webhook-secret',
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-key',
};

function webhookRequest(pathToken, init = {}) {
  const url = `https://example.com/webhook/${pathToken}`;
  return new Request(url, {
    method: 'POST',
    headers: {
      Authorization: 'Bearer webhook-secret',
      ...init.headers,
    },
    body: init.body ?? '{}',
  });
}

test('fetch rejects webhook when WEBHOOK_PATH_TOKEN is unset', async () => {
  let upstream = 0;
  const env = {
    ...baseEnv,
    WEBHOOK_PATH_TOKEN: '',
    fetch: async () => {
      upstream += 1;
      return new Response('ok');
    },
  };
  const response = await worker.fetch(webhookRequest(''), env);
  assert.equal(response.status, 500);
  assert.equal(upstream, 0);
});

test('fetch rejects webhook when neither auth secret is configured', async () => {
  let upstream = 0;
  const env = {
    WEBHOOK_PATH_TOKEN: 'path-token',
    SUPABASE_URL: baseEnv.SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY: baseEnv.SUPABASE_SERVICE_ROLE_KEY,
    fetch: async () => {
      upstream += 1;
      return new Response('ok');
    },
  };
  const response = await worker.fetch(webhookRequest('path-token'), env);
  assert.equal(response.status, 500);
  assert.equal(upstream, 0);
});

test('fetch accepts valid Authorization and does not call upstream without event', async () => {
  let upstream = 0;
  const env = {
    ...baseEnv,
    fetch: async () => {
      upstream += 1;
      return new Response('ok');
    },
  };
  const response = await worker.fetch(
    webhookRequest('path-token', { body: '{"event":{}}' }),
    env,
  );
  assert.equal(response.status, 400);
  assert.equal(upstream, 0);
});

test('fetch rejects stale RevenueCat signature within handler', async () => {
  const secret = 'signing-secret';
  const body = '{"event":{"id":"1","type":"TEST","app_user_id":"u1"}}';
  const timestamp = '1';
  const signature = await hmacSha256Hex(secret, `${timestamp}.${body}`);
  const header = `t=${timestamp},v1=${signature}`;
  let upstream = 0;
  const env = {
    WEBHOOK_PATH_TOKEN: 'path-token',
    WEBHOOK_SIGNING_SECRET: secret,
    SUPABASE_URL: baseEnv.SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY: baseEnv.SUPABASE_SERVICE_ROLE_KEY,
    fetch: async () => {
      upstream += 1;
      return new Response('ok');
    },
  };
  const response = await worker.fetch(
    webhookRequest('path-token', {
      headers: { 'X-RevenueCat-Webhook-Signature': header },
      body,
    }),
    env,
  );
  assert.equal(response.status, 401);
  assert.equal(upstream, 0);
});

test('fetch rejects missing RevenueCat signature when signing secret set', async () => {
  let upstream = 0;
  const env = {
    WEBHOOK_PATH_TOKEN: 'path-token',
    WEBHOOK_SIGNING_SECRET: 'signing-secret',
    SUPABASE_URL: baseEnv.SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY: baseEnv.SUPABASE_SERVICE_ROLE_KEY,
    fetch: async () => {
      upstream += 1;
      return new Response('ok');
    },
  };
  const response = await worker.fetch(
    webhookRequest('path-token', {
      body: '{"event":{"id":"1","type":"TEST","app_user_id":"u1"}}',
    }),
    env,
  );
  assert.equal(response.status, 401);
  assert.equal(upstream, 0);
});

test('/crash returns 404 when CRASH_PATH_TOKEN is unset', async () => {
  let upstream = 0;
  const env = {
    ...baseEnv,
    CRASH_PATH_TOKEN: undefined,
    fetch: async () => {
      upstream += 1;
      return new Response('ok');
    },
  };
  const response = await worker.fetch(
    new Request('https://example.com/crash/anything', {
      method: 'POST',
      body: JSON.stringify({ message: 'x', appVersion: '1' }),
    }),
    env,
  );
  assert.equal(response.status, 404);
  assert.equal(upstream, 0);
});

test('W7b: handler accepts BOM-prefixed body signed over raw bytes', async () => {
  const secret = 'signing-secret';
  const json = '{"event":{"id":"1","type":"TEST","app_user_id":"u1"}}';
  const bodyText = `\uFEFF${json}`;
  const rawBodyBytes = new TextEncoder().encode(bodyText);
  const timestamp = String(Math.floor(Date.now() / 1000));
  const prefix = new TextEncoder().encode(`${timestamp}.`);
  const message = new Uint8Array(prefix.length + rawBodyBytes.length);
  message.set(prefix);
  message.set(rawBodyBytes, prefix.length);
  const signature = await hmacSha256Hex(secret, message);
  const header = `t=${timestamp},v1=${signature}`;
  let upstream = 0;
  const env = {
    WEBHOOK_PATH_TOKEN: 'path-token',
    WEBHOOK_SIGNING_SECRET: secret,
    SUPABASE_URL: baseEnv.SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY: baseEnv.SUPABASE_SERVICE_ROLE_KEY,
  };
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => {
    assert.match(String(url), /revenuecat_events/);
    upstream += 1;
    return new Response('[]', { status: 201 });
  };
  try {
    const response = await worker.fetch(
      webhookRequest('path-token', {
        headers: { 'X-RevenueCat-Webhook-Signature': header },
        body: bodyText,
      }),
      env,
    );
    assert.equal(response.status, 200);
    assert.ok(upstream >= 1);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test('constantTimeEqual(undefined) does not match empty path token', async () => {
  const { constantTimeEqual } = await import('../src/security.ts');
  assert.equal(constantTimeEqual('', undefined), false);
});
