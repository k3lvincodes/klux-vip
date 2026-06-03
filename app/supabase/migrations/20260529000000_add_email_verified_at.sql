-- Add email_verified_at column to profiles to track OTP verification
alter table public.profiles
  add column if not exists email_verified_at timestamp with time zone;
