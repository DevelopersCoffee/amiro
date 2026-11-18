/// Public Supabase project coordinates. The anon key is meant to ship in
/// the app. Row access is enforced by row level security; the service-role
/// key is not in this file.
const supabaseProjectUrl = 'https://srvhqmfjqmxxvrdctbtf.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNydmhxbWZqcW14eHZyZGN0YnRmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2NTYzOTAsImV4cCI6MjEwNjIzMjM5MH0.PsihJP_JBL0RgJ6XLRJqViIrDfB_xeXVSU020mJsB34';

/// Host for published web profiles (override at build time).
const webSharePublicHost = String.fromEnvironment(
  'AMIRO_WEB_SHARE_HOST',
  defaultValue: 'id.amiro.app',
);

/// JSON profile fetch for in-app https scans (same host as [webSharePublicHost]).
String webShareProfileJsonUrl(String token) =>
    'https://$webSharePublicHost/u/$token';