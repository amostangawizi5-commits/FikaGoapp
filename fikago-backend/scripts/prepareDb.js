// Run this once against the target PostgreSQL database before deployment.
const pool = require('../config/db');

const prepareRegistrationSchema = async () => {
  // Keep existing local databases compatible with vendor and rider registration.
  // These additive, idempotent columns are also documented in migrations/.
  await pool.query(`
    ALTER TABLE restaurants
      ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'pending'
  `);
  await pool.query(`
    UPDATE restaurants
    SET approval_status = CASE
      WHEN is_approved = FALSE THEN 'pending'
      WHEN is_active = FALSE THEN 'suspended'
      ELSE 'approved'
    END
    WHERE approval_status = 'pending' AND (is_approved = TRUE OR is_active = TRUE)
  `);
  await pool.query(`
    ALTER TABLE restaurants
      ADD COLUMN IF NOT EXISTS delivery_area TEXT,
      ADD COLUMN IF NOT EXISTS gallery_images JSONB NOT NULL DEFAULT '[]'::jsonb
  `);
  await pool.query(`
    ALTER TABLE menu_items
      ADD COLUMN IF NOT EXISTS extras JSONB NOT NULL DEFAULT '[]'::jsonb
  `);
  await pool.query(`
    ALTER TABLE orders
      ADD COLUMN IF NOT EXISTS preparation_time_minutes INTEGER
  `);
  await pool.query(`
    ALTER TABLE rider_profiles
      ADD COLUMN IF NOT EXISTS license_number TEXT,
      ADD COLUMN IF NOT EXISTS license_plate TEXT,
      ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'pending'
  `);
  await pool.query(`
    UPDATE rider_profiles
    SET approval_status = CASE WHEN is_approved THEN 'approved' ELSE 'pending' END
    WHERE approval_status = 'pending' AND is_approved = TRUE
  `);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS restaurant_reviews (
      id BIGSERIAL PRIMARY KEY,
      restaurant_id BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
      customer_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      order_id BIGINT REFERENCES orders(id) ON DELETE SET NULL,
      rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
      comment TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (order_id)
    )
  `);
  await pool.query(`
    CREATE INDEX IF NOT EXISTS restaurant_reviews_restaurant_created_idx
    ON restaurant_reviews (restaurant_id, created_at DESC)
  `);
  await pool.query(`
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
    )
  `);
  await pool.query(`
    CREATE INDEX IF NOT EXISTS complaints_status_created_idx
    ON complaints (status, created_at DESC)
  `);
  await pool.query(`
    DO $$
    DECLARE
      customer_attnum SMALLINT;
      unique_constraint RECORD;
    BEGIN
      SELECT attnum INTO customer_attnum
      FROM pg_attribute
      WHERE attrelid = 'carts'::regclass
        AND attname = 'customer_id'
        AND NOT attisdropped;

      FOR unique_constraint IN
        SELECT conname FROM pg_constraint
        WHERE conrelid = 'carts'::regclass
          AND contype = 'u'
          AND conkey = ARRAY[customer_attnum]::SMALLINT[]
      LOOP
        EXECUTE format('ALTER TABLE carts DROP CONSTRAINT %I', unique_constraint.conname);
      END LOOP;

      FOR unique_constraint IN
        SELECT index_class.relname AS index_name
        FROM pg_index index_info
        JOIN pg_class index_class ON index_class.oid = index_info.indexrelid
        WHERE index_info.indrelid = 'carts'::regclass
          AND index_info.indisunique
          AND index_info.indnatts = 1
          AND index_info.indkey[0] = customer_attnum
          AND NOT EXISTS (
            SELECT 1 FROM pg_constraint constraint_info
            WHERE constraint_info.conindid = index_info.indexrelid
          )
      LOOP
        EXECUTE format('DROP INDEX %I', unique_constraint.index_name);
      END LOOP;
    END $$
  `);
  await pool.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS carts_customer_restaurant_unique
    ON carts (customer_id, restaurant_id)
  `);
};

prepareRegistrationSchema()
  .then(async () => {
    console.log('FikaGo database schema is ready.');
    await pool.end();
  })
  .catch(async (error) => {
    console.error('Could not prepare FikaGo database schema:', error.message);
    await pool.end();
    process.exitCode = 1;
  });
