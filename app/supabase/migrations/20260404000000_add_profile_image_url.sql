-- Add profile_image_url column to passenger_profiles
alter table public.passenger_profiles
  add column if not exists profile_image_url text;

-- Add profile_image_url column to driver_profiles
alter table public.driver_profiles
  add column if not exists profile_image_url text;
