-- Add client_note to rides table
ALTER TABLE public.rides
ADD COLUMN passenger_note text;
