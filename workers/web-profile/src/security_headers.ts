export const NO_STORE_CACHE = 'no-store';

/** Applied to every HTML, JSON, avatar, 410, and error response. */
export function responseSecurityHeaders(
  extra: Record<string, string> = {},
): Record<string, string> {
  return {
    'Cache-Control': NO_STORE_CACHE,
    Vary: 'Accept',
    'Referrer-Policy': 'no-referrer',
    'X-Content-Type-Options': 'nosniff',
    'Content-Security-Policy':
      "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'",
    ...extra,
  };
}