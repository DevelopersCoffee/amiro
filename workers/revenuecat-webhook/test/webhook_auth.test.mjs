import assert from 'node:assert/strict';
import test from 'node:test';
import { verifyWebhookRequest } from '../src/index.ts';

const env = {
  WEBHOOK_PATH_TOKEN: 'path-token',
  WEBHOOK_AUTHORIZATION: 'Bearer webhook-secret',
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'key',
};

test('verifyWebhookRequest rejects wrong Authorization header', async () => {
  const request = new Request('https://example.com/webhook/path-token', {
    method: 'POST',
    headers: { Authorization: 'Bearer wrong' },
    body: '{}',
  });
  const body = new TextEncoder().encode('{}');
  const response = await verifyWebhookRequest(request, env, 'path-token', body);
  assert.equal(response?.status, 401);
});

test('verifyWebhookRequest accepts matching Authorization header', async () => {
  const request = new Request('https://example.com/webhook/path-token', {
    method: 'POST',
    headers: { Authorization: 'Bearer webhook-secret' },
    body: '{}',
  });
  const body = new TextEncoder().encode('{}');
  const response = await verifyWebhookRequest(request, env, 'path-token', body);
  assert.equal(response, null);
});

test('verifyWebhookRequest rejects wrong path token in constant time', async () => {
  const request = new Request('https://example.com/webhook/wrong', {
    method: 'POST',
    headers: { Authorization: 'Bearer webhook-secret' },
    body: '{}',
  });
  const body = new TextEncoder().encode('{}');
  const response = await verifyWebhookRequest(request, env, 'wrong', body);
  assert.equal(response?.status, 404);
});

test('verifyWebhookRequest fails closed when path token env is missing', async () => {
  const request = new Request('https://example.com/webhook/', {
    method: 'POST',
    headers: { Authorization: 'Bearer webhook-secret' },
    body: '{}',
  });
  const body = new TextEncoder().encode('{}');
  const response = await verifyWebhookRequest(
    request,
    { ...env, WEBHOOK_PATH_TOKEN: '' },
    '',
    body,
  );
  assert.equal(response?.status, 500);
});

test('verifyWebhookRequest fails closed when no webhook secrets configured', async () => {
  const request = new Request('https://example.com/webhook/path-token', {
    method: 'POST',
    body: '{}',
  });
  const body = new TextEncoder().encode('{}');
  const response = await verifyWebhookRequest(
    request,
    {
      WEBHOOK_PATH_TOKEN: 'path-token',
      SUPABASE_URL: env.SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY: env.SUPABASE_SERVICE_ROLE_KEY,
    },
    'path-token',
    body,
  );
  assert.equal(response?.status, 500);
});
