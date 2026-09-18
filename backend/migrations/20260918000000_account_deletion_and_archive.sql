-- =============================================================================
-- Migration: Account Deletion, Soft-Delete Deactivation & Audit Archive Table
-- =============================================================================

-- 1. Create deleted_accounts table for compliance, legal, and audit preservation
create table if not exists public.deleted_accounts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null,
  original_email text,
  phone_number text,
  full_name text,
  role text,
  profile_snapshot jsonb not null,
  lifetime_rides_as_passenger integer default 0,
  lifetime_rides_as_driver integer default 0,
  lifetime_spend_or_earned numeric(12, 2) default 0.00,
  deletion_reason text,
  deleted_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_by text default 'user_self'
);

-- Index for fast lookup by user_id
create index if not exists idx_deleted_accounts_user_id on public.deleted_accounts(user_id);
create index if not exists idx_deleted_accounts_deleted_at on public.deleted_accounts(deleted_at desc);

-- 2. RLS on deleted_accounts
alter table public.deleted_accounts enable row level security;

-- Only admins can view archived deleted accounts
create policy "Admins can view archived deleted accounts"
  on public.deleted_accounts
  for select
  using (public.is_admin());

-- 3. Stored Procedure: delete_my_account(p_reason text default 'User requested deletion via app')
create or replace function public.delete_my_account(p_reason text default 'User requested deletion via app')
returns json as $$
declare
  v_user_id uuid;
  v_profile record;
  v_passenger_rides integer := 0;
  v_driver_rides integer := 0;
  v_total_spend numeric(12, 2) := 0.00;
  v_full_name text;
begin
  -- Identify caller
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Unauthorized: Must be logged in to delete account.';
  end if;

  -- Load profile
  select * into v_profile
  from public.profiles
  where id = v_user_id;

  if v_profile is null then
    return json_build_object('success', false, 'message', 'Profile not found.');
  end if;

  if v_profile.deleted_at is not null then
    return json_build_object('success', false, 'message', 'Account is already deleted.');
  end if;

  -- Calculate summary metrics for historical archive
  select count(*) into v_passenger_rides from public.rides where passenger_id = v_user_id;
  select count(*) into v_driver_rides from public.rides where driver_id = v_user_id;
  select coalesce(sum(fare_amount), 0) into v_total_spend 
  from public.rides 
  where passenger_id = v_user_id and status = 'completed';

  v_full_name := trim(concat(coalesce(v_profile.first_name, ''), ' ', coalesce(v_profile.last_name, '')));
  if v_full_name = '' then
    v_full_name := coalesce(v_profile.email, 'Client');
  end if;

  -- 1) Archive full snapshot into deleted_accounts table
  insert into public.deleted_accounts (
    user_id,
    original_email,
    phone_number,
    full_name,
    role,
    profile_snapshot,
    lifetime_rides_as_passenger,
    lifetime_rides_as_driver,
    lifetime_spend_or_earned,
    deletion_reason,
    deleted_at,
    deleted_by
  ) values (
    v_user_id,
    v_profile.email,
    v_profile.phone_number,
    v_full_name,
    v_profile.role,
    row_to_json(v_profile)::jsonb,
    v_passenger_rides,
    v_driver_rides,
    v_total_spend,
    coalesce(p_reason, 'User requested deletion via app'),
    timezone('utc'::text, now()),
    'user_self'
  );

  -- 2) Soft-delete and anonymize active profile
  update public.profiles
  set 
    deleted_at = timezone('utc'::text, now()),
    email = 'deleted_' || v_user_id::text || '@kenick-deleted.internal',
    phone_number = null,
    first_name = 'Deleted',
    last_name = 'Account',
    avatar_url = null,
    selfie_url = null,
    updated_at = timezone('utc'::text, now())
  where id = v_user_id;

  -- 3) If chauffeur, deactivate chauffeur status
  update public.driver_details
  set 
    is_online = false,
    status = 'deleted',
    updated_at = timezone('utc'::text, now())
  where profile_id = v_user_id;

  -- 4) Cancel any in-flight / active rides for this passenger
  update public.rides
  set 
    status = 'cancelled',
    cancelled_at = timezone('utc'::text, now()),
    cancelled_by = v_user_id,
    cancellation_reason = 'Account deleted by client'
  where passenger_id = v_user_id 
    and status in ('requested', 'accepted', 'arriving');

  -- Unassign any pending rides if driver
  update public.rides
  set 
    status = 'requested',
    driver_id = null
  where driver_id = v_user_id 
    and status in ('accepted', 'arriving');

  -- 5) Delete push tokens and device registrations
  delete from public.user_devices where user_id = v_user_id;
  delete from public.device_biometrics where user_id = v_user_id;

  -- 6) Ban in auth.users so the credentials can NEVER be used to sign in again
  update auth.users
  set 
    banned_until = '3000-01-01 00:00:00+00'::timestamptz,
    updated_at = timezone('utc'::text, now())
  where id = v_user_id;

  -- Revoke any active refresh tokens
  delete from auth.refresh_tokens where user_id = v_user_id::text;

  return json_build_object(
    'success', true, 
    'message', 'Account successfully deactivated and archived.'
  );
end;
$$ language plpgsql security definer;

-- Grant execution to authenticated users
grant execute on function public.delete_my_account(text) to authenticated;
