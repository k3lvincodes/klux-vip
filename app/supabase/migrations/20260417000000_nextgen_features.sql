-- Phase 5: Next-Generation Highly Functional Features
-- Includes schemas for: Batch Dispatching, Dynamic Surge, Immutable Ledger, Telemetry

-- ============================================
-- A. INTELLIGENT BATCH DISPATCHING
-- ============================================

create table public.ride_batch_queue (
  id uuid default gen_random_uuid() primary key,
  ride_id uuid references public.rides on delete cascade not null,
  passenger_id uuid references public.users on delete cascade not null,
  pickup_lat double precision not null,
  pickup_lng double precision not null,
  status text default 'queued' not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.ride_batch_queue enable row level security;
create policy "Service role can manage batch queue." on public.ride_batch_queue for all using (false);

-- ============================================
-- B. REAL-TIME DYNAMIC SURGE ENGINE
-- ============================================

create table public.surge_zones (
  id uuid default gen_random_uuid() primary key,
  -- A hex grid ID or geofence representing the zone
  zone_identifier text not null unique,
  -- The current multiplier based on real-time supply/demand
  current_multiplier numeric(3,2) default 1.00 not null,
  -- Number of active drivers in the zone
  active_drivers integer default 0 not null,
  -- Number of pending requests in the zone
  pending_requests integer default 0 not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.surge_zones enable row level security;
create policy "Anyone can read surge zones." on public.surge_zones for select using (true);

-- Function to safely update surge zones
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

-- ============================================
-- C. IMMUTABLE DOUBLE-ENTRY LEDGER (WALLET)
-- ============================================

create type ledger_account_type as enum ('user', 'chauffeur', 'system', 'promo');

create table public.ledger_accounts (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade,
  type ledger_account_type not null,
  balance numeric(10,2) default 0.00 not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_user_account unique (user_id)
);

create table public.ledger_entries (
  id uuid default gen_random_uuid() primary key,
  transaction_id uuid references public.transactions on delete set null,
  from_account_id uuid references public.ledger_accounts(id) on delete restrict not null,
  to_account_id uuid references public.ledger_accounts(id) on delete restrict not null,
  amount numeric(10,2) not null check (amount > 0),
  description text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.ledger_accounts enable row level security;
alter table public.ledger_entries enable row level security;

-- Only service role can modify ledger
create policy "Service role manages ledger accounts." on public.ledger_accounts for all using (false);
create policy "Service role manages ledger entries." on public.ledger_entries for all using (false);

-- Users can read their own accounts and entries
create policy "Users read own ledger account." on public.ledger_accounts for select using (auth.uid() = user_id);
create policy "Users read own ledger entries." on public.ledger_entries for select using (
  auth.uid() in (
    select user_id from public.ledger_accounts where id = from_account_id or id = to_account_id
  )
);

-- ============================================
-- D. HIGH-FREQUENCY TELEMETRY DATA LAKE
-- ============================================

-- Append-only table for time-series driver tracking
create table public.driver_telemetry (
  id uuid default gen_random_uuid() primary key,
  driver_id uuid references public.users on delete cascade not null,
  ride_id uuid references public.rides on delete set null,
  location geography(point) not null,
  speed double precision,
  heading double precision,
  recorded_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.driver_telemetry enable row level security;

-- Chauffeurs can insert their own telemetry
create policy "Chauffeurs can insert telemetry." on public.driver_telemetry for insert with check (auth.uid() = driver_id);

-- System can read all telemetry
create policy "Service role reads telemetry." on public.driver_telemetry for select using (false);

-- Disable updates/deletes to ensure append-only
create policy "No updates to telemetry." on public.driver_telemetry for update using (false);
create policy "No deletes to telemetry." on public.driver_telemetry for delete using (false);
