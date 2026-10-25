-- Run once against the FikaGo PostgreSQL database before deploying vendor management.
ALTER TABLE restaurants
  ADD COLUMN IF NOT EXISTS delivery_area TEXT,
  ADD COLUMN IF NOT EXISTS gallery_images JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE menu_items
  ADD COLUMN IF NOT EXISTS extras JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS preparation_time_minutes INTEGER;

CREATE TABLE IF NOT EXISTS restaurant_reviews (
  id BIGSERIAL PRIMARY KEY,
  restaurant_id BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  customer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  order_id BIGINT REFERENCES orders(id) ON DELETE SET NULL,
  rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (order_id)
);
CREATE INDEX IF NOT EXISTS restaurant_reviews_restaurant_created_idx
  ON restaurant_reviews (restaurant_id, created_at DESC);
