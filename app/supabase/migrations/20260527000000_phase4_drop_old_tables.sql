-- Phase 4: Drop Old Tables
-- Removes users, driver_profiles, passenger_profiles, and ride_batch_queue
-- after verifying no code references them.

-- ============================================
-- 1. UPDATE AUTH TRIGGER
-- ============================================
-- Stop writing to the old users table; profiles is the source of truth.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, role)
  values (new.id, coalesce(new.email, ''), 'client');
  return new;
end;
$$ language plpgsql security definer;

-- ============================================
-- 2. DROP FOREIGN KEY CONSTRAINTS
-- ============================================
-- Drop all FK constraints referencing public.users before dropping the table.
do $$
declare
  rec record;
begin
  for rec in (
    select conname, conrelid::regclass as table_name
    from pg_constraint
    where confrelid = 'public.users'::regclass
      and contype = 'f'
  ) loop
    execute format('alter table %s drop constraint %I', rec.table_name, rec.conname);
  end loop;
end $$;

-- ============================================
-- 3. DROP OLD TABLES
-- ============================================
drop table if exists public.passenger_profiles;
drop table if exists public.driver_profiles;
drop table if exists public.users;
drop table if exists public.ride_batch_queue;

-- ============================================
-- 4. RE-ADD FOREIGN KEY CONSTRAINTS
-- ============================================
-- Re-point all FKs to public.profiles which has the same IDs (both reference auth.users).

-- Rides
alter table public.rides add constraint rides_passenger_id_fkey
  foreign key (passenger_id) references public.profiles(id) on delete restrict;
alter table public.rides add constraint rides_driver_id_fkey
  foreign key (driver_id) references public.profiles(id) on delete restrict;

-- Vehicles
alter table public.vehicles add constraint vehicles_driver_id_fkey
  foreign key (driver_id) references public.profiles(id) on delete cascade;

-- Reviews
alter table public.reviews add constraint reviews_reviewer_id_fkey
  foreign key (reviewer_id) references public.profiles(id) on delete cascade;
alter table public.reviews add constraint reviews_reviewee_id_fkey
  foreign key (reviewee_id) references public.profiles(id) on delete cascade;

-- Support tickets
alter table public.support_tickets add constraint support_tickets_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;

-- Driver documents
alter table public.driver_documents add constraint driver_documents_driver_id_fkey
  foreign key (driver_id) references public.profiles(id) on delete cascade;

-- User devices
alter table public.user_devices add constraint user_devices_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;

-- Notifications
alter table public.notifications add constraint notifications_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;

-- Device biometrics
alter table public.device_biometrics add constraint device_biometrics_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;

-- Transactions
alter table public.transactions add constraint transactions_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;

-- Payment methods
alter table public.payment_methods add constraint payment_methods_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;

-- Ledger accounts
alter table public.ledger_accounts add constraint ledger_accounts_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;

-- Driver telemetry
alter table public.driver_telemetry add constraint driver_telemetry_driver_id_fkey
  foreign key (driver_id) references public.profiles(id) on delete cascade;

-- ============================================
-- 5. DROP OLD RLS POLICIES ON DROPPED TABLES
-- ============================================
-- The policies were dropped automatically when the tables were dropped.
