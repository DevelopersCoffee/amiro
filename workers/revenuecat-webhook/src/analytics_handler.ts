import type { Env } from './env.ts';
import {
  ANALYTICS_MAX_BODY_BYTES,
  ANALYTICS_MAX_EVENTS_PER_REQUEST,
  INSTALL_ID_UUID_PATTERN,
  sanitiseAnalyticsEvent,
} from './analytics_schema.ts';
import { constantTimeEqual } from './security.ts';

async function readJsonBody(
  request: Request,
  maxBytes: number,
): Promise<{ ok: true; value: unknown } | { ok: false; status: number; body: string }> {
  const lengthHeader = request.headers.get('Content-Length');
  if (lengthHeader != null) {
    const length = Number(lengthHeader);
    if (Number.isFinite(length) && length > maxBytes) {
      return { ok: false, status: 413, body: 'Payload too large' };
    }
  }

  const chunks: Uint8Array[] = [];
  let total = 0;
  if (request.body) {
    const reader = request.body.getReader();
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      if (!value) continue;
      total += value.byteLength;
      if (total > maxBytes) {
        return { ok: false, status: 413, body: 'Payload too large' };
      }
      chunks.push(value);
    }
  }

  const merged = new Uint8Array(total);
  let offset = 0;
  for (const c of chunks) {
    merged.set(c, offset);
    offset += c.byteLength;
  }
  const text = new TextDecoder().decode(merged);
  if (!text.trim()) {
    return { ok: false, status: 400, body: 'Missing body' };
  }
  try {
    return { ok: true, value: JSON.parse(text) };
  } catch {
    return { ok: false, status: 400, body: 'Invalid JSON' };
  }
}

function clientIp(request: Request): string {
  return (
    request.headers.get('cf-connecting-ip') ??
    request.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    'unknown'
  );
}

function rateLimitKey(request: Request): string {
  return `analytics:${clientIp(request)}`;
}

async function checkRateLimits(
  request: Request,
  env: Env,
): Promise<Response | null> {
  if (!env.ANALYTICS_RATE_LIMITER) {
    return new Response('Ingest unavailable', { status: 503 });
  }
  const { success } = await env.ANALYTICS_RATE_LIMITER.limit({
    key: rateLimitKey(request),
  });
  if (!success) {
    return new Response('Too many requests', { status: 429 });
  }
  return null;
}

function verifyAnalyticsPathToken(env: Env, url: URL): Response | null {
  const token = url.pathname.replace(/^\/analytics\//, '');
  if (
    !env.ANALYTICS_PATH_TOKEN ||
    !constantTimeEqual(token, env.ANALYTICS_PATH_TOKEN)
  ) {
    return new Response('Not found', { status: 404 });
  }
  return null;
}

async function supabaseInsert(
  env: Env,
  rows: Record<string, unknown>[],
): Promise<Response> {
  const url = `${env.SUPABASE_URL}/rest/v1/analytics_events`;
  const insert = await fetch(url, {
    method: 'POST',
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify(
      rows.map((row) => ({
        event_name: row.event,
        event_day: row.event_day,
        app_version: row.app_version,
        platform: row.platform ?? null,
        install_id: row.install_id,
        surface: row.surface ?? null,
        sku_kind: row.sku_kind ?? null,
        community_slug: row.community_slug ?? null,
        src: row.src ?? null,
      })),
    ),
  });
  if (!insert.ok) {
    console.error(`analytics_events insert failed: ${insert.status}`);
    return new Response('Ingest unavailable', { status: 502 });
  }
  return new Response('ok', { status: 200 });
}

async function supabaseRevokeByInstallId(
  env: Env,
  installId: string,
): Promise<Response> {
  const params = new URLSearchParams({ install_id: `eq.${installId}` });
  const del = await fetch(
    `${env.SUPABASE_URL}/rest/v1/analytics_events?${params}`,
    {
      method: 'DELETE',
      headers: {
        apikey: env.SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
        Prefer: 'return=minimal',
      },
    },
  );
  if (!del.ok) {
    console.error(`analytics_events revoke failed: ${del.status}`);
    return new Response('Ingest unavailable', { status: 502 });
  }
  return new Response('ok', { status: 200 });
}

async function handleAnalyticsPost(
  request: Request,
  env: Env,
): Promise<Response> {
  const parsed = await readJsonBody(request, ANALYTICS_MAX_BODY_BYTES);
  if (!parsed.ok) {
    return new Response(parsed.body, { status: parsed.status });
  }

  const body = parsed.value;
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    return new Response('Invalid JSON', { status: 400 });
  }
  const record = body as { events?: unknown[] };
  if (!Array.isArray(record.events)) {
    return new Response('Missing events array', { status: 400 });
  }
  if (record.events.length === 0) {
    return new Response('Empty batch', { status: 400 });
  }
  if (record.events.length > ANALYTICS_MAX_EVENTS_PER_REQUEST) {
    return new Response('Too many events', { status: 400 });
  }

  const rows: Record<string, unknown>[] = [];
  for (const item of record.events) {
    if (typeof item !== 'object' || item === null || Array.isArray(item)) {
      return new Response('Invalid event shape', { status: 400 });
    }
    const raw = item as Record<string, unknown>;
    const installId = raw.install_id;
    if (
      typeof installId !== 'string' ||
      !INSTALL_ID_UUID_PATTERN.test(installId)
    ) {
      return new Response('Invalid install_id', { status: 400 });
    }
    const cleaned = sanitiseAnalyticsEvent(raw);
    if (cleaned === null) {
      return new Response('Unknown or invalid event', { status: 400 });
    }
    rows.push(cleaned);
  }

  return supabaseInsert(env, rows);
}

async function handleAnalyticsRevoke(
  request: Request,
  env: Env,
): Promise<Response> {
  const parsed = await readJsonBody(request, 512);
  if (!parsed.ok) {
    return new Response(parsed.body, { status: parsed.status });
  }

  const body = parsed.value;
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    return new Response('Invalid JSON', { status: 400 });
  }
  const installId = (body as { install_id?: unknown }).install_id;
  if (typeof installId !== 'string' || !INSTALL_ID_UUID_PATTERN.test(installId)) {
    return new Response('Invalid install_id', { status: 400 });
  }

  return supabaseRevokeByInstallId(env, installId);
}

export async function handleAnalytics(
  request: Request,
  env: Env,
  url: URL,
): Promise<Response> {
  const tokenFailure = verifyAnalyticsPathToken(env, url);
  if (tokenFailure) return tokenFailure;

  if (request.method !== 'POST' && request.method !== 'DELETE') {
    return new Response('Method not allowed', { status: 405 });
  }

  const rateLimited = await checkRateLimits(request, env);
  if (rateLimited) return rateLimited;

  if (request.method === 'DELETE') {
    return handleAnalyticsRevoke(request, env);
  }
  return handleAnalyticsPost(request, env);
}