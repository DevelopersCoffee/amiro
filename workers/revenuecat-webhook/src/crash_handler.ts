import {
  APP_VERSION_PATTERN,
  CRASH_BODY_MAX_BYTES,
  CRASH_PLATFORMS,
  CRASH_SOURCES,
  scrubCrashPayload,
} from './crash_allowlist.ts';
import { constantTimeEqual } from './security.ts';

export interface CrashEnv {
  CRASH_PATH_TOKEN?: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  CRASH_RATE_LIMITER?: {
    limit(options: { key: string }): Promise<{ success: boolean }>;
  };
}

const globalMinute: { window: number; count: number } = { window: 0, count: 0 };
const GLOBAL_PER_MINUTE = 100;

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
    return { ok: false, status: 400, body: 'Missing crash fields' };
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

async function checkRateLimits(
  request: Request,
  env: CrashEnv,
): Promise<Response | null> {
  const now = Math.floor(Date.now() / 60_000);
  if (globalMinute.window !== now) {
    globalMinute.window = now;
    globalMinute.count = 0;
  }
  globalMinute.count += 1;
  if (globalMinute.count > GLOBAL_PER_MINUTE) {
    return new Response('Too many requests', { status: 429 });
  }

  if (env.CRASH_RATE_LIMITER) {
    const { success } = await env.CRASH_RATE_LIMITER.limit({
      key: clientIp(request),
    });
    if (!success) {
      return new Response('Too many requests', { status: 429 });
    }
  }
  return null;
}

function validateCrashBody(body: unknown):
  | {
      ok: true;
      data: {
        message: string;
        stack: string;
        runtimeType: string;
        source: string;
        appVersion: string;
        platform: string | null;
      };
    }
  | { ok: false; status: number; body: string } {
  if (body === null || typeof body !== 'object' || Array.isArray(body)) {
    return { ok: false, status: 400, body: 'Invalid crash body' };
  }
  const record = body as Record<string, unknown>;
  if (typeof record.message !== 'string' || record.message.length === 0) {
    return { ok: false, status: 400, body: 'Missing crash fields' };
  }
  if (typeof record.appVersion !== 'string' || !APP_VERSION_PATTERN.test(record.appVersion)) {
    return { ok: false, status: 400, body: 'Invalid appVersion' };
  }
  const source =
    typeof record.source === 'string' && CRASH_SOURCES.has(record.source)
      ? record.source
      : null;
  if (!source) {
    return { ok: false, status: 400, body: 'Invalid source' };
  }
  let platform: string | null = null;
  if (record.platform != null) {
    if (typeof record.platform !== 'string' || !CRASH_PLATFORMS.has(record.platform)) {
      return { ok: false, status: 400, body: 'Invalid platform' };
    }
    platform = record.platform;
  }
  const stack = typeof record.stack === 'string' ? record.stack : '';
  const runtimeType =
    typeof record.runtimeType === 'string' && record.runtimeType.length > 0
      ? record.runtimeType
      : 'Error';
  return {
    ok: true,
    data: {
      message: record.message,
      stack,
      runtimeType,
      source,
      appVersion: record.appVersion,
      platform,
    },
  };
}

async function supabaseInsert(
  env: CrashEnv,
  row: Record<string, unknown>,
): Promise<Response> {
  const insert = await fetch(`${env.SUPABASE_URL}/rest/v1/crash_reports`, {
    method: 'POST',
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify([row]),
  });
  if (!insert.ok) {
    console.error(`crash_reports insert failed: ${insert.status}`);
    return new Response('Ingest unavailable', { status: 502 });
  }
  return new Response('ok', { status: 200 });
}

export async function handleCrash(
  request: Request,
  env: CrashEnv,
  url: URL,
): Promise<Response> {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }
  const token = url.pathname.replace(/^\/crash\//, '');
  if (!env.CRASH_PATH_TOKEN || !constantTimeEqual(token, env.CRASH_PATH_TOKEN)) {
    return new Response('Not found', { status: 404 });
  }

  const contentType = request.headers.get('Content-Type') ?? '';
  if (!contentType.toLowerCase().startsWith('application/json')) {
    return new Response('Unsupported Media Type', { status: 415 });
  }

  const rateLimited = await checkRateLimits(request, env);
  if (rateLimited) return rateLimited;

  const parsed = await readJsonBody(request, CRASH_BODY_MAX_BYTES);
  if (!parsed.ok) {
    return new Response(parsed.body, { status: parsed.status });
  }

  const validated = validateCrashBody(parsed.value);
  if (!validated.ok) {
    return new Response(validated.body, { status: validated.status });
  }

  const scrubbed = scrubCrashPayload(validated.data);

  return supabaseInsert(env, {
    message: scrubbed.message,
    stack: scrubbed.stack,
    source: validated.data.source,
    app_version: validated.data.appVersion,
    platform: validated.data.platform,
    occurred_at: new Date().toISOString(),
  });
}