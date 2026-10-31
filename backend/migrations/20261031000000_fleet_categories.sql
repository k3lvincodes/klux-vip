-- ========================================================
-- Migration: Add Fleet Categories (Business Class, Business Van, First Class)
-- ========================================================

-- 1. Add category column to fleet_cars catalog
ALTER TABLE public.fleet_cars ADD COLUMN IF NOT EXISTS category text DEFAULT 'Business Class';

-- 2. Add category column to vehicles table
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS category text DEFAULT 'Business Class';

-- 3. Auto-categorize existing fleet cars based on vehicle make and model
UPDATE public.fleet_cars
SET category = CASE
  WHEN lower(make || ' ' || model) ~* '(van|v-class|v class|vclass|vito|sprinter|transit|multivan|caravelle|metris|escalade|suburban|navigator)' THEN 'Business Van'
  WHEN lower(make || ' ' || model) ~* '(s-class|s class|sclass|maybach|7 series|7-series|750|760|i7|a8|s8|panamera|flying spur|phantom|ghost|rolls|bentley)' THEN 'First Class'
  ELSE 'Business Class'
END
WHERE category IS NULL OR category = 'Business Class';

-- 4. Create an index on fleet category for fast filtering
CREATE INDEX IF NOT EXISTS idx_fleet_cars_category ON public.fleet_cars(category) WHERE deleted_at IS NULL;
