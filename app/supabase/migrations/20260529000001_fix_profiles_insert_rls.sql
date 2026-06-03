-- Fix: Add INSERT policy for profiles so client upserts work on first use.
-- The existing UPDATE/SELECT policies on profiles were created in 
-- 20260525000000_execute_db_proposal.sql, but INSERT was omitted.
-- This caused upserts to fail with "new row violates row-level security"
-- because PostgREST checks INSERT permission even during upsert.
-- Same root cause as the 20260526000000_fix_driver_details_insert_rls fix.

create policy "Users can insert own profile."
  on public.profiles
  for insert
  with check (auth.uid() = id);
