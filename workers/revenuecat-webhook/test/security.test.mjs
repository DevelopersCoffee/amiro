import assert from 'node:assert/strict';
import test from 'node:test';
import {
  constantTimeEqual,
  hmacSha256Hex,
  parseRevenueCatSignature,
  verifyRevenueCatWebhookSignature,
} from '../src/security.ts';

test('constantTimeEqual rejects unequal strings', () => {
  assert.equal(constantTimeEqual('abc', 'abd'), false);
  assert.equal(constantTimeEqual('abc', 'abc'), true);
});

test('verifyRevenueCatWebhookSignature accepts valid HMAC', async () => {
  const body = '{"event":{"id":"1"}}';
  const secret = 'test-signing-secret';
  const timestamp = '1700000000';
  const signature = await hmacSha256Hex(secret, `${timestamp}.${body}`);
  const header = `t=${timestamp},v1=${signature}`;

  const ok = await verifyRevenueCatWebhookSignature(header, body, secret, 999999999);
  assert.equal(ok, true);
});

test('verifyRevenueCatWebhookSignature rejects tampered body', async () => {
  const body = '{"event":{"id":"1"}}';
  const secret = 'test-signing-secret';
  const timestamp = '1700000000';
  const signature = await hmacSha256Hex(secret, `${timestamp}.${body}`);
  const header = `t=${timestamp},v1=${signature}`;

  const ok = await verifyRevenueCatWebhookSignature(
    header,
    '{"event":{"id":"2"}}',
    secret,
    999999999,
  );
  assert.equal(ok, false);
});

test('parseRevenueCatSignature reads timestamp and v1', () => {
  const parsed = parseRevenueCatSignature('t=123,v1=abc');
  assert.deepEqual(parsed, { timestamp: '123', signature: 'abc' });
});
