import {
  avatarBytesFromRow,
  fetchProfile,
  parseTokenFromPath,
  type Env,
} from './profile.ts';
import { isValidPng } from './avatar_validate.ts';
import { profileJson, renderProfileHtml, resolvePlayStoreUrl } from './html.ts';
import { responseSecurityHeaders, PRIVATE_NO_STORE } from './security_headers.ts';

function notFound(): Response {
  return new Response('Not found', {
    status: 404,
    headers: responseSecurityHeaders(),
  });
}

function gone(): Response {
  return new Response('This link has been revoked.', {
    status: 410,
    headers: responseSecurityHeaders(),
  });
}

export async function handleProfileRequest(
  request: Request,
  env: Env,
  url: URL,
): Promise<Response> {
  if (request.method !== 'GET') {
    return new Response('Method not allowed', {
      status: 405,
      headers: responseSecurityHeaders(),
    });
  }
  if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
    return new Response('Service unavailable', {
      status: 503,
      headers: responseSecurityHeaders(),
    });
  }

  const token = parseTokenFromPath(url.pathname);
  if (!token) return notFound();

  let row;
  try {
    row = await fetchProfile(env, token);
  } catch {
    return new Response('Service unavailable', {
      status: 503,
      headers: responseSecurityHeaders(),
    });
  }

  if (row === 'missing') return notFound();
  if (row === 'revoked') return gone();

  const isAvatar = url.pathname.endsWith('/avatar');
  if (isAvatar) {
    try {
      const bytes = avatarBytesFromRow(row);
      if (!isValidPng(bytes)) {
        return new Response('Bad avatar', {
          status: 502,
          headers: responseSecurityHeaders(),
        });
      }
      return new Response(bytes, {
        status: 200,
        headers: responseSecurityHeaders({
          'Content-Type': 'image/png',
        }),
      });
    } catch {
      return new Response('Bad avatar', {
        status: 502,
        headers: responseSecurityHeaders(),
      });
    }
  }

  const accept = request.headers.get('Accept') ?? '';
  if (accept.includes('application/json')) {
    return Response.json(profileJson(token, row), {
      headers: responseSecurityHeaders({ 'X-Robots-Tag': 'noindex, nofollow' }),
    });
  }

  const html = renderProfileHtml(token, row, resolvePlayStoreUrl(env));
  return new Response(html, {
    status: 200,
    headers: responseSecurityHeaders({
      'Content-Type': 'text/html; charset=utf-8',
      'X-Robots-Tag': 'noindex, nofollow',
    }),
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

export { PRIVATE_NO_STORE };