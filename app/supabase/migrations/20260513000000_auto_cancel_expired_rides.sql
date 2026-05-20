-- Auto-cancel rides that have been 'requested' for more than 30 minutes

-- Function to cancel expired rides
create or replace function public.cancel_expired_rides()
returns void
language plpgsql
as $$
begin
  update public.rides
  set status = 'cancelled'
  where status = 'requested'
    and created_at < now() - interval '30 minutes';
end;
$$;

-- Schedule via pg_cron if extension is available
do $do$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule(
      'cancel-expired-rides',
      '* * * * *',
      $$select public.cancel_expired_rides()$$
    );
  end if;
end;
$do$;
