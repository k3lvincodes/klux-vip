-- ==========================================================
-- AUTO-CANCEL UNMATCHED RIDES OLDER THAN 30 MINUTES
-- ==========================================================

-- 1. Function to auto-cancel any ride or ride_request that has remained
--    unmatched for more than 30 minutes from its creation or scheduled window.
CREATE OR REPLACE FUNCTION public.auto_cancel_stale_rides()
RETURNS integer AS $$
DECLARE
  v_cancelled_count integer := 0;
  v_count_requests integer := 0;
  v_count_rides integer := 0;
BEGIN
  -- A. Auto-cancel stale pending/requested in ride_requests
  WITH cancelled_reqs AS (
    UPDATE public.ride_requests
    SET 
      status = 'cancelled',
      passenger_note = CASE 
        WHEN passenger_note IS NOT NULL AND passenger_note NOT ILIKE '%Auto-cancelled%' THEN
          passenger_note || ' | Auto-cancelled: No chauffeur matched within 30 minutes'
        ELSE COALESCE(passenger_note, 'Auto-cancelled: No chauffeur matched within 30 minutes')
      END
    WHERE status IN ('pending', 'requested', 'searching')
      AND (
        -- Created over 30 minutes ago
        created_at < timezone('utc'::text, now()) - interval '30 minutes'
        -- Or explicit expiration passed
        OR (expires_at IS NOT NULL AND expires_at < timezone('utc'::text, now()))
        -- Or scheduled time passed by more than 30 mins with no chauffeur assigned
        OR (scheduled_time IS NOT NULL AND scheduled_time < timezone('utc'::text, now()) - interval '30 minutes')
      )
    RETURNING id
  )
  SELECT count(*) INTO v_count_requests FROM cancelled_reqs;

  -- B. Auto-cancel stale requested/pending in rides table without driver
  WITH cancelled_r AS (
    UPDATE public.rides
    SET 
      status = 'cancelled'::ride_status,
      cancelled_reason = 'Auto-cancelled: No chauffeur matched within 30 minutes',
      updated_at = timezone('utc'::text, now())
    WHERE status IN ('requested'::ride_status, 'pending'::ride_status)
      AND driver_id IS NULL
      AND (
        created_at < timezone('utc'::text, now()) - interval '30 minutes'
        OR (scheduled_pickup_time IS NOT NULL AND scheduled_pickup_time < timezone('utc'::text, now()) - interval '30 minutes')
      )
    RETURNING id
  )
  SELECT count(*) INTO v_count_rides FROM cancelled_r;

  v_cancelled_count := v_count_requests + v_count_rides;
  RETURN v_cancelled_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Callable RPC for clients or background jobs
CREATE OR REPLACE FUNCTION public.clean_stale_matching_rides()
RETURNS jsonb AS $$
DECLARE
  v_count integer;
BEGIN
  v_count := public.auto_cancel_stale_rides();
  RETURN jsonb_build_object(
    'success', true,
    'cancelled_stale_rides', v_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution to authenticated and anon users for cleanups
GRANT EXECUTE ON FUNCTION public.auto_cancel_stale_rides() TO authenticated, service_role, anon;
GRANT EXECUTE ON FUNCTION public.clean_stale_matching_rides() TO authenticated, service_role, anon;

-- 3. Execute immediately once to clean up all historical matching rides (e.g. from September)
SELECT public.auto_cancel_stale_rides();

-- 4. Ensure cron job runs every minute if pg_cron is enabled
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Unsched old job if exists
    PERFORM cron.unschedule('auto-cancel-stale-rides') WHERE EXISTS (
      SELECT 1 FROM cron.job WHERE jobname = 'auto-cancel-stale-rides'
    );
    -- Schedule refreshed job
    PERFORM cron.schedule(
      'auto-cancel-stale-rides',
      '* * * * *',
      'SELECT public.auto_cancel_stale_rides();'
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    NULL; -- Silently ignore if pg_cron permissions are restricted
END $$;

