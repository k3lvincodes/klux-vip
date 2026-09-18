-- ==========================================================
-- Allow users and admins to update notifications (mark as read)
-- ==========================================================

DO $$
BEGIN
  -- 1. Policy for users to update their own notifications
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'notifications' 
      AND policyname = 'Users can update own notifications.'
  ) THEN
    CREATE POLICY "Users can update own notifications." 
      ON public.notifications 
      FOR UPDATE 
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;

  -- 2. Policy for admins to update all notifications
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'notifications' 
      AND policyname = 'Admins can update all notifications.'
  ) THEN
    CREATE POLICY "Admins can update all notifications." 
      ON public.notifications 
      FOR UPDATE 
      USING (public.is_admin());
  END IF;
END $$;

-- Dedicated RPC functions to guarantee marking notifications as read
CREATE OR REPLACE FUNCTION public.mark_notification_read(p_notification_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.notifications
  SET is_read = true
  WHERE id = p_notification_id
    AND (user_id = auth.uid() OR public.is_admin());
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.notifications
  SET is_read = true
  WHERE user_id = auth.uid()
    AND is_read = false;
END;
$$;
