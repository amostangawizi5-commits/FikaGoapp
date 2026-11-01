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
  // Managed providers put sslmode=require in their external connection URL.
  // Render's internal database URL can be used without TLS inside the region.
  ...(process.env.DB_SSL === 'disable' ? { ssl: false } : {}),
  max: parseInt(process.env.DB_POOL_MAX || '3', 10),
  idleTimeoutMillis: 10000,
  connectionTimeoutMillis: 10000,
});

pool.on('connect', () => {
  console.log(`✅ PostgreSQL Connected: ${process.env.DB_NAME}`);
});

pool.on('error', (err) => {
  console.error('❌ DB Error:', err.message);
});

module.exports = pool;
