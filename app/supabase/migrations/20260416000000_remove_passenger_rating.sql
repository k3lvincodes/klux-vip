-- Remove rating from passenger profiles
ALTER TABLE public.passenger_profiles
DROP COLUMN IF EXISTS rating;
