// ============================================================
// FIKAGO API SERVER - Main Entry Point
// ============================================================

const express = require('express');
const path = require('path');

const cors = require('cors');
const axios = require('axios');
const pool = require('./config/db');
const { errorHandler, notFound } = require('./middlewares/errorHandler');
const { normalizePhoneFields } = require('./utils/phone');

const app = express();

// ============================================================
// MIDDLEWARE
// ============================================================
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Normalize phone values at the API boundary, including phone fields nested in payloads.
app.use((req, res, next) => {
  req.body = normalizePhoneFields(req.body);
  const originalJson = res.json.bind(res);
  res.json = (body) => originalJson(normalizePhoneFields(body));
  next();
});

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} | ${req.method} ${req.originalUrl}`);
  next();
});

// ============================================================
// ROUTES
// ============================================================
app.get('/', (req, res) => {
  res.json({
    message: '🍔 FikaGo API is running!',
    version: '1.0.0',
    status: 'OK',
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy', uptime: process.uptime() });
});

// Keep the Google Maps key on the server so it is never shipped in the app.
let lastReverseGeocodeAt = 0;
let googleGeocodingUnavailable = false;
let lastGoogleSearchAt = 0;
let lastOpenStreetMapGeocodeAt = 0;
let lastOpenStreetMapSearchAt = 0;

const searchWithGoogle = async (query, lat, lon) => {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  if (!apiKey || apiKey === 'your_google_maps_key' || googleGeocodingUnavailable) {
    return [];
  }
  const waitMs = Math.max(0, 200 - (Date.now() - lastGoogleSearchAt));
  if (waitMs) await new Promise((resolve) => setTimeout(resolve, waitMs));
  lastGoogleSearchAt = Date.now();

  const response = await axios.get('https://maps.googleapis.com/maps/api/geocode/json', {
    params: {
      address: query,
      components: 'country:TZ',
      ...(Number.isFinite(lat) && Number.isFinite(lon)
        ? { location: `${lat},${lon}`, radius: 50000 }
        : {}),
      key: apiKey,
    },
    timeout: 8000,
  });
  if (response.data.status === 'REQUEST_DENIED') {
    googleGeocodingUnavailable = true;
    console.warn('Google location search is unavailable; using OpenStreetMap fallback.');
    return [];
  }
  if (response.data.status !== 'OK') return [];
  return (response.data.results || []).slice(0, 5).map((item) => ({
    address: item.formatted_address || query,
    latitude: Number(item.geometry?.location?.lat),
    longitude: Number(item.geometry?.location?.lng),
    place_id: item.place_id,
  }));
};

const reverseGeocodeWithOpenStreetMap = async (lat, lon) => {
  const waitMs = Math.max(0, 1100 - (Date.now() - lastOpenStreetMapGeocodeAt));
  if (waitMs) await new Promise((resolve) => setTimeout(resolve, waitMs));
  lastOpenStreetMapGeocodeAt = Date.now();

  const response = await axios.get('https://nominatim.openstreetmap.org/reverse', {
    params: { format: 'jsonv2', lat, lon, zoom: 18, addressdetails: 1 },
    headers: { 'User-Agent': 'FikaGo/1.0 (customer location lookup)' },
    timeout: 8000,
  });
  const addressParts = response.data.address || {};
  const city = addressParts.city || addressParts.town || addressParts.village ||
    addressParts.municipality || addressParts.state_district || addressParts.county ||
    addressParts.state || '';
  const detail = response.data.name || addressParts.amenity || addressParts.road ||
    addressParts.neighbourhood || addressParts.suburb || addressParts.residential || '';
  const address = detail && city && detail.toLowerCase() !== city.toLowerCase()
    ? `${detail}, ${city}`
    : detail || city || response.data.display_name || '';
  if (!city && !address) throw new Error('OpenStreetMap returned no address');
  return { city, address, attribution: '© OpenStreetMap contributors' };
};

app.get('/api/location/reverse-geocode', async (req, res) => {
  const lat = Number(req.query.lat);
  const lon = Number(req.query.lon);
  if (!Number.isFinite(lat) || !Number.isFinite(lon) ||
      Math.abs(lat) > 90 || Math.abs(lon) > 180) {
    return res.status(400).json({ success: false, message: 'Coordinates are invalid' });
  }
  try {
    let data;
    const apiKey = process.env.GOOGLE_MAPS_API_KEY;
    if (apiKey && apiKey !== 'your_google_maps_key' && !googleGeocodingUnavailable) {
      try {
        const waitMs = Math.max(0, 200 - (Date.now() - lastReverseGeocodeAt));
        if (waitMs) await new Promise((resolve) => setTimeout(resolve, waitMs));
        lastReverseGeocodeAt = Date.now();

        const response = await axios.get('https://maps.googleapis.com/maps/api/geocode/json', {
          params: { latlng: `${lat},${lon}`, key: apiKey },
          timeout: 8000,
        });
        if (response.data.status === 'REQUEST_DENIED') {
          googleGeocodingUnavailable = true;
          console.warn('Google Geocoding is unavailable; using OpenStreetMap fallback.');
        } else if (response.data.status === 'OK' && response.data.results?.length) {
          const results = response.data.results;
          const result = results.find((candidate) =>
            candidate.address_components?.some((item) =>
              item.types.some((type) =>
                ['point_of_interest', 'establishment', 'premise'].includes(type)))) ||
            results[0];
          const components = result.address_components || [];
          const component = (...types) => components.find((item) =>
            types.some((type) => item.types.includes(type)))?.long_name || '';
          const city = component('locality', 'postal_town',
            'administrative_area_level_2', 'administrative_area_level_1');
          const detail = component('point_of_interest', 'establishment', 'premise') ||
            result.formatted_address || city;
          data = { city, address: detail, attribution: 'Google Maps' };
        }
      } catch (err) {
        console.warn('Google reverse geocoding failed; using OpenStreetMap fallback:', err.message);
      }
    }

    if (!data) data = await reverseGeocodeWithOpenStreetMap(lat, lon);
    return res.json({
      success: true,
      data,
    });
  } catch (err) {
    console.error('Reverse geocoding failed:', err.message);
    return res.status(502).json({ success: false, message: 'Could not resolve this location' });
  }
});

app.get('/api/location/search', async (req, res) => {
  const query = String(req.query.q || '').trim();
  const lat = Number(req.query.lat);
  const lon = Number(req.query.lon);
  const hasProximity = Number.isFinite(lat) && Number.isFinite(lon) &&
    Math.abs(lat) <= 90 && Math.abs(lon) <= 180;
  if (query.length < 2) {
    return res.status(400).json({ success: false, message: 'Search query is required' });
  }
  try {
    try {
      const googleResults = await searchWithGoogle(
        query,
        hasProximity ? lat : undefined,
        hasProximity ? lon : undefined,
      );
      if (googleResults.length) {
        return res.json({ success: true, data: googleResults });
      }
    } catch (err) {
      console.warn('Google location search failed; using OpenStreetMap fallback:', err.message);
    }

    const waitMs = Math.max(0, 1100 - (Date.now() - lastOpenStreetMapSearchAt));
    if (waitMs) await new Promise((resolve) => setTimeout(resolve, waitMs));
    lastOpenStreetMapSearchAt = Date.now();
    const viewbox = hasProximity
      ? `${lon - 0.15},${lat + 0.15},${lon + 0.15},${lat - 0.15}`
      : undefined;
    const response = await axios.get('https://nominatim.openstreetmap.org/search', {
      params: {
        q: query,
        format: 'jsonv2',
        addressdetails: 1,
        limit: Math.min(Number(req.query.limit) || 5, 10),
        countrycodes: 'tz',
        ...(viewbox ? { viewbox, bounded: 0 } : {}),
      },
      headers: { 'User-Agent': 'FikaGo/1.0 (customer location search)' },
      timeout: 8000,
    });
    const results = (response.data || []).map((item) => ({
      address: item.display_name,
      latitude: Number(item.lat),
      longitude: Number(item.lon),
      place_id: item.place_id,
    }));
    return res.json({ success: true, data: results });
  } catch (err) {
    console.error('Location search failed:', err.message);
    return res.status(502).json({ success: false, message: 'Could not search this location' });
  }
});

app.get('/api/test-db', async (req, res) => {
  try {
    const time = await pool.query('SELECT NOW()');
    const tables = await pool.query(
      `SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'`
    );
    const users = await pool.query('SELECT COUNT(*) FROM users');
    const restaurants = await pool.query('SELECT COUNT(*) FROM restaurants');
    res.json({
      success: true,
      database: process.env.DB_NAME,
      server_time: time.rows[0].now,
      total_tables: parseInt(tables.rows[0].count),
      total_users: parseInt(users.rows[0].count),
      total_restaurants: parseInt(restaurants.rows[0].count),
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// ============================================================
// API ROUTES - ZOTE HAPA
// ============================================================
app.use('/api/auth', require('./routes/auth'));
app.use('/api/restaurants', require('./routes/restaurants'));
app.use('/api/addresses', require('./routes/addresses'));
app.use('/api/cart', require('./routes/cart'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/vendor', require('./routes/vendor'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/upload', require('./routes/upload'));
app.use('/api/rider', require('./routes/rider'));
app.use('/api/wallet', require('./routes/wallet'));
app.use('/api/payments', require('./routes/payments'));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ============================================================
// ERROR HANDLING
// ============================================================
app.use(notFound);
app.use(errorHandler);

// ============================================================
// START SERVER
// ============================================================
const PORT = process.env.PORT || 5000;

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
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log('');
      console.log('════════════════════════════════════════════');
      console.log('   🍔 FIKAGO API SERVER');
      console.log('════════════════════════════════════════════');
      console.log(`   🌐 URL:      http://localhost:${PORT}`);
      console.log(`   📊 Database: ${process.env.DB_NAME}`);
      console.log(`   ⚙️  ENV:      ${process.env.NODE_ENV}`);
      console.log('════════════════════════════════════════════');
      console.log('');
    });
  })
  .catch((err) => {
    console.error('❌ Could not prepare registration schema:', err.message);
    process.exitCode = 1;
  });
