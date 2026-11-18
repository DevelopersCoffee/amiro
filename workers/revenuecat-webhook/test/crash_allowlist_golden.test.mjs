import assert from 'node:assert/strict';
import fs from 'node:fs';
import test from 'node:test';

import {
  filterDartStackFrames,
  prepareCrashMessage,
  redactCrashSecrets,
  scrubCrashPayload,
} from '../src/crash_allowlist.ts';

const golden = JSON.parse(
  fs.readFileSync(
    new URL('../../../test/fixtures/crash_allowlist_golden.json', import.meta.url),
    'utf8',
  ),
);

for (const entry of golden.secretRedaction) {
  test(`secret redaction: ${entry.id}`, () => {
    assert.equal(redactCrashSecrets(entry.input), entry.expected);
  });
}

for (const entry of golden.messageUpload) {
  test(`message upload allowlist: ${entry.id}`, () => {
    assert.equal(
      prepareCrashMessage(entry.runtimeType, entry.input),
      entry.expected,
    );
  });
}

test('stack frame allowlist', () => {
  assert.equal(
    filterDartStackFrames(golden.stackFilter.input),
    golden.stackFilter.expected,
  );
});

test('full report scrub matches golden', () => {
  const out = scrubCrashPayload({
    runtimeType: golden.fullReport.runtimeType,
    message: golden.fullReport.message,
    stack: golden.fullReport.stack,
  });
  assert.equal(out.message, golden.fullReport.expectedMessage);
  assert.equal(out.stack, golden.fullReport.expectedStack);
});