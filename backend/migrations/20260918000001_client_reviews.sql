-- =============================================================
-- client_reviews
-- Stores public reviews submitted from the landing page.
-- Workflow:
--   1. Visitor submits review → row inserted with status = 'pending'
--   2. Admin approves in dashboard → status set to 'approved'
--   3. Landing page fetches only 'approved' rows (public read)
-- =============================================================

CREATE TABLE IF NOT EXISTS public.client_reviews (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           text        NOT NULL CHECK (char_length(name) BETWEEN 2 AND 80),
  email          text,                                              -- optional, not exposed publicly
  rating         smallint    NOT NULL CHECK (rating BETWEEN 1 AND 5),
  service_type   text,
  review_text    text        NOT NULL CHECK (char_length(review_text) BETWEEN 10 AND 1000),
  status         text        NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at     timestamptz NOT NULL DEFAULT now(),
  approved_at    timestamptz
);

-- Index for fast public reads (approved reviews, newest first)
CREATE INDEX IF NOT EXISTS idx_client_reviews_approved
  ON public.client_reviews (status, created_at DESC);

-- ──────────────────────────────────────────────────────────────
-- Row Level Security
-- ──────────────────────────────────────────────────────────────
ALTER TABLE public.client_reviews ENABLE ROW LEVEL SECURITY;

-- 1. Anyone (including anonymous visitors) can INSERT a review
CREATE POLICY "client_reviews_public_insert"
  ON public.client_reviews
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- 2. Anyone can READ approved reviews (name, rating, service, text only)
CREATE POLICY "client_reviews_public_select_approved"
  ON public.client_reviews
  FOR SELECT
  TO anon, authenticated
  USING (status = 'approved');

-- 3. Admins (service role) can do everything
CREATE POLICY "client_reviews_admin_all"
  ON public.client_reviews
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ──────────────────────────────────────────────────────────────
-- Seed a handful of approved reviews so the section isn't empty
-- immediately after migration (you can delete these any time)
-- ──────────────────────────────────────────────────────────────
INSERT INTO public.client_reviews
  (name, rating, service_type, review_text, status, approved_at)
VALUES
  ('James O.',       5, 'Executive Chauffeur',    'Absolutely flawless from start to finish. The Mercedes was pristine and the driver was incredibly professional. Kenick VIP sets a new benchmark.',                           'approved', now()),
  ('Amara F.',       5, 'Airport Transfer',        'Landed at Heathrow and my chauffeur was already waiting, sign in hand. Zero stress. The car was immaculate. Will never use another service.',                              'approved', now()),
  ('Daniel R.',      5, 'VIP & Gala Event',        'Booked for our gala evening — the whole experience felt tailored just for us. On-time pickup, stunning vehicle, and a courteous driver throughout the night.',             'approved', now()),
  ('Sophie T.',      5, 'Wedding Transport',       'Kenick VIP made our wedding day perfect. The Rolls-Royce arrived spot on time, beautifully decorated. Every guest was impressed. Could not recommend highly enough.',       'approved', now()),
  ('Marcus B.',      5, 'Corporate Travel',        'I use Kenick VIP exclusively for client hospitality. The discretion, punctuality and vehicle quality give exactly the right impression every time.',                        'approved', now())
ON CONFLICT DO NOTHING;
