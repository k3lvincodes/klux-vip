-- ============================================
-- KLUX VIP HOTFIXES MIGRATION
-- Fixes critical RLS, security, and logic bugs identified in the SQL audit
-- ============================================

-- ============================================
-- 1. FIX: Drivers Cannot Accept Rides (RLS Bug)
-- ============================================
-- The previous policy evaluated `auth.uid() = driver_id` BEFORE the update.
-- Since requested rides have a NULL driver_id, this evaluated to false, blocking acceptance.
-- We fix this by allowing updates when driver_id IS NULL, and enforcing the new driver_id with CHECK.
drop policy if exists "Drivers can accept requested rides." on public.rides;

create policy "Drivers can accept requested rides." on public.rides for update 
  using (driver_id is null and status = 'requested')
  with check (auth.uid() = driver_id);


-- ============================================
-- 2. FIX: Passenger Ride Tampering (Missing CHECK)
-- ============================================
-- The previous policy lacked a `with check` clause, meaning a passenger could update
-- their ride and maliciously change the passenger_id to someone else's ID.
drop policy if exists "Passengers can update their rides only when requested." on public.rides;

create policy "Passengers can update their rides only when requested." on public.rides for update 
  using (auth.uid() = passenger_id and status = 'requested')
  with check (auth.uid() = passenger_id);


-- ============================================
-- 3. FIX: Biometric Authentication Fails for Logged-Out Users
-- ============================================
-- The `check_device_biometric` function must query `auth.users` to map an email to a UUID.
-- Because biometric login happens BEFORE the user is authenticated, the caller lacks permissions.
-- We must recreate the function with SECURITY DEFINER to grant it elevated privileges.
drop function if exists public.check_device_biometric(text, text);

create or replace function public.check_device_biometric(
  p_email text,
  p_device_id text
) returns jsonb
language plpgsql
security definer -- Critical fix: allows function to query auth.users anonymously
as $$
declare
  v_result jsonb;
  v_user_id uuid;
  v_last_verified_at timestamp with time zone;
  v_days_diff integer;
begin
  -- Get the user id from auth.users (requires security definer for anon access)
  select id into v_user_id
  from auth.users
  where email = p_email;

  if v_user_id is null then
    return null;
  end if;

  -- Check device biometric record
  select last_verified_at into v_last_verified_at
  from public.device_biometrics
  where user_id = v_user_id
    and device_id = p_device_id
    and is_enabled = true;

  if v_last_verified_at is null then
    return null;
  end if;

  v_days_diff := extract(day from (timezone('utc'::text, now()) - v_last_verified_at));

  -- Require re-authentication via password after 7 days
  if v_days_diff >= 7 then
    return null;
  end if;

  v_result := jsonb_build_object(
    'user_id', v_user_id,
    'days_remaining', 7 - v_days_diff
  );

  return v_result;
end;
$$;


-- ============================================
-- 4. FIX: Secure the accept_ride RPC
-- ============================================
-- Previously, the RPC blindly accepted the `driver_uuid` passed by the client.
-- Even though RLS would catch it (once fixed), it is much safer to rely entirely 
-- on the cryptographically secure auth.uid() token.
create or replace function public.accept_ride(
  ride_uuid uuid,
  driver_uuid uuid -- Keeping parameter for client signature compatibility
)
returns boolean as $$
begin
  -- Enforce that the driver accepting the ride is actually the authenticated caller
  if auth.uid() is null then
    return false;
  end if;

  update public.rides
  set driver_id = auth.uid(), -- Force use of actual auth token ID
      status = 'accepted'::ride_status
  where id = ride_uuid and status = 'requested'::ride_status;
  
  return found;
end;
$$ language plpgsql;
