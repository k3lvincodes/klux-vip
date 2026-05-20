-- Enable PostGIS extension for geographic data types
create extension if not exists postgis schema extensions;

-- Create Enums
create type user_role as enum ('passenger', 'driver');
create type profile_status as enum ('pending', 'approved', 'suspended');
create type ride_status as enum ('requested', 'accepted', 'arriving', 'in_progress', 'completed', 'cancelled');
create type booking_type as enum ('instant', 'scheduled', 'special');
create type payment_type as enum ('card', 'bank_account');
create type transaction_type as enum ('ride_payment', 'withdrawal');
create type transaction_status as enum ('pending', 'completed', 'failed');

-- Table: users (Extended profile for Supabase Auth auth.users)
create table public.users (
  id uuid references auth.users on delete cascade primary key,
  role user_role not null,
  phone_number text unique,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table: driver_profiles
create table public.driver_profiles (
  user_id uuid references public.users on delete cascade primary key,
  first_name text not null,
  last_name text not null,
  selfie_url text,
  status profile_status default 'pending'::profile_status not null,
  is_online boolean default false not null,
  current_location geography(point),
  rating numeric(3,2) default 5.00
);

-- Table: passenger_profiles
create table public.passenger_profiles (
  user_id uuid references public.users on delete cascade primary key,
  first_name text not null,
  last_name text not null
);

-- Table: rides
create table public.rides (
  id uuid default gen_random_uuid() primary key,
  passenger_id uuid references public.users on delete restrict not null,
  driver_id uuid references public.users on delete restrict,
  pickup_location geography(point) not null,
  pickup_address text not null,
  dropoff_location geography(point) not null,
  dropoff_address text not null,
  status ride_status default 'requested'::ride_status not null,
  type booking_type default 'instant'::booking_type not null,
  scheduled_time timestamp with time zone,
  fare_amount numeric(10,2) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Table: payment_methods
create table public.payment_methods (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  provider_token text not null,
  type payment_type not null,
  last4 text
);

-- Table: transactions
create table public.transactions (
  id uuid default gen_random_uuid() primary key,
  ride_id uuid references public.rides on delete set null,
  user_id uuid references public.users on delete cascade not null,
  amount numeric(10,2) not null,
  type transaction_type not null,
  status transaction_status default 'pending'::transaction_status not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.users enable row level security;
alter table public.driver_profiles enable row level security;
alter table public.passenger_profiles enable row level security;
alter table public.rides enable row level security;
alter table public.payment_methods enable row level security;
alter table public.transactions enable row level security;

-- Basic RLS Policies

-- Users: can read and update their own record
create policy "Users can view own profile." on public.users for select using (auth.uid() = id);
create policy "Users can update own profile." on public.users for update using (auth.uid() = id);

-- Driver Profiles: Publicly viewable for matchmaking, updateable by driver
create policy "Driver profiles are viewable by everyone." on public.driver_profiles for select using (true);
create policy "Drivers can insert their own profile." on public.driver_profiles for insert with check (auth.uid() = user_id);
create policy "Drivers can update their own profile." on public.driver_profiles for update using (auth.uid() = user_id);

-- Passenger Profiles: Updateable by passenger
create policy "Passenger profiles viewable by everyone." on public.passenger_profiles for select using (true);
create policy "Passengers can insert their own profile." on public.passenger_profiles for insert with check (auth.uid() = user_id);
create policy "Passengers can update their own profile." on public.passenger_profiles for update using (auth.uid() = user_id);

-- Rides: Passengers and drivers can see their own rides
create policy "Passengers can view their rides." on public.rides for select using (auth.uid() = passenger_id);
create policy "Drivers can view their assigned rides." on public.rides for select using (auth.uid() = driver_id);
create policy "Drivers can see requested rides." on public.rides for select using (status = 'requested');

create policy "Passengers can insert rides." on public.rides for insert with check (auth.uid() = passenger_id);
create policy "Passengers can update their unassigned rides." on public.rides for update using (auth.uid() = passenger_id and driver_id is null);
create policy "Drivers can accept and update their assigned rides." on public.rides for update using (auth.uid() = driver_id or driver_id is null);

-- Function and Trigger to automatically create a user record on Auth Signup
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.users (id, role)
  values (new.id, 'passenger'); -- Default role, can be updated during onboarding
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger for rides updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger on_ride_updated
  before update on public.rides
  for each row execute procedure public.handle_updated_at();

-- Enable Realtime for requested tables
alter publication supabase_realtime add table public.rides;
alter publication supabase_realtime add table public.driver_profiles;
