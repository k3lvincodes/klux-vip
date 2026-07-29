-- Consolidated Initial Schema
-- Merged from all migrations up to 20260605 (seed_admin.sql excluded)
-- Represents the final state of all tables, functions, RLS, and triggers.

-- ============================================
-- EXTENSIONS
-- ============================================
create extension if not exists postgis schema extensions;
create extension if not exists "uuid-ossp";

-- ============================================
-- ENUMS
-- ============================================
create type user_role as enum ('client', 'chauffeur');
create type profile_status as enum ('pending', 'approved', 'suspended');
create type ride_status as enum ('requested', 'accepted', 'arriving', 'in_progress', 'completed', 'cancelled');
create type booking_type as enum ('instant', 'scheduled', 'special');
create type payment_type as enum ('card', 'bank_account');
create type transaction_type as enum ('ride_payment', 'withdrawal');
create type transaction_status as enum ('pending', 'completed', 'failed');
create type ticket_category as enum ('ride_issue', 'payment_issue', 'safety_concern', 'account_issue', 'other');
create type ticket_status as enum ('open', 'in_progress', 'resolved', 'closed');
create type document_type as enum ('driver_license', 'insurance', 'registration', 'background_check');
create type document_status as enum ('pending', 'approved', 'rejected');
create type notification_type as enum ('ride_request', 'ride_accepted', 'ride_arriving', 'ride_completed', 'payment_received', 'message', 'general');
create type ledger_account_type as enum ('user', 'chauffeur', 'system', 'promo');

-- ============================================
-- TABLES (in dependency order)
-- ============================================

-- 1. PROFILES (replaces old `users` table)
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  first_name text,
  last_name text,
  phone_number text unique,
  avatar_url text,
  role user_role,
  is_super_admin boolean default false not null,
  selfie_url text,
  verification_status text,
  rating numeric(3,2) default 0.00,
  rating_count integer default 0,
  email_verified_at timestamp with time zone,
  last_seen_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone
);

-- 2. DRIVER DETAILS (replaces old `driver_profiles` table)
create table public.driver_details (
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

-- 3. RIDES
create table public.rides (
  id uuid default gen_random_uuid() primary key,
  passenger_id uuid references public.profiles on delete restrict not null,
  driver_id uuid references public.profiles on delete restrict,
  pickup_location geography(point) not null,
  pickup_address text not null,
  dropoff_location geography(point) not null,
  dropoff_address text not null,
  status ride_status default 'requested'::ride_status not null,
  type booking_type default 'instant'::booking_type not null,
  scheduled_time timestamp with time zone,
  passenger_note text,
  fare_amount numeric(10,2) not null,
  batch_status text,
  cancelled_by uuid references public.profiles(id),
  cancelled_reason text,
  driver_lat double precision,
  driver_lng double precision,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone
);

-- 4. RIDE REQUESTS (separate from actual rides)
create table public.ride_requests (
  id uuid default gen_random_uuid() primary key,
  passenger_id uuid references public.profiles on delete restrict not null,
  pickup_location geography(point) not null,
  pickup_address text not null,
  dropoff_location geography(point) not null,
  dropoff_address text not null,
  fare_amount numeric(10,2) not null,
  type booking_type default 'instant'::booking_type not null,
  scheduled_time timestamp with time zone,
  passenger_note text,
  status text default 'pending' not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 5. VEHICLES
create table public.vehicles (
  id uuid default gen_random_uuid() primary key,
  driver_id uuid references public.profiles on delete cascade not null,
  make text not null,
  model text not null,
  year integer not null,
  color text not null,
  license_plate text not null,
  images text[] default '{}' not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone,
  constraint valid_year check (year between 2000 and extract(year from now()) + 1)
);

-- 6. REVIEWS
create table public.reviews (
  id uuid default gen_random_uuid() primary key,
  ride_id uuid references public.rides on delete cascade not null,
  reviewer_id uuid references public.profiles on delete cascade not null,
  reviewee_id uuid references public.profiles on delete cascade not null,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_ride_reviewer unique (ride_id, reviewer_id),
  constraint rating_bounds check (rating between 1 and 5)
);

-- 7. SUPPORT TICKETS
create table public.support_tickets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  ride_id uuid references public.rides on delete set null,
  category ticket_category not null,
  subject text not null,
  description text not null,
  status ticket_status default 'open'::ticket_status not null,
  assigned_to uuid references public.profiles(id),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone
);

-- 8. DRIVER DOCUMENTS
create table public.driver_documents (
  id uuid default gen_random_uuid() primary key,
  driver_id uuid references public.profiles on delete cascade not null,
  type document_type not null,
  file_url text not null,
  status document_status default 'pending'::document_status not null,
  rejection_reason text,
  expires_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone,
  constraint unique_driver_doc_type unique (driver_id, type)
);

-- 9. PAYMENT METHODS
create table public.payment_methods (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  provider_token text not null,
  type payment_type not null,
  last4 text,
  stripe_pm_id text,
  is_default boolean default false,
  deleted_at timestamp with time zone
);

-- 10. TRANSACTIONS
create table public.transactions (
  id uuid default gen_random_uuid() primary key,
  ride_id uuid references public.rides on delete set null,
  user_id uuid references public.profiles on delete cascade not null,
  amount numeric(10,2) not null,
  type transaction_type not null,
  status transaction_status default 'pending'::transaction_status not null,
  payer_id uuid references public.profiles(id),
  payee_id uuid references public.profiles(id),
  stripe_payment_intent_id text,
  deleted_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 11. USER DEVICES (FCM tokens)
create table public.user_devices (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  fcm_token text not null,
  device_type text not null default 'android',
  is_active boolean default true not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone,
  constraint unique_fcm_token unique (fcm_token)
);

-- 12. DEVICE BIOMETRICS
create table public.device_biometrics (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  device_id text not null,
  is_enabled boolean default false not null,
  last_verified_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  deleted_at timestamp with time zone,
  unique(user_id, device_id)
);

-- 13. NOTIFICATIONS
create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade not null,
  type notification_type not null,
  title text not null,
  body text,
  data jsonb,
  status text not null default 'pending',
  is_read boolean default false,
  delivery_status text default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 14. LEDGER ACCOUNTS
create table public.ledger_accounts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles on delete cascade,
  type ledger_account_type not null,
  balance numeric(10,2) default 0.00 not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_user_account unique (user_id)
);

-- 15. LEDGER ENTRIES
create table public.ledger_entries (
  id uuid default gen_random_uuid() primary key,
  transaction_id uuid references public.transactions on delete set null,
  from_account_id uuid references public.ledger_accounts(id) on delete restrict not null,
  to_account_id uuid references public.ledger_accounts(id) on delete restrict not null,
  amount numeric(10,2) not null check (amount > 0),
  description text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 16. DRIVER TELEMETRY
create table public.driver_telemetry (
  id uuid default gen_random_uuid() primary key,
  driver_id uuid references public.profiles on delete cascade not null,
  ride_id uuid references public.rides on delete set null,
  location geography(point) not null,
  speed double precision,
  heading double precision,
  recorded_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 17. SURGE ZONES
create table public.surge_zones (
  id uuid default gen_random_uuid() primary key,
  zone_identifier text not null unique,
  current_multiplier numeric(3,2) default 1.00 not null,
  active_drivers integer default 0 not null,
  pending_requests integer default 0 not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 18. FARE RATES
create table public.fare_rates (
  id uuid default gen_random_uuid() primary key,
  country_code varchar(2) not null,
  state_or_region varchar(100),
  per_km_rate numeric(10,2) not null,
  base_fare numeric(10,2) not null default 3.50,
  per_minute_rate numeric(10,2) not null default 0.45,
  vip_amount numeric(10,2) default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(country_code, state_or_region)
);

-- ============================================
-- RLS: ENABLE ON ALL TABLES
-- ============================================
alter table public.profiles enable row level security;
alter table public.driver_details enable row level security;
alter table public.rides enable row level security;
alter table public.ride_requests enable row level security;
alter table public.vehicles enable row level security;
alter table public.reviews enable row level security;
alter table public.support_tickets enable row level security;
alter table public.driver_documents enable row level security;
alter table public.payment_methods enable row level security;
alter table public.transactions enable row level security;
alter table public.user_devices enable row level security;
alter table public.device_biometrics enable row level security;
alter table public.notifications enable row level security;
alter table public.ledger_accounts enable row level security;
alter table public.ledger_entries enable row level security;
alter table public.driver_telemetry enable row level security;
alter table public.surge_zones enable row level security;
alter table public.fare_rates enable row level security;

-- ============================================
-- RLS POLICIES
-- ============================================

-- PROFILES
create policy "Users can view own profile." on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);
create policy "Users can insert own profile." on public.profiles for insert with check (auth.uid() = id);
create policy "Admins can view all profiles." on public.profiles for select using (public.is_admin());
create policy "Admins can update all profiles." on public.profiles for update using (public.is_admin());

-- DRIVER DETAILS
create policy "Chauffeurs can insert own details." on public.driver_details for insert with check (auth.uid() = profile_id);
create policy "Chauffeur details are viewable by everyone." on public.driver_details for select using (true);
create policy "Chauffeurs can update own details." on public.driver_details for update using (auth.uid() = profile_id);
create policy "Admins can view all chauffeur details." on public.driver_details for select using (public.is_admin());
create policy "Admins can update all chauffeur details." on public.driver_details for update using (public.is_admin());

-- RIDES
create policy "Clients can view their rides." on public.rides for select using (auth.uid() = passenger_id);
create policy "Chauffeurs can view their assigned rides." on public.rides for select using (auth.uid() = driver_id);
create policy "Chauffeurs can see requested rides." on public.rides for select using (status = 'requested');
create policy "Clients can insert rides." on public.rides for insert with check (auth.uid() = passenger_id);
create policy "Clients can update their rides only when requested." on public.rides for update using (auth.uid() = passenger_id and status = 'requested') with check (auth.uid() = passenger_id);
create policy "Chauffeurs can accept requested rides." on public.rides for update using (driver_id is null and status = 'requested') with check (auth.uid() = driver_id);
create policy "Admins can view all rides." on public.rides for select using (public.is_admin());
create policy "Admins can update all rides." on public.rides for update using (public.is_admin());

-- RIDE REQUESTS
create policy "Users can insert ride requests" on public.ride_requests for insert with check (auth.uid() = passenger_id);
create policy "Ride requests are viewable by all" on public.ride_requests for select using (true);
create policy "Drivers can update ride requests" on public.ride_requests for update using (true);

-- VEHICLES
create policy "Vehicles are viewable by everyone." on public.vehicles for select using (true);
create policy "Chauffeurs can insert their own vehicles." on public.vehicles for insert with check (auth.uid() = driver_id);
create policy "Chauffeurs can update their own vehicles." on public.vehicles for update using (auth.uid() = driver_id);
create policy "Admins can view all vehicles." on public.vehicles for select using (public.is_admin());
create policy "Admins can update all vehicles." on public.vehicles for update using (public.is_admin());

-- REVIEWS
create policy "Users can view reviews they gave or received." on public.reviews for select using (auth.uid() = reviewer_id or auth.uid() = reviewee_id);
create policy "Clients can insert reviews for chauffeurs." on public.reviews for insert with check (auth.uid() = reviewer_id);
create policy "Users cannot update their reviews." on public.reviews for update using (false);
create policy "Users cannot delete reviews." on public.reviews for delete using (false);
create policy "Admins can view all reviews." on public.reviews for select using (public.is_admin());

-- SUPPORT TICKETS
create policy "Users can view their own support tickets." on public.support_tickets for select using (auth.uid() = user_id);
create policy "Users can create support tickets." on public.support_tickets for insert with check (auth.uid() = user_id);
create policy "Users can update their own open tickets." on public.support_tickets for update using (auth.uid() = user_id and status = 'open');
create policy "Admins can view all support tickets." on public.support_tickets for select using (public.is_admin());
create policy "Admins can update all support tickets." on public.support_tickets for update using (public.is_admin());
create policy "Admins can assign support tickets." on public.support_tickets for update using (public.is_admin());

-- DRIVER DOCUMENTS
create policy "Chauffeurs can view their own documents." on public.driver_documents for select using (auth.uid() = driver_id);
create policy "Chauffeurs can upload their own documents." on public.driver_documents for insert with check (auth.uid() = driver_id);
create policy "Chauffeurs can update their own documents." on public.driver_documents for update using (auth.uid() = driver_id);
create policy "Admins can view all chauffeur documents." on public.driver_documents for select using (public.is_admin());
create policy "Admins can update all chauffeur documents." on public.driver_documents for update using (public.is_admin());

-- PAYMENT METHODS
-- (no default policies; managed by application layer)

-- TRANSACTIONS
create policy "No direct insert on transactions." on public.transactions for insert with check (false);
create policy "No direct update on transactions." on public.transactions for update using (false);
create policy "No direct delete on transactions." on public.transactions for delete using (false);
create policy "Users can view their own transactions." on public.transactions for select using (auth.uid() = user_id);
create policy "Admins can view all transactions." on public.transactions for select using (public.is_admin());

-- USER DEVICES
create policy "Users can manage their own devices." on public.user_devices for all using (auth.uid() = user_id);
create policy "Admins can view all user devices." on public.user_devices for select using (public.is_admin());

-- DEVICE BIOMETRICS
create policy "Users can manage their own device biometrics" on public.device_biometrics for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- NOTIFICATIONS
create policy "Users can view their own notifications." on public.notifications for select using (auth.uid() = user_id);
create policy "Service can insert notifications." on public.notifications for insert with check (true);
create policy "Admins can view all notifications." on public.notifications for select using (public.is_admin());

-- LEDGER ACCOUNTS
create policy "Service role manages ledger accounts." on public.ledger_accounts for all using (false);
create policy "Users read own ledger account." on public.ledger_accounts for select using (auth.uid() = user_id);
create policy "Admins can view all ledger accounts." on public.ledger_accounts for select using (public.is_admin());

-- LEDGER ENTRIES
create policy "Service role manages ledger entries." on public.ledger_entries for all using (false);
create policy "Users read own ledger entries." on public.ledger_entries for select using (auth.uid() in (select user_id from public.ledger_accounts where id = from_account_id or id = to_account_id));
create policy "Admins can view all ledger entries." on public.ledger_entries for select using (public.is_admin());

-- DRIVER TELEMETRY
create policy "Chauffeurs can insert telemetry." on public.driver_telemetry for insert with check (auth.uid() = driver_id);
create policy "Service role reads telemetry." on public.driver_telemetry for select using (false);
create policy "No updates to telemetry." on public.driver_telemetry for update using (false);
create policy "No deletes to telemetry." on public.driver_telemetry for delete using (false);
create policy "Admins can view all telemetry." on public.driver_telemetry for select using (public.is_admin());

-- SURGE ZONES
create policy "Anyone can read surge zones." on public.surge_zones for select using (true);
create policy "Admins can update surge zones." on public.surge_zones for update using (public.is_admin());

-- FARE RATES
create policy "Fare rates are viewable by everyone" on public.fare_rates for select using (true);
create policy "Fare rates are manageable by admins only" on public.fare_rates for all using (public.is_admin());

-- ============================================
-- FUNCTIONS
-- ============================================

-- Auth signup handler (no role auto-assigned; stays null until onboarding)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email)
  values (new.id, coalesce(new.email, ''));
  return new;
end;
$$ language plpgsql security definer;

-- Updated_at helper for rides
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Updated_at helper for vehicles
create or replace function public.handle_vehicle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Updated_at helper for support tickets
create or replace function public.handle_ticket_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

-- Updated_at helper for profiles
create or replace function public.handle_profile_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Updated_at helper for driver_details
create or replace function public.handle_driver_details_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Admin check (uses profiles.is_super_admin)
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

-- Accept ride: moves from ride_requests to rides
create or replace function public.accept_ride(
  ride_uuid uuid,
  driver_uuid uuid
)
returns boolean as $$
declare
  req record;
begin
  if auth.uid() is null then
    return false;
  end if;

  select * into req from public.ride_requests
  where id = ride_uuid and status = 'pending'
  for update skip locked;

  if not found then
    return false;
  end if;

  insert into public.rides (
    id, passenger_id, driver_id,
    pickup_location, pickup_address,
    dropoff_location, dropoff_address,
    fare_amount, type, scheduled_time, passenger_note,
    status, driver_lat, driver_lng
  ) values (
    ride_uuid,
    req.passenger_id,
    auth.uid(),
    req.pickup_location,
    req.pickup_address,
    req.dropoff_location,
    req.dropoff_address,
    req.fare_amount,
    req.type,
    req.scheduled_time,
    req.passenger_note,
    'accepted'::ride_status,
    null, null
  );

  update public.ride_requests
  set status = 'accepted'
  where id = ride_uuid;

  return true;
end;
$$ language plpgsql security definer;

-- Auto-cancel expired pending ride requests (30+ minutes)
create or replace function public.cancel_expired_rides()
returns void
language plpgsql
as $$
begin
  update public.ride_requests
  set status = 'cancelled'
  where status = 'pending'
    and created_at < now() - interval '30 minutes';
end;
$$;

-- Driver document approval check
create or replace function public.driver_documents_approved(driver_uuid uuid)
returns boolean as $$
declare
  doc_count integer;
begin
  select count(*) into doc_count
  from public.driver_documents
  where driver_id = driver_uuid
    and type in ('driver_license', 'insurance', 'registration')
    and status = 'approved';

  return doc_count >= 3;
end;
$$ language plpgsql;

-- Find nearby drivers (uses profiles + driver_details)
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

-- Calculate fare
create or replace function public.calculate_fare(
  distance_meters double precision,
  duration_seconds integer,
  booking_type booking_type default 'instant'::booking_type
)
returns numeric(10,2) as $$
declare
  base_fare constant numeric(5,2) := 3.50;
  per_km_rate constant numeric(5,2) := 1.85;
  per_minute_rate constant numeric(5,2) := 0.45;
  surge_multiplier numeric(3,2) := 1.00;
  total_fare numeric(10,2);
begin
  case booking_type
    when 'special' then surge_multiplier := 1.50;
    when 'scheduled' then surge_multiplier := 1.25;
    else surge_multiplier := 1.00;
  end case;

  total_fare := (
    base_fare +
    ((distance_meters / 1000.0) * per_km_rate) +
    ((duration_seconds / 60.0) * per_minute_rate)
  ) * surge_multiplier;

  return round(total_fare, 2);
end;
$$ language plpgsql;

-- Update aggregate rating (for both chauffeurs and clients)
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

  update public.profiles
  set rating = new_avg, rating_count = review_count
  where id = target_user_id;

  return new;
end;
$$ language plpgsql security definer;

-- Admin dashboard stats
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

-- Promote user to admin by email
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
    update public.profiles set is_super_admin = true where id = admin_user_id;
    raise notice 'User % promoted to super admin.', admin_user_id;
  else
    raise notice 'No user found with email: %', target_email;
  end if;
end;
$$ language plpgsql security definer;

-- Update surge zone (upsert)
create or replace function public.update_surge_zone(
  zone_id text,
  new_multiplier numeric(3,2),
  driver_count integer,
  request_count integer
) returns void as $$
begin
  insert into public.surge_zones (zone_identifier, current_multiplier, active_drivers, pending_requests, updated_at)
  values (zone_id, new_multiplier, driver_count, request_count, now())
  on conflict (zone_identifier) do update
  set current_multiplier = excluded.current_multiplier,
      active_drivers = excluded.active_drivers,
      pending_requests = excluded.pending_requests,
      updated_at = now();
end;
$$ language plpgsql security definer;

-- Device biometric: register
create or replace function public.register_device_biometric(
  p_user_id uuid,
  p_device_id text
) returns void
language plpgsql
as $$
begin
  insert into public.device_biometrics (user_id, device_id, is_enabled, last_verified_at)
  values (p_user_id, p_device_id, true, timezone('utc'::text, now()))
  on conflict (user_id, device_id)
  do update set
    is_enabled = true,
    last_verified_at = timezone('utc'::text, now()),
    updated_at = timezone('utc'::text, now());
end;
$$;

-- Device biometric: unregister
create or replace function public.unregister_device_biometric(
  p_user_id uuid,
  p_device_id text
) returns void
language plpgsql
as $$
begin
  update public.device_biometrics
  set is_enabled = false, updated_at = timezone('utc'::text, now())
  where user_id = p_user_id and device_id = p_device_id;
end;
$$;

-- Device biometric: check (SECURITY DEFINER for unauthenticated access)
create or replace function public.check_device_biometric(
  p_email text,
  p_device_id text
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_result jsonb;
  v_user_id uuid;
  v_last_verified_at timestamp with time zone;
  v_days_diff integer;
begin
  select id into v_user_id
  from auth.users
  where email = p_email;

  if v_user_id is null then
    return null;
  end if;

  select last_verified_at into v_last_verified_at
  from public.device_biometrics
  where user_id = v_user_id
    and device_id = p_device_id
    and is_enabled = true;

  if v_last_verified_at is null then
    return null;
  end if;

  v_days_diff := extract(day from (timezone('utc'::text, now()) - v_last_verified_at));

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

-- Device biometric: refresh session
create or replace function public.refresh_device_biometric(
  p_user_id uuid,
  p_device_id text
) returns void
language plpgsql
as $$
begin
  update public.device_biometrics
  set last_verified_at = timezone('utc'::text, now()),
      updated_at = timezone('utc'::text, now())
  where user_id = p_user_id
    and device_id = p_device_id
    and is_enabled = true;
end;
$$;

-- ============================================
-- TRIGGERS
-- ============================================

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create trigger on_ride_updated
  before update on public.rides
  for each row execute procedure public.handle_updated_at();

create trigger on_vehicle_updated
  before update on public.vehicles
  for each row execute procedure public.handle_vehicle_updated_at();

create trigger on_ticket_updated
  before update on public.support_tickets
  for each row execute procedure public.handle_ticket_updated_at();

create trigger on_profile_updated
  before update on public.profiles
  for each row execute procedure public.handle_profile_updated_at();

create trigger on_driver_details_updated
  before update on public.driver_details
  for each row execute procedure public.handle_driver_details_updated_at();

create trigger on_review_created
  after insert on public.reviews
  for each row execute procedure public.update_profile_rating();

-- ============================================
-- REALTIME PUBLICATIONS
-- ============================================

alter publication supabase_realtime add table public.rides;
alter publication supabase_realtime add table public.driver_details;
alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.vehicles;
alter publication supabase_realtime add table public.support_tickets;
alter publication supabase_realtime add table public.notifications;
alter publication supabase_realtime add table public.ride_requests;

-- ============================================
-- SEED DATA: FARE RATES
-- ============================================

insert into public.fare_rates (country_code, state_or_region, per_km_rate, base_fare, per_minute_rate) values
  ('US', null, 1.85, 3.50, 0.45),
  ('GB', null, 2.10, 4.00, 0.50),
  ('NG', null, 1.20, 2.00, 0.30),
  ('CA', null, 1.75, 3.50, 0.45),
  ('AU', null, 2.00, 4.50, 0.55);

-- ============================================
-- SCHEDULE AUTO-CANCEL (if pg_cron available)
-- ============================================

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
