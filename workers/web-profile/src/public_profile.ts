import type { WebShareRow } from './profile.ts';

/** Keep in sync with `packages/sharing/lib/src/web_share_public_view.dart`. */
export const PUBLIC_CONTACT_KEYS = [
  'username',
  'bio',
  'mobile',
  'email',
  'website',
  'xHandle',
  'instagramHandle',
] as const;

export const CARD_EXTRA_KEYS = ['equippedCosmetics', 'collectionCompletion'] as const;

export function filterPublicContact(
  contact: Record<string, string> | undefined,
): Record<string, string> {
  const out: Record<string, string> = {};
  const src = contact ?? {};
  for (const key of PUBLIC_CONTACT_KEYS) {
    const value = src[key];
    if (typeof value === 'string' && value.length > 0) {
      out[key] = value;
    }
  }
  return out;
}

export function filterCardExtras(
  extras: WebShareRow['card_extras'] | undefined,
): WebShareRow['card_extras'] {
  if (!extras) return {};
  const out: WebShareRow['card_extras'] = {};
  for (const key of CARD_EXTRA_KEYS) {
    const value = extras[key as keyof typeof extras];
    if (value !== undefined) {
      (out as Record<string, unknown>)[key] = value;
    }
  }
  return out;
}

export function buildPublicProfileView(token: string, row: WebShareRow) {
  return {
    displayName: row.display_name,
    publicContact: filterPublicContact(row.public_contact),
    cardExtras: filterCardExtras(row.card_extras),
    avatarUrl: `/u/${token}/avatar`,
  };
}