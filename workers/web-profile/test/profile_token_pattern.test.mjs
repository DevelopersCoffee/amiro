import assert from 'node:assert/strict';
import test from 'node:test';
import { parseTokenFromPath, tokenPattern } from '../src/profile.ts';

test('tokenPattern accepts base64url samples with - and _', () => {
  const samples = [
    'abcdefghijklmnopqrstuvwxy',
    'AbCdEfGhIjKlMnOpQrStUv',
    '______________----------',
    'mixed-_-_-_-_-_-_-_-_-x',
  ];
  for (const token of samples) {
    assert.match(token, tokenPattern, `expected ${token} to match`);
    assert.equal(parseTokenFromPath(`/u/${token}`), token);
  }
});

test('tokenPattern rejects padding and standard base64 specials', () => {
  assert.doesNotMatch('abcdefghijklmnopqrstuv==', tokenPattern);
  assert.doesNotMatch('abcd+efgh/ijklmnopqrst', tokenPattern);
  assert.equal(parseTokenFromPath('/u/abcd+efgh/ijklmnopqrstuvwx'), null);
});

test('tokenPattern rejects tokens shorter than 22 chars', () => {
  assert.doesNotMatch('tooshorttoken', tokenPattern);
  assert.equal(parseTokenFromPath('/u/tooshort'), null);
});