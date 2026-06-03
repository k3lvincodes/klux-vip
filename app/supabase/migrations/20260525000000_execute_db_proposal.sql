-- Execute DB Proposal: Consolidated schema restructuring
-- Creates profiles + driver_details, adds soft deletes, renames foreign keys,
-- and migrates data Ã¢â‚¬â€ while keeping old tables for backward compatibility.

-- ============================================
-- 1. CREATE PROFILES TABLE
-- ============================================
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  first_name text,
  last_name text,
  phone_number text unique,
  avatar_url text,
  role user_role not null default 'client',
  is_super_admin boolean default false not null,
  selfie_url text,
  last_seen_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone
);

-- ============================================
-- 2. CREATE DRIVER DETAILS TABLE
-- ============================================
create table if not exists public.driver_details (
  profile_id uuid references public.profiles on delete cascade primary key,
  status profile_status default 'pending' not null,
  is_online boolean default false not null,
  rating numeric(3,2) default 0.00,
  rating_count integer default 0,
  verification_status text,
  last_location geography(point),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ============================================
-- 3. ADD NEW COLUMNS TO EXISTING TABLES
-- ============================================

-- Rides: batch, cancellation, soft delete
alter table public.rides add column if not exists batch_status text;
alter table public.rides add column if not exists cancelled_by uuid references public.profiles(id);
alter table public.rides add column if not exists cancelled_reason text;
alter table public.rides add column if not exists deleted_at timestamp with time zone;

-- Transactions: explicit payer/payee, Stripe reference, soft delete
alter table public.transactions add column if not exists payer_id uuid references public.profiles(id);
alter table public.transactions add column if not exists payee_id uuid references public.profiles(id);
alter table public.transactions add column if not exists stripe_payment_intent_id text;
alter table public.transactions add column if not exists deleted_at timestamp with time zone;

-- Payment methods: Stripe PM ID, default flag, soft delete
alter table public.payment_methods add column if not exists stripe_pm_id text;
alter table public.payment_methods add column if not exists is_default boolean default false;
alter table public.payment_methods add column if not exists deleted_at timestamp with time zone;

-- Notifications: split status into is_read + delivery_status
alter table public.notifications add column if not exists is_read boolean default false;
alter table public.notifications add column if not exists delivery_status text default 'pending';

-- Support tickets: admin assignment, soft delete
alter table public.support_tickets add column if not exists assigned_to uuid references public.profiles(id);
alter table public.support_tickets add column if not exists deleted_at timestamp with time zone;

-- Soft delete on remaining tables
alter table public.vehicles add column if not exists deleted_at timestamp with time zone;
alter table public.driver_documents add column if not exists deleted_at timestamp with time zone;
alter table public.user_devices add column if not exists deleted_at timestamp with time zone;
alter table public.device_biometrics add column if not exists deleted_at timestamp with time zone;

-- ============================================
-- 4. ENABLE RLS ON NEW TABLES
-- ============================================
alter table public.profiles enable row level security;
alter table public.driver_details enable row level security;

-- ============================================
-- 5. RLS POLICIES FOR PROFILES
-- ============================================
create policy "Users can view own profile." on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);
create policy "Admins can view all profiles." on public.profiles for select using (public.is_admin());
create policy "Admins can update all profiles." on public.profiles for update using (public.is_admin());

-- ============================================
-- 6. RLS POLICIES FOR DRIVER DETAILS
-- ============================================
create policy "Chauffeur details are viewable by everyone." on public.driver_details for select using (true);
create policy "Chauffeurs can update own details." on public.driver_details for update using (auth.uid() = profile_id);
create policy "Admins can view all chauffeur details." on public.driver_details for select using (public.is_admin());
create policy "Admins can update all chauffeur details." on public.driver_details for update using (public.is_admin());

-- ============================================
-- 7. RLS POLICIES FOR NEW COLUMNS ON EXISTING TABLES
-- ============================================

-- Support tickets: admin assignment policy
drop policy if exists "Admins can assign support tickets." on public.support_tickets;
create policy "Admins can assign support tickets." on public.support_tickets for update using (public.is_admin());

-- ============================================
-- 8. TRIGGER FUNCTIONS
-- ============================================

-- Profile updated_at trigger
create or replace function public.handle_profile_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_profile_updated on public.profiles;
create trigger on_profile_updated
  before update on public.profiles
  for each row execute procedure public.handle_profile_updated_at();

-- Driver details updated_at trigger
create or replace function public.handle_driver_details_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists on_driver_details_updated on public.driver_details;
create trigger on_driver_details_updated
  before update on public.driver_details
  for each row execute procedure public.handle_driver_details_updated_at();

-- ============================================
-- 9. UPDATE AUTH SIGNUP TRIGGER
-- ============================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, role)
  values (new.id, 'client');
  insert into public.profiles (id, email, role)
  values (new.id, coalesce(new.email, ''), 'client');

  return new;
end;
$$ language plpgsql security definer;

-- ============================================
-- 10. MIGRATE DATA: PROFILES
-- ============================================
insert into public.profiles (
  id, email, first_name, last_name, phone_number, avatar_url,
  role, is_super_admin, selfie_url, created_at
)
select
  u.id,
  coalesce(au.email, ''),
  coalesce(dp.first_name, pp.first_name),
  coalesce(dp.last_name, pp.last_name),
  u.phone_number,
  coalesce(dp.profile_image_url, pp.profile_image_url),
  u.role,
  coalesce(u.is_super_admin, false),
  dp.selfie_url,
  u.created_at
from public.users u
left join auth.users au on au.id = u.id
left join public.driver_profiles dp on dp.user_id = u.id
left join public.passenger_profiles pp on pp.user_id = u.id
on conflict (id) do nothing;

-- ============================================
-- 11. MIGRATE DATA: DRIVER DETAILS
-- ============================================
insert into public.driver_details (
  profile_id, status, is_online, rating, last_location
)
select
  user_id,
  status,
  is_online,
  rating,
  current_location
from public.driver_profiles dp
where exists (select 1 from public.profiles p where p.id = dp.user_id)
on conflict (profile_id) do nothing;

-- ============================================
-- 12. UPDATE RPCs
-- ============================================

-- is_admin(): use profiles table
create or replace function public.is_admin()
returns boolean as $$
begin
  return exists (
    select 1 from public.profiles
    where id = auth.uid()
      and is_super_admin = true
      and deleted_at is null
  );
end;
$$ language plpgsql security definer;

-- find_nearby_drivers(): use profiles + driver_details
create or replace function public.find_nearby_drivers(
  pickup_lat double precision,
  pickup_lng double precision,
  radius_meters double precision default 5000
)
returns table (
  user_id uuid,
  first_name text,
  last_name text,
  distance_meters double precision,
  rating numeric(3,2)
) as $$
begin
  return query
  select
    p.id,
    p.first_name,
    p.last_name,
    ST_Distance(
      dd.last_location::geography,
      ST_SetSRID(ST_MakePoint(pickup_lng, pickup_lat), 4326)::geography
    ) as distance_meters,
    dd.rating
  from public.profiles p
  inner join public.driver_details dd on dd.profile_id = p.id
  where p.role = 'chauffeur'
    and p.deleted_at is null
    and dd.is_online = true
    and dd.status = 'approved'
    and dd.last_location is not null
    and ST_DWithin(
      dd.last_location::geography,
      ST_SetSRID(ST_MakePoint(pickup_lng, pickup_lat), 4326)::geography,
      radius_meters
    )
  order by distance_meters asc
  limit 10;
end;
$$ language plpgsql;

-- update_profile_rating(): write to driver_details + old driver_profiles
create or replace function public.update_profile_rating()
returns trigger as $$
declare
  target_user_id uuid;
  new_avg numeric(3,2);
  review_count integer;
begin
  target_user_id := new.reviewee_id;

  select coalesce(avg(rating), 0.00)::numeric(3,2), count(*)
  into new_avg, review_count
  from public.reviews
  where reviewee_id = target_user_id;

  update public.driver_details
  set rating = new_avg, rating_count = review_count
  where profile_id = target_user_id;

  update public.driver_profiles
  set rating = new_avg
  where user_id = target_user_id;

  return new;
end;
$$ language plpgsql security definer;

-- accept_ride(): use auth.uid() for security
create or replace function public.accept_ride(
  ride_uuid uuid,
  driver_uuid uuid
)
returns boolean as $$
begin
  if auth.uid() is null then
    return false;
  end if;

  update public.rides
  set driver_id = auth.uid(),
      status = 'accepted'::ride_status
  where id = ride_uuid and status = 'requested'::ride_status;

  return found;
end;
$$ language plpgsql;

-- get_admin_dashboard_stats(): use new tables
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
    'total_clients', (select count(*) from public.profiles where role = 'client' and deleted_at is null),
    'total_chauffeurs', (select count(*) from public.profiles where role = 'chauffeur' and deleted_at is null),
    'approved_chauffeurs', (select count(*) from public.driver_details where status = 'approved'),
    'pending_chauffeurs', (select count(*) from public.driver_details where status = 'pending'),
    'online_chauffeurs', (select count(*) from public.driver_details where is_online = true),
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

-- ============================================
-- 13. REALTIME
-- ============================================
alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.driver_details;

-- ============================================
-- 14. UPDATE SEED ADMIN SCRIPT
-- ============================================
-- This updates the seed_admin migration logic so it also sets profiles.
-- The next person to promote an admin will use this path.
create or replace function public.promote_to_admin(target_email text)
returns void as $$
declare
  admin_user_id uuid;
begin
  select id into admin_user_id
  from auth.users
  where email = target_email
  limit 1;

  if admin_user_id is not null then
    update public.users set is_super_admin = true where id = admin_user_id;
    update public.profiles set is_super_admin = true where id = admin_user_id;
    raise notice 'User % promoted to super admin.', admin_user_id;
  else
    raise notice 'No user found with email: %', target_email;
  end if;
end;
$$ language plpgsql security definer;
