export const CRASH_BODY_MAX_BYTES = 16_384;
export const CRASH_MESSAGE_MAX = 500;
export const CRASH_FRAMES_MAX = 30;
export const CRASH_FRAME_LINE_MAX = 256;

const ALLOWED_SOURCES = new Set(['flutter', 'platform']);
const ALLOWED_PLATFORMS = new Set([
  'android',
  'ios',
  'linux',
  'macos',
  'windows',
  'fuchsia',
]);

const JWT =
  /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/g;
const JWT_PREFIX = /\beyJ[A-Za-z0-9_-]+\b/g;
const BEARER = /\bBearer\s+[A-Za-z0-9._~+/=-]{8,}\b/gi;
const UUID =
  /\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b/gi;
const HEX32 = /\b[0-9a-f]{32,64}\b/gi;
const EMAIL = /\b[A-Za-z0-9._%+-]{1,64}@[A-Za-z0-9.-]{1,253}\.[A-Za-z]{2,}\b/g;
const PHONE = /\b\+?\d[\d\s().-]{6,14}\d\b/g;
const URL_SECRET = /\bhttps?:\/\/[^\s"'<>#]+/gi;
const FRAGMENT = /#[^\s"'<>]+/g;
const QUERY_VALUE = /([?&][^= \t\r\n"']+=)([^&\s"'<>]+)/g;

export type CrashUpload = {
  exceptionType: string;
  message: string;
  frames: string[];
  source: string;
  appVersion: string;
  platform: string | null;
};

/** Truncate then redact in one pass — safe for large inputs (linear time). */
export function scrubCrashMessage(input: string, max = CRASH_MESSAGE_MAX): string {
  let text = input.length > max ? input.slice(0, max) : input;
  text = text.replace(JWT, '[redacted-jwt]');
  text = text.replace(JWT_PREFIX, '[redacted-jwt]');
  text = text.replace(BEARER, 'Bearer [redacted]');
  text = text.replace(UUID, '[redacted-id]');
  text = text.replace(HEX32, '[redacted-hex]');
  text = text.replace(EMAIL, '[redacted-email]');
  text = text.replace(PHONE, '[redacted-phone]');
  text = text.replace(URL_SECRET, '[redacted-url]');
  text = text.replace(FRAGMENT, '#[redacted]');
  text = text.replace(QUERY_VALUE, '$1[redacted]');
  if (text.length > max) {
    text = text.slice(0, max);
  }
  return text;
}

export function extractPackageFrames(
  stack: string,
  maxFrames = CRASH_FRAMES_MAX,
): string[] {
  const frames: string[] = [];
  for (const line of stack.split(/\r?\n/)) {
    if (!line.includes('package:')) continue;
    const trimmed = line.trim().slice(0, CRASH_FRAME_LINE_MAX);
    if (trimmed.length === 0) continue;
    frames.push(scrubCrashMessage(trimmed, CRASH_FRAME_LINE_MAX));
    if (frames.length >= maxFrames) break;
  }
  return frames;
}

export function parseCrashUpload(raw: unknown): CrashUpload | null {
  if (raw == null || typeof raw !== 'object') return null;
  const body = raw as Record<string, unknown>;
  const exceptionType = body.exceptionType;
  const message = body.message;
  const frames = body.frames;
  const source = body.source;
  const appVersion = body.appVersion;
  const platform = body.platform;

  if (typeof exceptionType !== 'string' || exceptionType.length === 0) {
    return null;
  }
  if (typeof message !== 'string') return null;
  if (!Array.isArray(frames) || !frames.every((f) => typeof f === 'string')) {
    return null;
  }
  if (typeof source !== 'string' || !ALLOWED_SOURCES.has(source)) return null;
  if (typeof appVersion !== 'string' || appVersion.length === 0) return null;
  if (appVersion.length > 64) return null;
  if (platform !== null && platform !== undefined) {
    if (typeof platform !== 'string' || !ALLOWED_PLATFORMS.has(platform)) {
      return null;
    }
  }

  const safeFrames = frames
    .slice(0, CRASH_FRAMES_MAX)
    .map((f) => scrubCrashMessage(f, CRASH_FRAME_LINE_MAX))
    .filter((f) => f.includes('package:'));

  return {
    exceptionType: scrubCrashMessage(exceptionType, 128),
    message: scrubCrashMessage(message),
    frames: safeFrames,
    source,
    appVersion: appVersion.slice(0, 64),
    platform: platform == null ? null : (platform as string),
  };
}