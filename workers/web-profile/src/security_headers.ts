export const PRIVATE_NO_STORE = 'private, no-store';

/** Applied to every HTML, JSON, avatar, 410, and error response. */
export function responseSecurityHeaders(
  extra: Record<string, string> = {},
): Record<string, string> {
  return {
    'Cache-Control': PRIVATE_NO_STORE,
    'Referrer-Policy': 'no-referrer',
    'X-Content-Type-Options': 'nosniff',
    'Content-Security-Policy':
      "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'",
    ...extra,
  };
}