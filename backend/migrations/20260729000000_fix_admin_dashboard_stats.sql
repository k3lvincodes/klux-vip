-- Fix get_admin_dashboard_stats: the live function used 'passenger'
-- which is not a valid user_role enum value ('client', 'chauffeur').

create or replace function public.get_admin_dashboard_stats()
returns json as $$
declare
  result json;
begin
  if not public.is_admin() then
    raise exception 'Unauthorized';
  end if;

  select json_build_object(
    'total_users', (select count(*) from public.profiles where deleted_at is null),
    'total_passengers', (select count(*) from public.profiles where role = 'client' and deleted_at is null),
    'total_drivers', (select count(*) from public.profiles where role = 'chauffeur' and deleted_at is null),
    'approved_drivers', (select count(*) from public.driver_details where status = 'approved'),
    'pending_drivers', (select count(*) from public.driver_details where status = 'pending'),
    'online_drivers', (select count(*) from public.driver_details where is_online = true),
    'total_rides', (select count(*) from public.rides where deleted_at is null),
    'active_rides', (select count(*) from public.rides where status in ('requested', 'accepted', 'arriving', 'in_progress') and deleted_at is null),
    'completed_rides', (select count(*) from public.rides where status = 'completed' and deleted_at is null),
    'total_revenue', (select coalesce(sum(fare_amount), 0) from public.rides where status = 'completed' and deleted_at is null),
    'open_tickets', (select count(*) from public.support_tickets where status in ('open', 'in_progress')),
    'pending_documents', (select count(*) from public.driver_documents where status = 'pending'),
    'total_vehicles', (select count(*) from public.vehicles where is_active = true and deleted_at is null)
  ) into result;

  return result;
end;
$$ language plpgsql security definer;
