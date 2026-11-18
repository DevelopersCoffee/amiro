import assert from 'node:assert/strict';
import test from 'node:test';

import { parseCrashUpload, scrubCrashMessage } from '../src/crash_scrub.ts';

test('scrubCrashMessage handles 80kb input in linear time', () => {
  const big = `dev@test.com ${'x'.repeat(80_000)}`;
  const start = performance.now();
  const out = scrubCrashMessage(big);
  const ms = performance.now() - start;
  assert.ok(ms < 200, `scrub took ${ms}ms`);
  assert.ok(!out.includes('dev@test.com'));
  assert.ok(out.includes('[redacted-email]'));
  assert.ok(out.length <= 500);
});

test('parseCrashUpload strips JWT and keeps package frames', () => {
  const upload = parseCrashUpload({
    exceptionType: 'FormatException',
    message: 'Bearer abc eyJhbGciOiJIUzI1NiJ9.x.y',
    frames: [
      'package:amiro_app/foo.dart:1:1',
      '/home/leak.dart:2:2',
    ],
    source: 'flutter',
    appVersion: '1.0.0',
    platform: 'android',
  });
  assert.ok(upload);
  assert.ok(!upload.message.includes('eyJ'));
  assert.equal(upload.frames.length, 1);
  assert.ok(upload.frames[0].includes('package:'));
});