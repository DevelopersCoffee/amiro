-- Analytics events: deny client roles; purge rows older than 90 days.

revoke all on public.analytics_events from anon, authenticated;
revoke all on public.analytics_events from public;

select cron.schedule(
  'purge-analytics-events-90d',
  '0 4 * * *',
  $$delete from public.analytics_events where received_at < now() - interval '90 days'$$
);