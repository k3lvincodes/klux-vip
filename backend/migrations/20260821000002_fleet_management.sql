-- ============================================
-- FLEET MANAGEMENT SYSTEM
-- ============================================

-- 1. Fleet cars catalog (admin-managed)
create table if not exists public.fleet_cars (
  id            uuid          default gen_random_uuid() primary key,
  make          text          not null,
  model         text          not null,
  year          integer       not null,
  image_url     text,
  features      text          default '',
  is_available  boolean       default true not null,
  is_featured   boolean       default false not null,
  created_at    timestamptz   default timezone('utc', now()) not null,
  updated_at    timestamptz   default timezone('utc', now()) not null,
  deleted_at    timestamptz,

  constraint valid_fleet_year check (year between 2000 and extract(year from now()) + 1)
);

-- Handle existing table: add features, remove license_plate
ALTER TABLE public.fleet_cars ADD COLUMN IF NOT EXISTS features text DEFAULT '';
ALTER TABLE public.fleet_cars DROP COLUMN IF EXISTS license_plate;

-- 2. Vehicle requests (chauffeur -> admin approval)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'vehicle_request_status') THEN
    CREATE TYPE vehicle_request_status AS ENUM ('pending', 'approved', 'rejected');
  END IF;
END $$;

create table if not exists public.vehicle_requests (
  id            uuid                    default gen_random_uuid() primary key,
  chauffeur_id  uuid                    references public.profiles on delete cascade not null,
  make          text                    not null,
  model         text                    not null,
  year          integer                 not null,
  color         text                    not null,
  license_plate text                    not null,
  images        text[]                  default '{}' not null,
  status        vehicle_request_status  default 'pending' not null,
  admin_note    text,
  reviewed_by   uuid                    references public.profiles(id),
  reviewed_at   timestamptz,
  created_at    timestamptz             default timezone('utc', now()) not null,
  updated_at    timestamptz             default timezone('utc', now()) not null,

  constraint valid_request_year check (year between 2000 and extract(year from now()) + 1)
);

-- 3. Add fleet_car_id to vehicles (nullable, links to fleet car if assigned from fleet)
ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS fleet_car_id uuid REFERENCES public.fleet_cars(id);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_fleet_cars_available ON public.fleet_cars(is_available) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_fleet_cars_featured ON public.fleet_cars(is_featured) WHERE deleted_at IS NULL AND is_featured = true;
CREATE INDEX IF NOT EXISTS idx_vehicle_requests_status ON public.vehicle_requests(status);
CREATE INDEX IF NOT EXISTS idx_vehicle_requests_chauffeur ON public.vehicle_requests(chauffeur_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_fleet_car ON public.vehicles(fleet_car_id) WHERE fleet_car_id IS NOT NULL;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Fleet cars
ALTER TABLE public.fleet_cars ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Fleet cars are viewable by everyone." ON public.fleet_cars;
  DROP POLICY IF EXISTS "Admins can manage fleet cars." ON public.fleet_cars;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE POLICY "Fleet cars are viewable by everyone."
  ON public.fleet_cars FOR SELECT USING (TRUE);

CREATE POLICY "Admins can manage fleet cars."
  ON public.fleet_cars FOR ALL USING (public.is_admin());

-- Vehicle requests
ALTER TABLE public.vehicle_requests ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "Chauffeurs can view own requests." ON public.vehicle_requests;
  DROP POLICY IF EXISTS "Chauffeurs can insert own requests." ON public.vehicle_requests;
  DROP POLICY IF EXISTS "Admins can view all requests." ON public.vehicle_requests;
  DROP POLICY IF EXISTS "Admins can update all requests." ON public.vehicle_requests;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE POLICY "Chauffeurs can view own requests."
  ON public.vehicle_requests FOR SELECT USING (auth.uid() = chauffeur_id);

CREATE POLICY "Chauffeurs can insert own requests."
  ON public.vehicle_requests FOR INSERT WITH CHECK (auth.uid() = chauffeur_id);

CREATE POLICY "Admins can view all requests."
  ON public.vehicle_requests FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can update all requests."
  ON public.vehicle_requests FOR UPDATE USING (public.is_admin());

-- ============================================
-- TRIGGERS
-- ============================================

DO $$ BEGIN
  DROP TRIGGER IF EXISTS handle_fleet_cars_updated_at ON public.fleet_cars;
  DROP TRIGGER IF EXISTS handle_vehicle_requests_updated_at ON public.vehicle_requests;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE TRIGGER handle_fleet_cars_updated_at
  BEFORE UPDATE ON public.fleet_cars
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER handle_vehicle_requests_updated_at
  BEFORE UPDATE ON public.vehicle_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
