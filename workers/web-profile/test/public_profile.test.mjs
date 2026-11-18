import assert from 'node:assert/strict';
import test from 'node:test';
import { buildPublicProfileView, filterPublicContact } from '../src/public_profile.ts';

test('filterPublicContact uses allowlist', () => {
  const out = filterPublicContact({
    bio: 'Hi',
    extra: 'drop',
    username: 'ada',
  });
  assert.deepEqual(out, { bio: 'Hi', username: 'ada' });
  assert.equal('extra' in out, false);
});

test('buildPublicProfileView matches HTML/JSON shape', () => {
  const view = buildPublicProfileView('abcdefghijklmnopqrstuvwxy', {
    display_name: 'Ada',
    public_contact: { bio: 'x', junk: 'y' },
    card_extras: {},
    avatar_png: '\\x',
    revoked_at: null,
  });
  assert.equal(view.displayName, 'Ada');
  assert.deepEqual(view.publicContact, { bio: 'x' });
  assert.equal(view.avatarUrl, '/u/abcdefghijklmnopqrstuvwxy/avatar');
});