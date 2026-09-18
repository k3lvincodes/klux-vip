-- ==========================================================
-- CANCEL RIDE RPC AND PASSENGER CANCEL POLICY
-- ==========================================================

CREATE OR REPLACE FUNCTION public.cancel_ride(
  p_ride_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS boolean AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_passenger_id uuid;
  v_driver_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Check ride_requests
  SELECT passenger_id INTO v_passenger_id
  FROM public.ride_requests
  WHERE id = p_ride_id;

  -- 2. Check rides if present
  IF NOT FOUND THEN
    SELECT passenger_id, driver_id INTO v_passenger_id, v_driver_id
    FROM public.rides
    WHERE id = p_ride_id;
  ELSE
    SELECT driver_id INTO v_driver_id
    FROM public.rides
    WHERE id = p_ride_id;
  END IF;

  -- Authorization check: user must be passenger, driver, or admin
  IF v_uid <> v_passenger_id AND (v_driver_id IS NULL OR v_uid <> v_driver_id) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized to cancel this ride';
  END IF;

  -- Update ride_requests
  UPDATE public.ride_requests
  SET status = 'cancelled',
      passenger_note = CASE 
        WHEN p_reason IS NOT NULL AND p_reason <> '' THEN 
          COALESCE(passenger_note || ' | ', '') || 'Cancelled: ' || p_reason 
        ELSE passenger_note 
      END
  WHERE id = p_ride_id;

  -- Update rides if exists
  UPDATE public.rides
  SET status = 'cancelled',
      cancelled_by = v_uid::text,
      cancelled_reason = p_reason,
      updated_at = timezone('utc'::text, now())
  WHERE id = p_ride_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure passengers and drivers can update rides when cancelling
DROP POLICY IF EXISTS "Clients can cancel their own rides" ON public.rides;
CREATE POLICY "Clients can cancel their own rides" 
  ON public.rides FOR UPDATE 
  USING (auth.uid() = passenger_id)
  WITH CHECK (auth.uid() = passenger_id);
