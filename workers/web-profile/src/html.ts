import type { WebShareRow } from './profile.ts';
import {
  buildPublicProfileView,
  filterPublicContact,
  filterCardExtras,
} from './public_profile.ts';

const playStoreDefault =
  'https://play.google.com/store/apps/details?id=com.developerscoffee.amiro_app';

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

function contactRows(contact: Record<string, string>): string {
  const parts: string[] = [];
  const add = (label: string, key: string, href?: (v: string) => string) => {
    const value = contact[key];
    if (!value) return;
    const inner = href
      ? `<a href="${escapeHtml(href(value))}">${escapeHtml(value)}</a>`
      : escapeHtml(value);
    parts.push(`<div class="field"><span class="label">${label}</span>${inner}</div>`);
  };
  add('Username', 'username');
  add('Bio', 'bio');
  add('Phone', 'mobile', (v) => `tel:${v}`);
  add('Email', 'email', (v) => `mailto:${v}`);
  add('Website', 'website', (v) => (v.startsWith('http') ? v : `https://${v}`));
  add('X', 'xHandle', (v) => `https://x.com/${v.replace(/^@/, '')}`);
  add('Instagram', 'instagramHandle', (v) =>
    `https://instagram.com/${v.replace(/^@/, '')}`,
  );
  return parts.join('');
}

export function renderProfileHtml(
  token: string,
  row: WebShareRow,
  playStoreUrl: string,
): string {
  const name = escapeHtml(row.display_name);
  const extras = filterCardExtras(row.card_extras);
  const equipped = extras?.equippedCosmetics ?? [];
  const cosmetics = equipped
    .map((c) => `<li>${escapeHtml(c.name)}${c.rarity ? ` · ${escapeHtml(c.rarity)}` : ''}</li>`)
    .join('');
  const contact = contactRows(filterPublicContact(row.public_contact));

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex, nofollow">
  <title>${name} · Amiro</title>
  <style>
    :root {
      --ground: #161510;
      --surface: #1F1D17;
      --border: #322F26;
      --text: #EDE8DE;
      --muted: #8C8474;
      --primary: #C08A3E;
      --on-primary: #1D1509;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      background: var(--ground);
      color: var(--text);
      font-family: "Instrument Sans", system-ui, sans-serif;
      line-height: 1.5;
      padding: 24px 16px 48px;
    }
    .card {
      max-width: 390px;
      margin: 0 auto;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 24px;
    }
    .eyebrow {
      font-size: 0.75rem;
      letter-spacing: 0.04em;
      color: var(--muted);
      text-transform: uppercase;
    }
    h1 {
      font-family: "Instrument Serif", Georgia, serif;
      font-weight: 400;
      font-size: clamp(1.4rem, 5vw, 1.45rem);
      margin: 12px 0 16px;
    }
    .avatar {
      width: 100%;
      aspect-ratio: 1;
      object-fit: cover;
      border-radius: 14px;
      background: var(--ground);
      border: 1px solid var(--border);
    }
    .field { margin-top: 12px; font-size: 0.95rem; }
    .label {
      display: block;
      font-size: 0.75rem;
      letter-spacing: 0.04em;
      color: var(--muted);
      margin-bottom: 4px;
    }
    a { color: var(--primary); }
    ul { padding-left: 1.1rem; color: var(--muted); }
    .cta {
      display: block;
      width: 100%;
      margin-top: 24px;
      padding: 14px 16px;
      border: 0;
      border-radius: 14px;
      background: var(--primary);
      color: var(--on-primary);
      font-weight: 600;
      text-align: center;
      text-decoration: none;
    }
    .cta:hover { background: #D6A254; }
  </style>
</head>
<body>
  <main class="card">
    <div class="eyebrow">Amiro</div>
    <img class="avatar" src="/u/${escapeHtml(token)}/avatar" alt="" width="342" height="342">
    <h1>${name}</h1>
    ${contact}
    ${cosmetics ? `<ul>${cosmetics}</ul>` : ''}
    <a class="cta" href="${escapeHtml(playStoreUrl)}">Get Amiro</a>
  </main>
</body>
</html>`;
}

export function resolvePlayStoreUrl(env: { PLAY_STORE_URL?: string }): string {
  if (env.PLAY_STORE_URL && env.PLAY_STORE_URL.length > 0) {
    return env.PLAY_STORE_URL;
  }
  return playStoreDefault;
}

export function profileJson(token: string, row: WebShareRow) {
  return buildPublicProfileView(token, row);
}