-- Keep a separate cart for each customer and restaurant.
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
    SELECT conname
    FROM pg_constraint
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
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS carts_customer_restaurant_unique
  ON carts (customer_id, restaurant_id);
