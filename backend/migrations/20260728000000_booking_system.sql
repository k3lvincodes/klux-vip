-- ============================================
-- BOOKING SYSTEM MIGRATION
-- Adds tip_amount to rides, invoices table,
-- RLS policies, and invoice number generator.
-- ============================================

begin;

-- ============================================
-- 1. ADD TIP AMOUNT TO RIDES
-- ============================================

alter table public.rides
  add column if not exists tip_amount numeric(10,2) default 0;

-- ============================================
-- 2. INVOICES TABLE
-- ============================================

create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  ride_id uuid references public.rides on delete cascade not null,
  user_id uuid references public.profiles on delete cascade not null,
  invoice_number text unique not null,
  base_fare numeric(10,2) not null,
  tip_amount numeric(10,2) default 0,
  tax_amount numeric(10,2) default 0,
  total_amount numeric(10,2) not null,
  pickup_address text not null,
  dropoff_address text not null,
  vehicle_type text,
  trip_date timestamp with time zone,
  payment_method_last4 text,
  payment_status text default 'paid',
  booking_confirmation text unique not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ============================================
-- 3. RLS POLICIES FOR INVOICES
-- ============================================

alter table public.invoices enable row level security;

-- Users can view their own invoices
create policy "Users can view their own invoices."
  on public.invoices for select
  using (auth.uid() = user_id);

-- Admins can view all invoices
create policy "Admins can view all invoices."
  on public.invoices for select
  using (public.is_admin());

-- Insert only by service role (no direct user insert)
create policy "No direct insert on invoices."
  on public.invoices for insert
  with check (false);

-- ============================================
-- 4. INVOICE NUMBER GENERATOR FUNCTION
-- ============================================

create or replace function public.generate_invoice_number()
returns text as $$
declare
  date_part text;
  random_part text;
  result text;
  max_attempts integer := 10;
  attempt integer := 0;
begin
  date_part := to_char(now(), 'YYYYMMDD');

  loop
    random_part := upper(substr(md5(random()::text), 1, 4));
    result := 'KLX-' || date_part || '-' || random_part;

    exit when not exists (
      select 1 from public.invoices where invoice_number = result
    );

    attempt := attempt + 1;
    exit when attempt >= max_attempts;
  end loop;

  return result;
end;
$$ language plpgsql security definer;

-- ============================================
-- 5. BOOKING CONFIRMATION GENERATOR
-- ============================================

create or replace function public.generate_booking_confirmation()
returns text as $$
declare
  result text;
  max_attempts integer := 10;
  attempt integer := 0;
begin
  loop
    result := 'BK-' || upper(substr(md5(random()::text), 1, 6));

    exit when not exists (
      select 1 from public.invoices where booking_confirmation = result
    );

    attempt := attempt + 1;
    exit when attempt >= max_attempts;
  end loop;

  return result;
end;
$$ language plpgsql security definer;

commit;
