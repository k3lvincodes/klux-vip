-- Super Admin Infrastructure
-- Adds is_super_admin flag and RLS policies for admin dashboard access

-- ============================================
-- 1. ADD SUPER ADMIN COLUMN
-- ============================================
alter table public.users add column if not exists is_super_admin boolean default false not null;

-- ============================================
-- 2. HELPER FUNCTION: is_admin()
-- ============================================
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1 from public.users
    where id = auth.uid()
      and is_super_admin = true
  );
end;
$$ language plpgsql security definer;

-- ============================================
-- 3. ADMIN RLS POLICIES
-- ============================================

-- Users table
create policy "Admins can view all users." on public.users for select using (public.is_admin());
create policy "Admins can update all users." on public.users for update using (public.is_admin());

-- Driver profiles
create policy "Admins can view all driver profiles." on public.driver_profiles for select using (public.is_admin());
create policy "Admins can update all driver profiles." on public.driver_profiles for update using (public.is_admin());

-- Passenger profiles
create policy "Admins can view all passenger profiles." on public.passenger_profiles for select using (public.is_admin());
create policy "Admins can update all passenger profiles." on public.passenger_profiles for update using (public.is_admin());

-- Rides
create policy "Admins can view all rides." on public.rides for select using (public.is_admin());
create policy "Admins can update all rides." on public.rides for update using (public.is_admin());

-- Vehicles
create policy "Admins can view all vehicles." on public.vehicles for select using (public.is_admin());
create policy "Admins can update all vehicles." on public.vehicles for update using (public.is_admin());

-- Reviews
create policy "Admins can view all reviews." on public.reviews for select using (public.is_admin());

-- Support tickets
create policy "Admins can view all support tickets." on public.support_tickets for select using (public.is_admin());
create policy "Admins can update all support tickets." on public.support_tickets for update using (public.is_admin());

-- Driver documents
create policy "Admins can view all driver documents." on public.driver_documents for select using (public.is_admin());
create policy "Admins can update all driver documents." on public.driver_documents for update using (public.is_admin());

-- Transactions
create policy "Admins can view all transactions." on public.transactions for select using (public.is_admin());

-- Ledger accounts
create policy "Admins can view all ledger accounts." on public.ledger_accounts for select using (public.is_admin());

-- Ledger entries
create policy "Admins can view all ledger entries." on public.ledger_entries for select using (public.is_admin());

-- Notifications
create policy "Admins can view all notifications." on public.notifications for select using (public.is_admin());

-- Driver telemetry
create policy "Admins can view all telemetry." on public.driver_telemetry for select using (public.is_admin());

-- Surge zones
create policy "Admins can update surge zones." on public.surge_zones for update using (public.is_admin());

-- User devices
create policy "Admins can view all user devices." on public.user_devices for select using (public.is_admin());

-- ============================================
-- 4. ADMIN DASHBOARD STATS FUNCTION
-- ============================================
create or replace function public.get_admin_dashboard_stats()
returns json as $$
declare
  result json;
begin
  -- Only allow super admins
  if not public.is_admin() then
    raise exception 'Unauthorized';
  end if;

  select json_build_object(
    'total_users', (select count(*) from public.users),
    'total_passengers', (select count(*) from public.users where role = 'passenger'),
    'total_drivers', (select count(*) from public.users where role = 'driver'),
    'approved_drivers', (select count(*) from public.driver_profiles where status = 'approved'),
    'pending_drivers', (select count(*) from public.driver_profiles where status = 'pending'),
    'online_drivers', (select count(*) from public.driver_profiles where is_online = true),
    'total_rides', (select count(*) from public.rides),
    'active_rides', (select count(*) from public.rides where status in ('requested', 'accepted', 'arriving', 'in_progress')),
    'completed_rides', (select count(*) from public.rides where status = 'completed'),
    'total_revenue', (select coalesce(sum(fare_amount), 0) from public.rides where status = 'completed'),
    'open_tickets', (select count(*) from public.support_tickets where status in ('open', 'in_progress')),
    'pending_documents', (select count(*) from public.driver_documents where status = 'pending'),
    'total_vehicles', (select count(*) from public.vehicles where is_active = true)
  ) into result;

  return result;
end;
$$ language plpgsql security definer;
