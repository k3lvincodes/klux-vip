-- Auto-cancel rides stuck in 'requested' status for over 30 minutes
-- Runs every minute via pg_cron

-- Ensure pg_cron and pg_net extensions are enabled
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Cancel stale requested rides
select cron.schedule(
  'auto-cancel-stale-rides',
  '* * * * *',
  $$
    update public.rides
    set status = 'cancelled'::ride_status
    where status = 'requested'::ride_status
      and created_at < now() - interval '30 minutes';
  $$
);
