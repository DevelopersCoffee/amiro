import assert from 'node:assert/strict';
import test from 'node:test';
import { isValidPng, MAX_AVATAR_BYTES } from '../src/avatar_validate.ts';

test('isValidPng accepts minimal png and rejects garbage', () => {
  const png = new Uint8Array([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00,
  ]);
  assert.equal(isValidPng(png), true);
  assert.equal(isValidPng(new Uint8Array([1, 2, 3])), false);
  assert.equal(isValidPng(new Uint8Array(MAX_AVATAR_BYTES + 1)), false);
});