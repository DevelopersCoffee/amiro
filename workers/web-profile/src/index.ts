import {
  avatarBytesFromRow,
  fetchProfile,
  parseTokenFromPath,
  type Env,
} from './profile.ts';
import { profileJson, renderProfileHtml, resolvePlayStoreUrl } from './html.ts';
import { allowRequest, clientKeyFromRequest } from './rate_limit.ts';

const noStore = { 'Cache-Control': 'no-store' };

function notFound(): Response {
  return new Response('Not found', { status: 404, headers: noStore });
}

function gone(): Response {
  return new Response('This link has been revoked.', {
    status: 410,
    headers: noStore,
  });
}

function rateLimited(): Response {
  return new Response('Too many requests', {
    status: 429,
    headers: { ...noStore, 'Retry-After': '60' },
  });
}

export async function handleProfileRequest(
  request: Request,
  env: Env,
  url: URL,
): Promise<Response> {
  if (request.method !== 'GET') {
    return new Response('Method not allowed', { status: 405, headers: noStore });
  }
  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
    return new Response('Profile service not configured', { status: 500 });
  }

  const limit = Number(env.RATE_LIMIT_PER_MINUTE ?? '60');
  const key = clientKeyFromRequest(request);
  if (!allowRequest(key, Number.isFinite(limit) && limit > 0 ? limit : 60)) {
    return rateLimited();
  }

  const token = parseTokenFromPath(url.pathname);
  if (!token) return notFound();

  let row;
  try {
    row = await fetchProfile(env, token);
  } catch {
    return new Response('Upstream error', { status: 502, headers: noStore });
  }

  if (row === 'missing') return notFound();
  if (row === 'revoked') return gone();

  const isAvatar = url.pathname.endsWith('/avatar');
  if (isAvatar) {
    try {
      const bytes = avatarBytesFromRow(row);
      return new Response(bytes, {
        status: 200,
        headers: {
          'Content-Type': 'image/png',
          'Cache-Control': 'public, max-age=3600',
        },
      });
    } catch {
      return new Response('Bad avatar', { status: 502, headers: noStore });
    }
  }

  const accept = request.headers.get('Accept') ?? '';
  if (accept.includes('application/json')) {
    return Response.json(profileJson(token, row), {
      headers: { ...noStore, 'X-Robots-Tag': 'noindex, nofollow' },
    });
  }

  const html = renderProfileHtml(token, row, resolvePlayStoreUrl(env));
  return new Response(html, {
    status: 200,
    headers: {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=300',
      'X-Robots-Tag': 'noindex, nofollow',
    },
  });
}

export default {
  fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (!url.pathname.startsWith('/u/')) {
      return Promise.resolve(notFound());
    }
    return handleProfileRequest(request, env, url);
  },
};