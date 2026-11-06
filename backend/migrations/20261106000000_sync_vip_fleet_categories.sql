-- =========================================================================
-- Migration: Sync VIP Fleet Categories (Sedans, SUVs, Vans, Buses)
-- Enforces clean database persistence and ensures categories match app tiers
-- =========================================================================

-- 1. Ensure category column exists on fleet_cars with 'None' default
ALTER TABLE public.fleet_cars ADD COLUMN IF NOT EXISTS category text DEFAULT 'None';

-- 2. Update existing fleet cars to standard Kenick VIP categories
-- (Buses, Vans, SUVs, Sedans)
UPDATE public.fleet_cars
SET category = CASE
  -- 1. Buses: minibuses, coaches, 14+ seaters
  WHEN lower(make || ' ' || model) ~* '(bus|minibus|coach|coaster|rosa|tourliner|setra|sprinter 1[4-9]|sprinter 20|transit 1[4-5]|crafter 16)' THEN 'Buses'

  -- 2. Vans: executive vans, MPVs, standard sprinters
  WHEN lower(make || ' ' || model) ~* '(van|v-class|v class|vclass|vito|sprinter|transit|multivan|caravelle|metris|alphard|vellfire|carnival|sienna|odyssey|pacifica|transporter)' THEN 'Vans'

  -- 3. SUVs: luxury & full-size SUVs
  WHEN lower(make || ' ' || model) ~* '(suv|escalade|suburban|yukon|tahoe|navigator|expedition|gle|gls|g-class|g class|g-wagon|gwagon|x5|x7|q7|q8|cayenne|urus|cullinan|bentayga|range rover|land rover|defender|discovery|lx 600|lx 570|gx|sequoia|cherokee|patrol|land cruiser|armada|telluride|palisade|aviator)' THEN 'SUVs'

  -- 4. Sedans: executive sedans, flagships, and default luxury cars
  ELSE 'Sedans'
END
WHERE deleted_at IS NULL
  AND (category IS NULL OR category = 'None' OR category = 'Business Class' OR category = 'First Class' OR category = 'Business Van');

-- 3. Re-verify index on fleet category for fast filtering
CREATE INDEX IF NOT EXISTS idx_fleet_cars_category ON public.fleet_cars(category) WHERE deleted_at IS NULL;

-- 4. Verify RLS permissions for public view and admin management
ALTER TABLE public.fleet_cars ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Fleet cars are viewable by everyone." ON public.fleet_cars;
CREATE POLICY "Fleet cars are viewable by everyone."
  ON public.fleet_cars FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Admins can manage fleet cars." ON public.fleet_cars;
CREATE POLICY "Admins can manage fleet cars."
  ON public.fleet_cars FOR ALL USING (public.is_admin());

