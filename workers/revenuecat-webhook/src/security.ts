export function constantTimeEqual(
  a: string | undefined | null,
  b: string | undefined | null,
): boolean {
  if (a == null || b == null) {
    return false;
  }
  if (typeof a !== 'string' || typeof b !== 'string') {
    return false;
  }
  const enc = new TextEncoder();
  const left = enc.encode(a);
  const right = enc.encode(b);
  if (left.length !== right.length) {
    return false;
  }
  let diff = 0;
  for (let i = 0; i < left.length; i++) {
    diff |= left[i] ^ right[i];
  }
  return diff === 0;
}

export async function hmacSha256Hex(
  key: string,
  message: string | Uint8Array,
): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    enc.encode(key),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const data = typeof message === 'string' ? enc.encode(message) : message;
  const signature = await crypto.subtle.sign('HMAC', cryptoKey, data);
  return [...new Uint8Array(signature)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export function parseRevenueCatSignature(
  header: string | null,
): { timestamp: string; signature: string } | null {
  if (!header) return null;
  let timestamp: string | undefined;
  let signature: string | undefined;
  for (const part of header.split(',')) {
    const [key, value] = part.trim().split('=');
    if (key === 't') timestamp = value;
    if (key === 'v1') signature = value;
  }
  if (!timestamp || !signature) return null;
  return { timestamp, signature };
}

export async function verifyRevenueCatWebhookSignature(
  header: string | null,
  rawBody: Uint8Array,
  signingSecret: string,
  maxSkewSeconds = 300,
): Promise<boolean> {
  const parsed = parseRevenueCatSignature(header);
  if (!parsed) return false;
  const ts = Number(parsed.timestamp);
  if (!Number.isFinite(ts)) return false;
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - ts) > maxSkewSeconds) return false;
  const enc = new TextEncoder();
  const prefix = enc.encode(`${parsed.timestamp}.`);
  const message = new Uint8Array(prefix.length + rawBody.length);
  message.set(prefix);
  message.set(rawBody, prefix.length);
  const expected = await hmacSha256Hex(signingSecret, message);
  return constantTimeEqual(expected, parsed.signature);
}
