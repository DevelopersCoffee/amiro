export interface Env {
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  PLAY_STORE_URL?: string;
}

export interface WebShareRow {
  display_name: string;
  public_contact: Record<string, string>;
  card_extras: {
    equippedCosmetics?: { name: string; rarity?: string }[];
    collectionCompletion?: { seriesId: string; currentCount: number; totalCount: number }[];
  };
  avatar_png: string; // base64 from PostgREST
  revoked_at: string | null;
}

/** 128-bit base64url tokens are 22 chars without padding (#50). */
const tokenPattern = /^[A-Za-z0-9_-]{22,64}$/;

export function parseTokenFromPath(pathname: string): string | null {
  const match = pathname.match(/^\/u\/([A-Za-z0-9_-]+)(?:\/avatar)?\/?$/);
  if (!match) return null;
  const token = match[1];
  if (!tokenPattern.test(token)) return null;
  return token;
}

export async function fetchProfile(
  env: Env,
  token: string,
): Promise<WebShareRow | 'missing' | 'revoked'> {
  const url = new URL(`${env.SUPABASE_URL}/rest/v1/web_share_profiles`);
  url.searchParams.set(
    'select',
    'display_name,public_contact,card_extras,avatar_png,revoked_at',
  );
  url.searchParams.set('token', `eq.${token}`);
  url.searchParams.set('limit', '1');

  const response = await fetch(url.toString(), {
    headers: {
      apikey: env.SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${env.SUPABASE_SERVICE_ROLE_KEY}`,
    },
  });
  if (!response.ok) {
    throw new Error(`Supabase read failed: ${response.status}`);
  }
  const rows = (await response.json()) as WebShareRow[];
  if (rows.length === 0) return 'missing';
  const row = rows[0];
  if (row.revoked_at) return 'revoked';
  if (!row.display_name || row.display_name.trim().length === 0) {
    return 'revoked';
  }
  if (!row.avatar_png || row.avatar_png === '\\x') {
    return 'revoked';
  }
  return row;
}

export function decodeByteaField(value: string): Uint8Array {
  if (value.startsWith('\\x')) {
    const hex = value.slice(2);
    const bytes = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
      bytes[i / 2] = parseInt(hex.slice(i, i + 2), 16);
    }
    return bytes;
  }
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

export function avatarBytesFromRow(row: WebShareRow): Uint8Array {
  return decodeByteaField(row.avatar_png);
}