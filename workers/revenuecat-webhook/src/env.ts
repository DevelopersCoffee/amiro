export interface Env {
  WEBHOOK_PATH_TOKEN: string;
  WEBHOOK_AUTHORIZATION?: string;
  WEBHOOK_SIGNING_SECRET?: string;
  CRASH_PATH_TOKEN?: string;
  ANALYTICS_PATH_TOKEN?: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
}