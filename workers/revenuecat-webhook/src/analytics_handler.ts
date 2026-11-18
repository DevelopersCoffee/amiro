import type { Env } from './env.ts';
import {
  ANALYTICS_MAX_BODY_BYTES,
  ANALYTICS_MAX_EVENTS_PER_REQUEST,
  sanitiseAnalyticsEvent,
} from './analytics_schema.ts';
import { constantTimeEqual } from './security.ts';

async function supabaseInsert(
  env: Env,
  rows: Record<string, unknown>[],
): Promise<Response> {
  const url = `${env.SUPABASE_URL}/rest/v1/analytics_events`;
  return fetch(url, {
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
}

export async function handleAnalytics(
  request: Request,
  env: Env,
  url: URL,
): Promise<Response> {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }
  const token = url.pathname.replace(/^\/analytics\//, '');
  if (
    !env.ANALYTICS_PATH_TOKEN ||
    !constantTimeEqual(token, env.ANALYTICS_PATH_TOKEN)
  ) {
    return new Response('Not found', { status: 404 });
  }

  const rawBytes = new Uint8Array(await request.arrayBuffer());
  if (rawBytes.byteLength > ANALYTICS_MAX_BODY_BYTES) {
    return new Response('Payload too large', { status: 413 });
  }

  let body: { events?: unknown[] };
  try {
    body = JSON.parse(new TextDecoder().decode(rawBytes));
  } catch {
    return new Response('Invalid JSON', { status: 400 });
  }

  if (!Array.isArray(body.events)) {
    return new Response('Missing events array', { status: 400 });
  }
  if (body.events.length === 0) {
    return new Response('Empty batch', { status: 400 });
  }
  if (body.events.length > ANALYTICS_MAX_EVENTS_PER_REQUEST) {
    return new Response('Too many events', { status: 400 });
  }

  const rows: Record<string, unknown>[] = [];
  for (const item of body.events) {
    if (typeof item !== 'object' || item === null || Array.isArray(item)) {
      return new Response('Invalid event shape', { status: 400 });
    }
    const cleaned = sanitiseAnalyticsEvent(item as Record<string, unknown>);
    if (cleaned === null) {
      return new Response('Unknown or invalid event', { status: 400 });
    }
    rows.push(cleaned);
  }

  const insert = await supabaseInsert(env, rows);
  if (!insert.ok) {
    return new Response(`Supabase analytics insert failed: ${await insert.text()}`, {
      status: 502,
    });
  }
  return new Response('ok', { status: 200 });
}