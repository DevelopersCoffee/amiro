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
  assert.equal(constantTimeEqual('', undefined), false);
  assert.equal(constantTimeEqual(undefined, ''), false);
  assert.equal(constantTimeEqual('a', 'aa'), false);
});

test('verifyRevenueCatWebhookSignature accepts valid HMAC', async () => {
  const body = '{"event":{"id":"1"}}';
  const secret = 'test-signing-secret';
  const timestamp = '1700000000';
  const signature = await hmacSha256Hex(secret, `${timestamp}.${body}`);
  const header = `t=${timestamp},v1=${signature}`;

  const ok = await verifyRevenueCatWebhookSignature(
    header,
    new TextEncoder().encode(body),
    secret,
    999999999,
  );
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
    new TextEncoder().encode('{"event":{"id":"2"}}'),
    secret,
    999999999,
  );
  assert.equal(ok, false);
});

test('verifyRevenueCatWebhookSignature rejects timestamps outside skew window', async () => {
  const body = '{"event":{"id":"1"}}';
  const secret = 'test-signing-secret';
  const timestamp = '1700000000';
  const signature = await hmacSha256Hex(secret, `${timestamp}.${body}`);
  const header = `t=${timestamp},v1=${signature}`;

  const ok = await verifyRevenueCatWebhookSignature(
    header,
    new TextEncoder().encode(body),
    secret,
    300,
  );
  assert.equal(ok, false);
});

test('parseRevenueCatSignature reads timestamp and v1', () => {
  const parsed = parseRevenueCatSignature('t=123,v1=abc');
  assert.deepEqual(parsed, { timestamp: '123', signature: 'abc' });
});

test('W11: rejects signature that only matches expected as a hex prefix', async () => {
  const body = '{"event":{"id":"1"}}';
  const secret = 'test-signing-secret';
  const timestamp = String(Math.floor(Date.now() / 1000));
  const expected = await hmacSha256Hex(secret, `${timestamp}.${body}`);
  const prefixOnly = expected.slice(0, 16);
  assert.notEqual(prefixOnly.length, expected.length);
  const header = `t=${timestamp},v1=${prefixOnly}`;

  const ok = await verifyRevenueCatWebhookSignature(
    header,
    new TextEncoder().encode(body),
    secret,
    300,
  );
  assert.equal(ok, false);
});

test('W11: rejects signature with valid prefix plus extra suffix bytes', async () => {
  const body = '{"event":{"id":"1"}}';
  const secret = 'test-signing-secret';
  const timestamp = String(Math.floor(Date.now() / 1000));
  const expected = await hmacSha256Hex(secret, `${timestamp}.${body}`);
  const header = `t=${timestamp},v1=${expected}00`;

  const ok = await verifyRevenueCatWebhookSignature(
    header,
    new TextEncoder().encode(body),
    secret,
    300,
  );
  assert.equal(ok, false);
});
