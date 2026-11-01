// ============================================================
// FIKAGO - DATABASE CONNECTION
// ============================================================
const { Pool } = require('pg');
require('dotenv').config({
  path: `.env.${process.env.NODE_ENV || 'development'}`
});

const pool = new Pool({
  ...(process.env.DATABASE_URL
    ? { connectionString: process.env.DATABASE_URL }
    : {
        host: process.env.DB_HOST,
        port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
        database: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
      }),
  // Hosted Postgres URLs should include sslmode=require.
  ...(process.env.DB_SSL === 'disable' && !process.env.DATABASE_URL
    ? { ssl: false }
    : {}),
  max: parseInt(process.env.DB_POOL_MAX || '3', 10),
  idleTimeoutMillis: 5000,
  connectionTimeoutMillis: 10000,
});

if (process.env.VERCEL) {
  const { attachDatabasePool } = require('@vercel/functions');
  attachDatabasePool(pool);
}

pool.on('connect', () => {
  console.log('✅ PostgreSQL Connected');
});

pool.on('error', (err) => {
  console.error('❌ DB Error:', err.message);
});

module.exports = pool;
