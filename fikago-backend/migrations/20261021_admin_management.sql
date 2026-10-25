-- Run once after the original FikaGo schema has been installed.
ALTER TABLE restaurants
  ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'approved';
UPDATE restaurants SET approval_status = CASE
  WHEN is_approved = FALSE THEN 'pending'
  WHEN is_active = FALSE THEN 'suspended'
  ELSE 'approved' END
WHERE approval_status = 'approved';

ALTER TABLE rider_profiles
  ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'approved';
UPDATE rider_profiles SET approval_status = CASE
  WHEN is_approved = FALSE THEN 'pending'
  ELSE 'approved' END
WHERE approval_status = 'approved';

ALTER TABLE promotions
  ADD COLUMN IF NOT EXISTS discount_type TEXT NOT NULL DEFAULT 'percentage',
  ADD COLUMN IF NOT EXISTS starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
UPDATE promotions SET discount_type = type WHERE discount_type = 'percentage';
CREATE UNIQUE INDEX IF NOT EXISTS promotions_code_unique_idx ON promotions (UPPER(code));

CREATE TABLE IF NOT EXISTS refunds (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
  customer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  reason TEXT NOT NULL,
  authorized_by_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'processed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS complaints (
  id BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  order_id BIGINT REFERENCES orders(id) ON DELETE SET NULL,
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  resolution TEXT,
  resolved_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS complaints_status_created_idx ON complaints(status, created_at DESC);
