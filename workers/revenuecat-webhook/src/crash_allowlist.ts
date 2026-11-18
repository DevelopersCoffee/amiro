export const CRASH_MESSAGE_PRE = 2048;
export const CRASH_STACK_PRE = 8192;
export const CRASH_MESSAGE_FINAL = 300;
export const CRASH_STACK_FINAL = 8000;
export const CRASH_BODY_MAX_BYTES = 16_384;
export const RUNTIME_TYPE_MAX = 120;

export const DART_RUNTIME_TYPE_PATTERN = /^[A-Za-z_$][A-Za-z0-9_$]{0,119}$/;

const JWT =
  /eyJ[A-Za-z0-9_-]{1,2000}\.[A-Za-z0-9_-]{1,2000}\.[A-Za-z0-9_-]{1,2000}/g;
const BEARER = /Bearer\s+\S{1,500}/g;
const UUID =
  /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/g;
const URL_WITH_QUERY_FRAGMENT =
  /https?:\/\/(?:[^\s"'<>]|'[^']*'|"[^"]*")+/gu;
const FILE_URL = /file:\/\/[^\s"'<>]+/gu;
const WIN_PATH = /(?:^|[\s(])([A-Za-z]:\\[^\s"'<>]+)/gu;
const HEX32 = /(?<![0-9a-fA-F])[0-9a-fA-F]{32}(?![0-9a-fA-F])/g;
const GOOGLE_PLAY_ORDER = /GPA\.[0-9A-Za-z\-_]{4,200}/g;
const GOOGLE_PLAY_PURCHASE_TOKEN =
  /(?:purchase[_-]?token|Purchases?Token)\s*[=:]\s*['"]?[A-Za-z0-9._\-+/=]{16,200}/gi;
const HEX = /(?<![\w/])[0-9a-fA-F]{16,128}(?![\w/])/g;
const BASE64 = /[A-Za-z0-9+/_\-]{20,}={0,2}/g;
const SHARE_PATH_TOKEN = /(?<=\/u\/)[A-Za-z0-9_-]{10,}/g;
const EMAIL =
  /[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9.-]{1,253}\.[a-zA-Z]{2,24}/g;
const PHONE = /\+?[0-9][0-9\s\-().]{6,24}[0-9]/g;
const UNIX_PATH = /(?:^|[\s(]|[:=]\s*['"]?)(\/[\p{L}\p{N}./\-_]{1,200})/gu;
const JSON_OBJECT_STRING_PAIR = /"([^"]+)"\s*:\s*"([^"\\]|\\.)*"/g;
const DART_FRAME =
  /^#\d+\s+\S.* \((package:[a-z0-9_]+\/|dart:[a-z_]+)[\w/.-]*:\d+(:\d+)?\)$/;

export const APP_VERSION_PATTERN = /^\d{1,6}\.\d{1,6}\.\d{1,6}(\+\d{1,6})?$/;
export const CRASH_SOURCES = new Set(['flutter', 'platform']);
export const CRASH_PLATFORMS = new Set(['android', 'ios']);

function truncateText(input: string, max: number): string {
  if (input.length <= max) return input;
  return input.slice(0, max);
}

export function redactCrashSecrets(input: string): string {
  return input
    .replace(JWT, '[redacted-jwt]')
    .replace(BEARER, '[redacted-bearer]')
    .replace(UUID, '[redacted-uuid]')
    .replace(URL_WITH_QUERY_FRAGMENT, '[redacted-url]')
    .replace(FILE_URL, '[redacted-path]')
    .replace(WIN_PATH, (match, path) => match.replace(path, '[redacted-path]'))
    .replace(SHARE_PATH_TOKEN, '[redacted-base64url]')
    .replace(GOOGLE_PLAY_ORDER, '[redacted-play-order]')
    .replace(GOOGLE_PLAY_PURCHASE_TOKEN, '[redacted-play-token]')
    .replace(HEX32, '[redacted-hex32]')
    .replace(HEX, '[redacted-hex]')
    .replace(EMAIL, '[redacted-email]')
    .replace(PHONE, '[redacted-phone]')
    .replace(UNIX_PATH, (match, path) => match.replace(path, '[redacted-path]'))
    .replace(BASE64, (match) =>
      match.includes('redacted') ? match : '[redacted-base64]',
    );
}

export function applyCrashMessageAllowlist(body: string): string {
  let text = body.replace(
    JSON_OBJECT_STRING_PAIR,
    (match, key: string) => {
      if (match.includes('[redacted-')) return match;
      return `"${key}":"[redacted-text]"`;
    },
  );
  text = text.replace(/\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+\b/g, '[redacted-text]');
  return text;
}

export function filterDartStackFrames(stack: string): string {
  const kept: string[] = [];
  for (const line of stack.split('\n')) {
    const trimmed = line.trimEnd();
    if (!trimmed) continue;
    if (DART_FRAME.test(trimmed)) kept.push(trimmed);
  }
  return kept.join('\n');
}

export function sanitizeRuntimeType(raw: string): string {
  const scrubbed = truncateText(redactCrashSecrets(raw), RUNTIME_TYPE_MAX);
  return DART_RUNTIME_TYPE_PATTERN.test(scrubbed) ? scrubbed : 'Error';
}

function scrubbedFirstLine(runtimeType: string, rawMessage: string): string {
  let body = rawMessage;
  const prefix = `${runtimeType}: `;
  if (body.startsWith(prefix)) {
    body = body.slice(prefix.length);
  }
  body = body.split(/\r?\n/)[0] ?? '';
  body = truncateText(body, CRASH_MESSAGE_PRE);
  body = redactCrashSecrets(body);
  body = applyCrashMessageAllowlist(body);
  body = truncateText(body, CRASH_MESSAGE_FINAL);
  return `${runtimeType}: ${body}`;
}

export function prepareCrashMessage(runtimeType: string, rawMessage: string): string {
  const safeType = sanitizeRuntimeType(runtimeType);
  const line = scrubbedFirstLine(safeType, rawMessage);
  return truncateText(line, CRASH_MESSAGE_FINAL);
}

export function prepareCrashStack(rawStack: string): string {
  let stack = truncateText(rawStack, CRASH_STACK_PRE);
  stack = filterDartStackFrames(stack);
  return truncateText(stack, CRASH_STACK_FINAL);
}

export function scrubCrashPayload(body: {
  message?: unknown;
  stack?: unknown;
  runtimeType?: unknown;
  source?: unknown;
  appVersion?: unknown;
  platform?: unknown;
}): { message: string; stack: string; runtimeType: string } {
  const rawType =
    typeof body.runtimeType === 'string' && body.runtimeType.length > 0
      ? body.runtimeType
      : 'Error';
  const messageStr = typeof body.message === 'string' ? body.message : '';
  const stackStr = typeof body.stack === 'string' ? body.stack : '';
  const runtimeType = sanitizeRuntimeType(rawType);
  return {
    runtimeType,
    message: prepareCrashMessage(runtimeType, messageStr),
    stack: prepareCrashStack(stackStr),
  };
}