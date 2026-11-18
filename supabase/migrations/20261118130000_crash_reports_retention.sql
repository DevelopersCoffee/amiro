-- Crash reports: deny client roles; purge rows older than 90 days.

revoke all on public.crash_reports from anon, authenticated;
revoke all on public.crash_reports from public;

create extension if not exists pg_cron with schema extensions;

select cron.schedule(
  'purge-crash-reports-90d',
  '0 3 * * *',
  $$delete from public.crash_reports where received_at < now() - interval '90 days'$$
);