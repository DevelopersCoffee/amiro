const buckets = new Map<string, { count: number; resetAt: number }>();

export function allowRequest(
  clientKey: string,
  limitPerMinute: number,
): boolean {
  const now = Date.now();
  const existing = buckets.get(clientKey);
  if (!existing || existing.resetAt <= now) {
    buckets.set(clientKey, { count: 1, resetAt: now + 60_000 });
    return true;
  }
  if (existing.count >= limitPerMinute) return false;
  existing.count += 1;
  return true;
}

export function clientKeyFromRequest(request: Request): string {
  return (
    request.headers.get('cf-connecting-ip') ??
    request.headers.get('x-forwarded-for') ??
    'unknown'
  );
}