-- Phase 1: Schema & Data Layer Additions
-- Klux VIP Backend Implementation

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================
-- 1. VEHICLES TABLE
-- ============================================
create table public.vehicles (
  id uuid default gen_random_uuid() primary key,
  driver_id uuid references public.users on delete cascade not null,
  make text not null,
  model text not null,
  year integer not null,
  color text not null,
  license_plate text not null,
  is_active boolean default true not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint valid_year check (year between 2000 and extract(year from now()) + 1)
);

-- Enable RLS
alter table public.vehicles enable row level security;

-- RLS Policies for vehicles
create policy "Vehicles are viewable by everyone." on public.vehicles for select using (true);
create policy "Chauffeurs can insert their own vehicles." on public.vehicles for insert with check (auth.uid() = driver_id);
create policy "Chauffeurs can update their own vehicles." on public.vehicles for update using (auth.uid() = driver_id);

-- Trigger for vehicle updated_at
create or replace function public.handle_vehicle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_vehicle_updated
  before update on public.vehicles
  for each row execute procedure public.handle_vehicle_updated_at();

-- ============================================
-- 2. REVIEWS TABLE
-- ============================================
create table public.reviews (
  id uuid default gen_random_uuid() primary key,
  ride_id uuid references public.rides on delete cascade not null,
  reviewer_id uuid references public.users on delete cascade not null,
  reviewee_id uuid references public.users on delete cascade not null,
  rating integer not null check (rating between 1 and 5),
  comment text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_ride_reviewer unique (ride_id, reviewer_id),
  constraint rating_bounds check (rating between 1 and 5)
);

-- Enable RLS
alter table public.reviews enable row level security;

-- RLS Policies for reviews
create policy "Users can view reviews they gave or received." on public.reviews for select using (auth.uid() = reviewer_id or auth.uid() = reviewee_id);
create policy "Clients can insert reviews for chauffeurs." on public.reviews for insert with check (auth.uid() = reviewer_id);
create policy "Users cannot update their reviews." on public.reviews for update using (false);
create policy "Users cannot delete reviews." on public.reviews for delete using (false);

-- Function to update aggregate rating on profiles
create or replace function public.update_profile_rating()
returns trigger as $$
declare
  target_user_id uuid;
  new_avg numeric(3,2);
begin
  -- Determine which profile to update based on reviewee_id
  target_user_id := new.reviewee_id;
  
  -- Calculate new average rating from reviews
  select coalesce(avg(rating), 5.00)::numeric(3,2)
  into new_avg
  from public.reviews
  where reviewee_id = target_user_id;
  
  -- Update driver profile if exists
  update public.driver_profiles
  set rating = new_avg
  where user_id = target_user_id;
  
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to auto-update rating after review insert
create trigger on_review_created
  after insert on public.reviews
  for each row execute procedure public.update_profile_rating();

-- ============================================
-- 3. SUPPORT TICKETS TABLE
-- ============================================
create type ticket_category as enum ('ride_issue', 'payment_issue', 'safety_concern', 'account_issue', 'other');
create type ticket_status as enum ('open', 'in_progress', 'resolved', 'closed');

create table public.support_tickets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  ride_id uuid references public.rides on delete set null,
  category ticket_category not null,
  subject text not null,
  description text not null,
  status ticket_status default 'open'::ticket_status not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.support_tickets enable row level security;

-- RLS Policies for support tickets
create policy "Users can view their own support tickets." on public.support_tickets for select using (auth.uid() = user_id);
create policy "Users can create support tickets." on public.support_tickets for insert with check (auth.uid() = user_id);
create policy "Users can update their own open tickets." on public.support_tickets for update using (auth.uid() = user_id and status = 'open');

-- Trigger for support_ticket updated_at
create or replace function public.handle_ticket_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

create trigger on_ticket_updated
  before update on public.support_tickets
  for each row execute procedure public.handle_ticket_updated_at();

-- ============================================
-- 4. DRIVER DOCUMENTS TABLE
-- ============================================
create type document_type as enum ('driver_license', 'insurance', 'registration', 'background_check');
create type document_status as enum ('pending', 'approved', 'rejected');

create table public.driver_documents (
  id uuid default gen_random_uuid() primary key,
  driver_id uuid references public.users on delete cascade not null,
  type document_type not null,
  file_url text not null,
  status document_status default 'pending'::document_status not null,
  rejection_reason text,
  expires_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_driver_doc_type unique (driver_id, type)
);

-- Enable RLS
alter table public.driver_documents enable row level security;

-- RLS Policies for driver documents
create policy "Chauffeurs can view their own documents." on public.driver_documents for select using (auth.uid() = driver_id);
create policy "Chauffeurs can upload their own documents." on public.driver_documents for insert with check (auth.uid() = driver_id);
create policy "Chauffeurs can update their own documents." on public.driver_documents for update using (auth.uid() = driver_id);

-- Function to check if driver has all required documents approved
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

-- ============================================
-- 5. DATABASE FUNCTIONS (PostGIS)
-- ============================================

-- Find nearby chauffeurs function
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
    dp.user_id,
    dp.first_name,
    dp.last_name,
    ST_Distance(
      dp.current_location::geography,
      ST_SetSRID(ST_MakePoint(pickup_lng, pickup_lat), 4326)::geography
    ) as distance_meters,
    dp.rating
  from public.driver_profiles dp
  where dp.is_online = true
    and dp.status = 'approved'
    and dp.current_location is not null
    and ST_DWithin(
      dp.current_location::geography,
      ST_SetSRID(ST_MakePoint(pickup_lng, pickup_lat), 4326)::geography,
      radius_meters
    )
  order by distance_meters asc
  limit 10;
end;
$$ language plpgsql;

-- Calculate fare function
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
  -- Apply surge multiplier based on booking type
  case booking_type
    when 'special' then surge_multiplier := 1.50;
    when 'scheduled' then surge_multiplier := 1.25;
    else surge_multiplier := 1.00;
  end case;
  
  -- Calculate fare
  total_fare := (
    base_fare +
    ((distance_meters / 1000.0) * per_km_rate) +
    ((duration_seconds / 60.0) * per_minute_rate)
  ) * surge_multiplier;
  
  -- Round to 2 decimal places
  return round(total_fare, 2);
end;
$$ language plpgsql;

-- ============================================
-- 6. RLS HARDENING
-- ============================================

-- Drop existing permissive policies and replace with hardened versions

-- Rides: Restrict UPDATE after creation (prevent tampering)
drop policy if exists "Clients can update their unassigned rides." on public.rides;
drop policy if exists "Chauffeurs can accept and update their assigned rides." on public.rides;

-- New hardened policies for rides
create policy "Clients can update their rides only when requested." on public.rides for update using 
  (auth.uid() = passenger_id and status = 'requested');

create policy "Chauffeurs can accept requested rides." on public.rides for update using 
  (auth.uid() = driver_id and status = 'requested');

-- Create a helper function for chauffeur to accept ride
create or replace function public.accept_ride(
  ride_uuid uuid,
  driver_uuid uuid
)
returns boolean as $$
begin
  update public.rides
  set driver_id = driver_uuid, status = 'accepted'::ride_status
  where id = ride_uuid and status = 'requested'::ride_status;
  
  return found;
end;
$$ language plpgsql;

-- Transactions: Restrict writes to service role only
drop policy if exists "Service role can manage transactions." on public.transactions;

create policy "No direct insert on transactions." on public.transactions for insert with check (false);
create policy "No direct update on transactions." on public.transactions for update using (false);
create policy "No direct delete on transactions." on public.transactions for delete using (false);

-- Users can view their own transaction history
create policy "Users can view their own transactions." on public.transactions for select using (auth.uid() = user_id);

-- ============================================
-- 7. REALTIME ADDITIONS
-- ============================================
alter publication supabase_realtime add table public.vehicles;
alter publication supabase_realtime add table public.support_tickets;

-- ============================================
-- 8. USER DEVICES & NOTIFICATIONS TABLES
-- ============================================

-- User devices for FCM tokens
create table public.user_devices (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  fcm_token text not null,
  device_type text not null default 'android',
  is_active boolean default true not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_fcm_token unique (fcm_token)
);

alter table public.user_devices enable row level security;

create policy "Users can manage their own devices." on public.user_devices for all using (auth.uid() = user_id);

-- Notifications table for push notification history
create type notification_type as enum ('ride_request', 'ride_accepted', 'ride_arriving', 'ride_completed', 'payment_received', 'message', 'general');

create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  type notification_type not null,
  title text not null,
  body text,
  data jsonb,
  status text not null default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.notifications enable row level security;

create policy "Users can view their own notifications." on public.notifications for select using (auth.uid() = user_id);
create policy "Service can insert notifications." on public.notifications for insert with check (true);

alter publication supabase_realtime add table public.notifications;