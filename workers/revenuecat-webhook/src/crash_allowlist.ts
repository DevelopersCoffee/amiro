export const CRASH_MESSAGE_PRE = 2048;
export const CRASH_STACK_PRE = 8192;
export const CRASH_MESSAGE_FINAL = 300;
export const CRASH_STACK_FINAL = 8000;
export const CRASH_BODY_MAX_BYTES = 16_384;
export const RUNTIME_TYPE_MAX = 120;

export const DART_RUNTIME_TYPE_PATTERN =
  /^[A-Za-z_$][\w$<>, ]{0,119}$/;

const JWT =
  /eyJ[A-Za-z0-9_-]{1,2000}\.[A-Za-z0-9_-]{1,2000}\.[A-Za-z0-9_-]{1,2000}/g;
const BEARER = /Bearer\s+\S{1,500}/g;
const UUID =
  /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/g;
const HTTP_URL =
  /https?:\/\/(?:[^\s"'<>]|'[^']*'|"[^"]*")+/gu;
const FILE_URL = /file:\/\/[^\s"'<>]+/gu;
const WIN_PATH = /(?:^|[\s(])([A-Za-z]:\\[^\s"'<>]+)/gu;
const HEX32 = /(?<![0-9a-fA-F])[0-9a-fA-F]{32}(?![0-9a-fA-F])/g;
const GOOGLE_PLAY_ORDER =
  /GPA\.[0-9A-Za-z\-_]{12,200}/g;
const PURCHASE_TOKEN_KEY =
  /\b(purchase[_-]?token|token)["']?\s*[=:\s]\s*['"]?([A-Za-z0-9._\-+/=]+)/gi;
const HEX = /(?<![\w/])[0-9a-fA-F]{16,128}(?![\w/])/g;
const BASE64 = /[A-Za-z0-9+/_\-]{20,}={0,2}/g;
const SHARE_PATH_TOKEN = /(?<=\/u\/)[A-Za-z0-9_-]{10,}/g;
const EMAIL =
  /[a-zA-Z0-9._%+-]{1,64}@[a-zA-Z0-9.-]{1,253}\.[a-zA-Z]{2,24}/g;
const PHONE = /\+?[0-9][0-9\s\-().]{6,24}[0-9]/g;
const UNIX_PATH = /(?:^['"]?|[\s(]['"]?|[:=]\s*['"]?)(\/[\p{L}\p{N}./\-_]{1,200})/gu;
const DART_FRAME =
  /^#\d+\s+\S.* \((package:[a-z0-9_]+\/|dart:[a-z_]+)[\w/.-]*:\d+(:\d+)?\)$/;

export const APP_VERSION_PATTERN = /^\d{1,6}\.\d{1,6}\.\d{1,6}(\+\d{1,6})?$/;
export const CRASH_SOURCES = new Set(['flutter', 'platform']);
export const CRASH_PLATFORMS = new Set(['android', 'ios']);

function truncateText(input: string, max: number): string {
  if (input.length <= max) return input;
  return input.slice(0, max);
}

export function sanitizeCrashRuntimeType(raw: string): string {
  const capped = truncateText(raw, RUNTIME_TYPE_MAX);
  if (!DART_RUNTIME_TYPE_PATTERN.test(capped)) {
    return 'Error';
  }
  if (redactCrashSecrets(capped) !== capped) {
    return 'Error';
  }
  if (/\s/.test(capped)) {
    const firstAngle = capped.indexOf('<');
    const lastAngle = capped.lastIndexOf('>');
    if (firstAngle === -1 || lastAngle === -1 || firstAngle >= lastAngle) {
      return 'Error';
    }
    const firstSpace = capped.search(/\s/);
    const lastSpace = capped.length - 1 - [...capped].reverse().join('').search(/\s/);
    if (firstSpace < firstAngle || lastSpace > lastAngle) {
      return 'Error';
    }
    if (/(?<!,)\s/.test(capped) || /,\s{2,}/.test(capped)) {
      return 'Error';
    }
  }
  return capped;
}

export function redactCrashSecrets(input: string): string {
  return input
    .replace(JWT, '[redacted-jwt]')
    .replace(BEARER, '[redacted-bearer]')
    .replace(UUID, '[redacted-uuid]')
    .replace(HTTP_URL, '[redacted-url]')
    .replace(FILE_URL, '[redacted-path]')
    .replace(WIN_PATH, (match, path) => match.replace(path, '[redacted-path]'))
    .replace(SHARE_PATH_TOKEN, '[redacted-base64url]')
    .replace(GOOGLE_PLAY_ORDER, '[redacted-play-purchase]')
    .replace(PURCHASE_TOKEN_KEY, '$1=[redacted-play-token]')
    .replace(HEX32, '[redacted-hex32]')
    .replace(HEX, '[redacted-hex]')
    .replace(EMAIL, '[redacted-email]')
    .replace(PHONE, '[redacted-phone]')
    .replace(UNIX_PATH, (match, path) => match.replace(path, '[redacted-path]'))
    .replace(BASE64, (match) =>
      match.includes('redacted') ? match : '[redacted-base64]',
    );
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

function scrubbedFirstLine(
  runtimeType: string,
  rawMessage: string,
  rawRuntimeType?: string,
): string {
  let body = rawMessage;
  for (const type of new Set(
    [runtimeType, rawRuntimeType].filter((t): t is string => Boolean(t)),
  )) {
    const prefix = `${type}: `;
    if (body.startsWith(prefix)) {
      body = body.slice(prefix.length);
      break;
    }
  }
  body = body.split(/\r?\n/)[0] ?? '';
  body = truncateText(body, CRASH_MESSAGE_PRE);
  body = redactCrashSecrets(body);
  body = truncateText(body, CRASH_MESSAGE_FINAL);
  const withType = `${runtimeType}: ${body}`;
  return truncateText(withType, CRASH_MESSAGE_FINAL);
}

export function prepareCrashMessage(runtimeType: string, rawMessage: string): string {
  const safeType = sanitizeCrashRuntimeType(runtimeType);
  return scrubbedFirstLine(safeType, rawMessage, runtimeType);
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
}): { message: string; stack: string } {
  const rawType =
    typeof body.runtimeType === 'string' && body.runtimeType.length > 0
      ? body.runtimeType
      : 'Error';
  const messageStr = typeof body.message === 'string' ? body.message : '';
  const stackStr = typeof body.stack === 'string' ? body.stack : '';
  return {
    message: prepareCrashMessage(rawType, messageStr),
    stack: prepareCrashStack(stackStr),
  };
}
