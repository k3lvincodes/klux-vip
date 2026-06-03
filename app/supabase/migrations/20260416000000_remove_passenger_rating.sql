-- Remove rating from client profiles
ALTER TABLE public.passenger_profiles
DROP COLUMN IF EXISTS rating;
