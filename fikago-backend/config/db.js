// ============================================================
// FIKAGO - DATABASE CONNECTION
// ============================================================
const { Pool } = require('pg');
require('dotenv').config({
  path: `.env.${process.env.NODE_ENV || 'development'}`
});

const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('connect', () => {
  console.log(`✅ PostgreSQL Connected: ${process.env.DB_NAME}`);
});

pool.on('error', (err) => {
  console.error('❌ DB Error:', err.message);
});

module.exports = pool;
