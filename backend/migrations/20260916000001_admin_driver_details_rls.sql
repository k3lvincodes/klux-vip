-- ==========================================================
-- Allow Admins to insert/upsert into driver_details
-- ==========================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'driver_details' 
      AND policyname = 'Admins can insert all chauffeur details.'
  ) THEN
    CREATE POLICY "Admins can insert all chauffeur details." 
      ON public.driver_details 
      FOR INSERT 
      WITH CHECK (public.is_admin());
  END IF;
END $$;

-- Dedicated RPC function for admins to approve/suspend chauffeurs
CREATE OR REPLACE FUNCTION public.admin_set_driver_status(
  p_driver_id uuid,
  p_status text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Super admin privileges required';
  END IF;

  -- Upsert into driver_details
  INSERT INTO public.driver_details (
    profile_id,
    status,
    verification_status,
    updated_at
  )
  VALUES (
    p_driver_id,
    p_status::profile_status,
    CASE WHEN p_status = 'approved' THEN 'approved' ELSE 'rejected' END,
    now()
  )
  ON CONFLICT (profile_id) DO UPDATE
  SET 
    status = EXCLUDED.status,
    verification_status = EXCLUDED.verification_status,
    updated_at = EXCLUDED.updated_at;

  -- Keep profiles verification_status synchronized
  UPDATE public.profiles
  SET 
    verification_status = CASE WHEN p_status = 'approved' THEN 'approved' ELSE 'rejected' END,
    updated_at = now()
  WHERE id = p_driver_id;

  RETURN json_build_object('success', true, 'status', p_status);
END;
$$;
