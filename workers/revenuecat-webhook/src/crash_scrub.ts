const EMAIL =
  /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;
const PHONE = /\+?\d[\d\s().-]{8,}\d/g;
const URL_WITH_QUERY = /https?:\/\/[^\s"'<>]+\?[^\s"'<>]*/g;
const FILE_URI = /file:\/\/[^\s"'<>]+/g;
const WINDOWS_PATH = /[A-Za-z]:\\[^\s"'<>]+/g;
const UNIX_PATH = /\/(?:[\w.-]+\/)+[\w.-]*/g;

export function scrubCrashText(input: string): string {
  return input
    .replace(EMAIL, '[redacted-email]')
    .replace(PHONE, '[redacted-phone]')
    .replace(URL_WITH_QUERY, '[redacted-url]')
    .replace(FILE_URI, '[redacted-path]')
    .replace(WINDOWS_PATH, '[redacted-path]')
    .replace(UNIX_PATH, '[redacted-path]');
}

export function scrubCrashPayload(body: {
  message?: string;
  stack?: string;
  source?: string;
  appVersion?: string;
  platform?: string;
  at?: string;
}): typeof body {
  return {
    ...body,
    message: body.message ? scrubCrashText(body.message) : body.message,
    stack: body.stack ? scrubCrashText(body.stack) : body.stack,
  };
}

export const CRASH_MESSAGE_MAX = 2000;
export const CRASH_STACK_MAX = 8000;