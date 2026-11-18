export const ANALYTICS_EVENT_NAMES = new Set([
  'setup_complete',
  'first_share',
  'paywall_shown',
  'purchase',
  'second_encounter',
  'invite_sent',
  'export_shared',
]);

export const ANALYTICS_COMMUNITY_SLUGS = new Set(['beta', 'launch', 'organic']);

export const ANALYTICS_SRC = new Set(['share', 'export', 'store_listing']);

export const ANALYTICS_SURFACES = new Set(['store_tab', 'payment_ask', 'store_item']);

export const ANALYTICS_SKU_KINDS = new Set(['cosmetic', 'plus', 'pack']);

const COMMON_KEYS = new Set([
  'event',
  'event_day',
  'app_version',
  'platform',
  'install_id',
]);

/** Max JSON body bytes for POST /analytics/<token>. */
export const ANALYTICS_MAX_BODY_BYTES = 8192;

/** Max events in one batch. */
export const ANALYTICS_MAX_EVENTS_PER_REQUEST = 20;

export function allowedKeysForEvent(event: string): Set<string> {
  if (!ANALYTICS_EVENT_NAMES.has(event)) return new Set();
  const keys = new Set(COMMON_KEYS);
  if (event === 'paywall_shown') keys.add('surface');
  if (event === 'purchase') keys.add('sku_kind');
  return keys;
}

export function sanitiseAnalyticsEvent(
  raw: Record<string, unknown>,
): Record<string, unknown> | null {
  if (typeof raw.event !== 'string' || !ANALYTICS_EVENT_NAMES.has(raw.event)) {
    return null;
  }
  const allowed = allowedKeysForEvent(raw.event);
  const out: Record<string, unknown> = {};
  for (const key of allowed) {
    const value = raw[key];
    if (value === undefined || value === null) continue;
    if (typeof value !== 'string') continue;
    if (key === 'surface' && !ANALYTICS_SURFACES.has(value)) continue;
    if (key === 'sku_kind' && !ANALYTICS_SKU_KINDS.has(value)) continue;
    if (key === 'community_slug' && !ANALYTICS_COMMUNITY_SLUGS.has(value)) {
      continue;
    }
    if (key === 'src' && !ANALYTICS_SRC.has(value)) continue;
    if (key === 'install_id' && value.length > 64) continue;
    if (key === 'app_version' && value.length > 32) continue;
    if (key === 'platform' && value.length > 16) continue;
    if (key === 'event_day' && !/^\d{4}-\d{2}-\d{2}$/.test(value)) continue;
    out[key] = value;
  }
  if (
    typeof out.event !== 'string' ||
    typeof out.event_day !== 'string' ||
    typeof out.app_version !== 'string' ||
    typeof out.install_id !== 'string'
  ) {
    return null;
  }
  return out;
}