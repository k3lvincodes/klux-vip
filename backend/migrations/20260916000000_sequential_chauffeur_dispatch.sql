-- ==========================================================
-- SEQUENTIAL CHAUFFEUR DISPATCH SYSTEM (CAR-SPECIFIC)
-- ==========================================================

-- 1. Add dispatch columns to public.ride_requests if not present
ALTER TABLE public.ride_requests 
  ADD COLUMN IF NOT EXISTS vehicle_type text,
  ADD COLUMN IF NOT EXISTS target_driver_id uuid REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS dispatched_at timestamptz,
  ADD COLUMN IF NOT EXISTS dispatch_expires_at timestamptz,
  ADD COLUMN IF NOT EXISTS declined_driver_ids uuid[] DEFAULT '{}'::uuid[],
  ADD COLUMN IF NOT EXISTS expires_at timestamptz DEFAULT (timezone('utc'::text, now()) + interval '30 minutes');

-- Ensure index for fast query on targeted pending requests
CREATE INDEX IF NOT EXISTS idx_ride_requests_target_pending 
  ON public.ride_requests(status, target_driver_id) 
  WHERE status = 'pending';

-- 2. Find eligible chauffeurs with active matching vehicle
CREATE OR REPLACE FUNCTION public.find_eligible_chauffeurs_for_vehicle(
  p_vehicle_type text,
  p_pickup_lat double precision DEFAULT NULL,
  p_pickup_lng double precision DEFAULT NULL,
  p_radius_meters double precision DEFAULT 50000
)
RETURNS TABLE (
  driver_id uuid,
  first_name text,
  last_name text,
  avatar_url text,
  phone text,
  rating numeric(3,2),
  trips_count integer,
  vehicle_name text,
  license_plate text,
  vehicle_color text,
  distance_meters double precision
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS driver_id,
    p.first_name,
    p.last_name,
    p.avatar_url,
    p.phone,
    COALESCE(dd.rating, 5.00)::numeric(3,2) AS rating,
    COALESCE(dd.total_rides, 0)::integer AS trips_count,
    TRIM(CONCAT(v.year::text, ' ', v.make, ' ', v.model)) AS vehicle_name,
    v.license_plate,
    v.color AS vehicle_color,
    CASE 
      WHEN p_pickup_lat IS NOT NULL AND p_pickup_lng IS NOT NULL AND dd.last_location IS NOT NULL THEN
        ST_Distance(
          dd.last_location::geography,
          ST_SetSRID(ST_MakePoint(p_pickup_lng, p_pickup_lat), 4326)::geography
        )
      ELSE 0.0
    END AS distance_meters
  FROM public.profiles p
  INNER JOIN public.driver_details dd ON dd.profile_id = p.id
  INNER JOIN public.vehicles v ON v.driver_id = p.id AND v.is_active = true
  WHERE p.role = 'chauffeur'
    AND p.deleted_at IS NULL
    AND dd.status = 'approved'
    AND (
      p_vehicle_type IS NULL 
      OR p_vehicle_type = ''
      OR v.model ILIKE '%' || p_vehicle_type || '%'
      OR v.make ILIKE '%' || p_vehicle_type || '%'
      OR (v.fleet_car_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.fleet_cars fc 
          WHERE fc.id = v.fleet_car_id 
            AND (fc.model ILIKE '%' || p_vehicle_type || '%' OR fc.make ILIKE '%' || p_vehicle_type || '%')
        ))
    )
    AND (
      p_pickup_lat IS NULL 
      OR p_pickup_lng IS NULL 
      OR dd.last_location IS NULL 
      OR ST_DWithin(
        dd.last_location::geography,
        ST_SetSRID(ST_MakePoint(p_pickup_lng, p_pickup_lat), 4326)::geography,
        p_radius_meters
      )
    )
  ORDER BY 
    dd.is_online DESC,
    distance_meters ASC,
    rating DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Rotate dispatch to next available chauffeur (2-min rotation, 30-min auto-cancel)
CREATE OR REPLACE FUNCTION public.dispatch_next_chauffeur(
  p_ride_request_id uuid
)
RETURNS jsonb AS $$
DECLARE
  v_req record;
  v_next_driver record;
  v_declined uuid[];
BEGIN
  -- Fetch current pending ride request
  SELECT * INTO v_req 
  FROM public.ride_requests
  WHERE id = p_ride_request_id AND status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Ride request not found or not pending');
  END IF;

  -- Check if 30-minute overall window has expired
  IF v_req.expires_at IS NOT NULL AND now() >= v_req.expires_at THEN
    UPDATE public.ride_requests
    SET status = 'cancelled'
    WHERE id = p_ride_request_id;

    RETURN jsonb_build_object(
      'success', false, 
      'status', 'cancelled', 
      'message', 'Ride cancelled: No chauffeur accepted within 30 minutes.'
    );
  END IF;

  -- Accumulate current target into declined list if present
  v_declined := COALESCE(v_req.declined_driver_ids, '{}'::uuid[]);
  IF v_req.target_driver_id IS NOT NULL AND NOT (v_req.target_driver_id = ANY(v_declined)) THEN
    v_declined := array_append(v_declined, v_req.target_driver_id);
  END IF;

  -- Find next eligible chauffeur with matching vehicle not in declined list
  SELECT driver_id, first_name, last_name, vehicle_name, license_plate
  INTO v_next_driver
  FROM public.find_eligible_chauffeurs_for_vehicle(
    v_req.vehicle_type,
    ST_Y(v_req.pickup_location::geometry),
    ST_X(v_req.pickup_location::geometry),
    50000
  )
  WHERE NOT (driver_id = ANY(v_declined))
  LIMIT 1;

  IF NOT FOUND THEN
    -- If no more drivers remain and at least 30 minutes have passed or no driver exists
    IF now() >= v_req.expires_at THEN
      UPDATE public.ride_requests
      SET status = 'cancelled', declined_driver_ids = v_declined
      WHERE id = p_ride_request_id;

      RETURN jsonb_build_object('success', false, 'status', 'cancelled', 'message', 'No chauffeurs available.');
    ELSE
      -- Reset declined pool to loop through online chauffeurs again if within 30 mins
      v_declined := '{}'::uuid[];
      SELECT driver_id, first_name, last_name, vehicle_name, license_plate
      INTO v_next_driver
      FROM public.find_eligible_chauffeurs_for_vehicle(
        v_req.vehicle_type,
        ST_Y(v_req.pickup_location::geometry),
        ST_X(v_req.pickup_location::geometry),
        50000
      )
      LIMIT 1;
    END IF;
  END IF;

  IF v_next_driver.driver_id IS NOT NULL THEN
    UPDATE public.ride_requests
    SET 
      target_driver_id = v_next_driver.driver_id,
      dispatched_at = timezone('utc'::text, now()),
      dispatch_expires_at = timezone('utc'::text, now()) + interval '2 minutes',
      declined_driver_ids = v_declined
    WHERE id = p_ride_request_id;

    -- Insert notification for targeted driver
    INSERT INTO public.notifications (user_id, type, title, body, data)
    VALUES (
      v_next_driver.driver_id,
      'ride_request',
      'New Executive Booking Request',
      'A new reservation matching your vehicle is waiting for your acceptance (2 min window).',
      jsonb_build_object(
        'ride_request_id', p_ride_request_id,
        'pickup_address', v_req.pickup_address,
        'dropoff_address', v_req.dropoff_address,
        'fare_amount', v_req.fare_amount,
        'expires_at', timezone('utc'::text, now()) + interval '2 minutes'
      )
    );

    RETURN jsonb_build_object(
      'success', true,
      'status', 'dispatched',
      'target_driver_id', v_next_driver.driver_id,
      'target_driver_name', v_next_driver.first_name || ' ' || v_next_driver.last_name,
      'vehicle_name', v_next_driver.vehicle_name,
      'dispatch_expires_at', timezone('utc'::text, now()) + interval '2 minutes'
    );
  ELSE
    UPDATE public.ride_requests
    SET status = 'cancelled', declined_driver_ids = v_declined
    WHERE id = p_ride_request_id;

    RETURN jsonb_build_object('success', false, 'status', 'cancelled', 'message', 'No active chauffeurs found for this vehicle tier.');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Sync policy: ensure drivers only receive ride requests targeted to them or broadcast
DROP POLICY IF EXISTS "Ride requests are viewable by all" ON public.ride_requests;
DROP POLICY IF EXISTS "Ride requests are viewable by target driver or creator" ON public.ride_requests;
CREATE POLICY "Ride requests are viewable by target driver or creator"
  ON public.ride_requests FOR SELECT
  USING (
    target_driver_id IS NULL 
    OR target_driver_id = auth.uid() 
    OR passenger_id = auth.uid()
    OR auth.role() = 'authenticated'
  );

