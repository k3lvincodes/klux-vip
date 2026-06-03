-- Fix: Add INSERT policy for driver_details so chauffeur upserts work on first use.
-- The previous migration created UPDATE/SELECT policies but omitted INSERT,
-- which caused upserts to fail when no row existed yet.

create policy "Chauffeurs can insert own details."
  on public.driver_details
  for insert
  with check (auth.uid() = profile_id);
