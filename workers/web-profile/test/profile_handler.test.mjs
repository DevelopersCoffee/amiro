import assert from 'node:assert/strict';
import test from 'node:test';
import worker, { handleProfileRequest } from '../src/index.ts';

const minimalPngHex =
  '\\x89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c63000100000500010d0a2db40000000049454e44ae426082';

const token = 'abcdefghijklmnopqrstuvwxy';

const activeRow = {
  display_name: 'Uday',
  public_contact: { bio: 'Engineer' },
  card_extras: {},
  avatar_png: minimalPngHex,
  revoked_at: null,
};

const baseEnv = {
  SUPABASE_URL: 'https://example.supabase.co',
  SUPABASE_SERVICE_ROLE_KEY: 'service-key',
};

function mockFetch(rows) {
  return async (input) => {
    const url = new URL(input);
    if (!url.pathname.endsWith('/web_share_profiles')) {
      return new Response('not mocked', { status: 500 });
    }
    return new Response(JSON.stringify(rows), { status: 200 });
  };
}

async function withMockFetch(rows, fn) {
  const previous = globalThis.fetch;
  globalThis.fetch = mockFetch(rows);
  try {
    return await fn();
  } finally {
    globalThis.fetch = previous;
  }
}

test('GET profile uses private no-store and CSP', async () => {
  const env = { ...baseEnv };
  const request = new Request(`https://id.amiro.app/u/${token}`);
  const response = await withMockFetch([activeRow], () =>
    handleProfileRequest(request, env, new URL(request.url)),
  );
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  assert.equal(response.headers.get('Vary'), 'Accept');
  assert.equal(response.headers.get('Referrer-Policy'), 'no-referrer');
  assert.equal(response.headers.get('X-Content-Type-Options'), 'nosniff');
  assert.match(
    response.headers.get('Content-Security-Policy') ?? '',
    /frame-ancestors 'none'/,
  );
});

test('revoked token returns 410 with no-store', async () => {
  const env = { ...baseEnv };
  const request = new Request(`https://id.amiro.app/u/${token}`);
  const response = await withMockFetch(
    [{ ...activeRow, revoked_at: '2026-01-01T00:00:00Z' }],
    () => worker.fetch(request, env),
  );
  assert.equal(response.status, 410);
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  assert.equal(response.headers.get('Vary'), 'Accept');
});

test('tombstone row (wiped PII) returns 410', async () => {
  const env = { ...baseEnv };
  const request = new Request(`https://id.amiro.app/u/${token}`);
  const response = await withMockFetch(
    [{
      display_name: '',
      public_contact: {},
      card_extras: {},
      avatar_png: '\\x',
      revoked_at: '2026-01-01T00:00:00Z',
    }],
    () => worker.fetch(request, env),
  );
  assert.equal(response.status, 410);
});

test('short token in URL returns 404', async () => {
  const env = { ...baseEnv };
  const request = new Request('https://id.amiro.app/u/tooshort');
  const response = await worker.fetch(request, env);
  assert.equal(response.status, 404);
});

test('JSON profile uses same allowlist fields', async () => {
  const env = { ...baseEnv };
  const request = new Request(`https://id.amiro.app/u/${token}`, {
    headers: { Accept: 'application/json' },
  });
  const response = await withMockFetch(
    [{
      ...activeRow,
      public_contact: { bio: 'Engineer', leak: 'secret' },
    }],
    () => handleProfileRequest(request, env, new URL(request.url)),
  );
  const json = await response.json();
  assert.equal(json.displayName, 'Uday');
  assert.equal(json.publicContact.bio, 'Engineer');
  assert.equal(json.publicContact.leak, undefined);
});

test('avatar response uses no-store and image/png', async () => {
  const env = { ...baseEnv };
  const request = new Request(`https://id.amiro.app/u/${token}/avatar`);
  const response = await withMockFetch([activeRow], () => worker.fetch(request, env));
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('Content-Type'), 'image/png');
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
  assert.equal(response.headers.get('Vary'), 'Accept');
});