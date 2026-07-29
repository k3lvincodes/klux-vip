-- Stripe webhook event deduplication table
create table public.stripe_events (
  id uuid default gen_random_uuid() primary key,
  stripe_event_id text not null unique,
  type text not null,
  related_object text,
  status text default 'pending' not null,
  error text,
  processed_at timestamp with time zone,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.stripe_events enable row level security;

-- Only service role can manage stripe_events
create policy "Service role manages stripe_events" on public.stripe_events for all using (false);

-- Add stripe_transfer_id to transactions (for driver payout tracking)
alter table public.transactions add column if not exists stripe_transfer_id text;

-- Add stripe_connect_id to profiles (for driver Stripe Connect payouts)
alter table public.profiles add column if not exists stripe_connect_id text;

-- Add stripe_customer_id to profiles (for passenger Stripe customer reference)
alter table public.profiles add column if not exists stripe_customer_id text;

-- Prevent race condition: only one driver can be assigned to a non-completed/non-cancelled ride
create unique index if not exists idx_rides_single_driver on public.rides (id) where driver_id is not null and status not in ('completed', 'cancelled');

-- Add transaction_status values for deferred capture flow
do $$
begin
  if not exists (select 1 from pg_enum where enumtypid = 'transaction_status'::regtype and enumlabel = 'requires_action') then
    alter type transaction_status add value 'requires_action';
  end if;
  if not exists (select 1 from pg_enum where enumtypid = 'transaction_status'::regtype and enumlabel = 'authorized') then
    alter type transaction_status add value 'authorized';
  end if;
  if not exists (select 1 from pg_enum where enumtypid = 'transaction_status'::regtype and enumlabel = 'cancelled') then
    alter type transaction_status add value 'cancelled';
  end if;
end;
$$;
