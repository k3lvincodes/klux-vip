CREATE TABLE fare_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code VARCHAR(2) NOT NULL,
  state_or_region VARCHAR(100),
  per_km_rate NUMERIC(10, 2) NOT NULL,
  base_fare NUMERIC(10, 2) NOT NULL DEFAULT 3.50,
  per_minute_rate NUMERIC(10, 2) NOT NULL DEFAULT 0.45,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(country_code, state_or_region)
);

ALTER TABLE fare_rates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Fare rates are viewable by everyone"
  ON fare_rates FOR SELECT
  USING (true);

CREATE POLICY "Fare rates are manageable by admins only"
  ON fare_rates FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND is_super_admin = true
    )
  );

INSERT INTO fare_rates (country_code, state_or_region, per_km_rate, base_fare, per_minute_rate) VALUES
  ('US', NULL, 1.85, 3.50, 0.45),
  ('GB', NULL, 2.10, 4.00, 0.50),
  ('NG', NULL, 1.20, 2.00, 0.30),
  ('CA', NULL, 1.75, 3.50, 0.45),
  ('AU', NULL, 2.00, 4.50, 0.55);
