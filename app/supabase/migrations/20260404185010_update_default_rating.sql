-- Update default rating from 5.00 to 0.00 for newly created profiles

-- Driver profiles
ALTER TABLE public.driver_profiles 
ALTER COLUMN rating SET DEFAULT 0.00;

