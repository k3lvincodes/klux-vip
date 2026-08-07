-- ============================================
-- Admin bug fixes
-- 1. payment_methods had RLS enabled with zero policies,
--    so it was unreadable by everyone (incl. admins) once columns were
--    queried correctly. Add the missing policies.
-- ============================================
create policy "Users can view own payment methods." on public.payment_methods
  for select using (auth.uid() = user_id and deleted_at is null);

create policy "Users can insert own payment methods." on public.payment_methods
  for insert with check (auth.uid() = user_id);

create policy "TEUsers can update own payment methods." on public.payment_methods
  for update using (auth.uid() = user_id and deleted_at is null)
  with check (auth.uid() = user_id);

create policy "Admins can view all payment methods." on public.payment_methods
  for select using (public.is_admin());

create policy "Admins can update all payment methods." on public.payment_methods
  for update using (public.is_admin());

-- ============================================
-- 2. fare_rates.per_km_rate is NOT NULL with no default, so every admin
--    insert that omitted it failed (HTTP 400). Give it a sane default.
-- ============================================
alter table public.fare_rates alter column per_km_rate set default 1.85;

-- ============================================
-- 3. Seed base fare rates for the countries the admin Pricing page shows by
--    default. The app reads per_km_rate / base_fare / per_minute_rate for
--    fare estimation (see app/lib/services/fare_rate_service.dart); without
--    rows it falls back to hardcoded defaults.
-- ============================================
insert into public.fare_rates (country_code, state_or_region, per_km_rate, base_fare, per_minute_rate, vip_amount)
values
  ('us', null, 1.85, 3.50, 0.45, 0),
  ('gb', null, 1.85, 3.50, 0.45, 0),
  ('ca', null, 1.85, 3.50, 0.45, 0),
  ('au', null, 1.85, 3.50, 0.45, 0),
  ('ng', null, 1.85, 3.50, 0.45, 0),
  ('br', null, 1.85, 3.50, 0.45, 0)
on conflict (country_code, state_or_region) do nothing;
