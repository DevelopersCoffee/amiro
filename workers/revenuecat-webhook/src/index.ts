export interface Env {
  WEBHOOK_PATH_TOKEN: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
}

interface RevenueCatEvent {
  id: string;
  type: string;
  app_user_id: string;
  product_id?: string;
  entitlement_ids?: string[];
  store?: string;
  [key: string]: unknown;
}

const REVOKING_EVENT_TYPES = new Set([
  'CANCELLATION',
  'EXPIRATION',
  'BILLING_ISSUE',
]);

async function supabaseRequest(
  env: Env,
  path: string,
  init: RequestInit,
): Promise<Response> {
  return fetch(`${env.SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
      Prefer: 'resolution=merge-duplicates',
      ...init.headers,
    },
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const pathToken = url.pathname.replace(/^\/webhook\//, '');

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }
    if (pathToken !== env.WEBHOOK_PATH_TOKEN) {
      return new Response('Not found', { status: 404 });
    }

    let body: { event?: RevenueCatEvent };
    try {
      body = await request.json();
    } catch {
      return new Response('Invalid JSON', { status: 400 });
    }

    const event = body.event;
    if (!event?.id || !event.type || !event.app_user_id) {
      return new Response('Missing event fields', { status: 400 });
    }

    const logResp = await supabaseRequest(env, 'revenuecat_events?on_conflict=event_id', {
      method: 'POST',
      headers: { Prefer: 'resolution=ignore-duplicates,return=minimal' },
      body: JSON.stringify([
        {
          event_id: event.id,
          event_type: event.type,
          app_user_id: event.app_user_id,
          product_id: event.product_id ?? null,
          entitlement_ids: event.entitlement_ids ?? [],
          store: event.store ?? null,
          raw_event: event,
        },
      ]),
    });
    if (!logResp.ok && logResp.status !== 409) {
      return new Response(`Supabase log insert failed: ${await logResp.text()}`, {
        status: 502,
      });
    }

    const entitlementIds = event.entitlement_ids ?? [];
    if (entitlementIds.length > 0) {
      const revoked = REVOKING_EVENT_TYPES.has(event.type);
      const rows = entitlementIds.map((key) => ({
        app_user_id: event.app_user_id,
        entitlement_key: key,
        product_id: event.product_id ?? null,
        granted_at: new Date().toISOString(),
        revoked_at: revoked ? new Date().toISOString() : null,
      }));
      const grantResp = await supabaseRequest(
        env,
        'entitlement_grants?on_conflict=app_user_id,entitlement_key',
        {
          method: 'POST',
          headers: {
            Prefer: 'resolution=merge-duplicates,return=minimal',
          },
          body: JSON.stringify(rows),
        },
      );
      if (!grantResp.ok) {
        return new Response(`Supabase grant upsert failed: ${await grantResp.text()}`, {
          status: 502,
        });
      }
    }

    return new Response('ok', { status: 200 });
  },
};
