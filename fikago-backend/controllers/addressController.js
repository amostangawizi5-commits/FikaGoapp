const pool = require('../config/db');
const { success, error } = require('../utils/response');

const coordinates = (latitude, longitude) => {
  if (latitude == null && longitude == null) return { latitude: null, longitude: null };
  const lat = Number(latitude);
  const lng = Number(longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng) ||
      Math.abs(lat) > 90 || Math.abs(lng) > 180) return false;
  return { latitude: lat, longitude: lng };
};

const listAddresses = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM customer_addresses
       WHERE customer_id = $1 ORDER BY is_default DESC, created_at DESC`,
      [req.user.id],
    );
    return success(res, result.rows, 'Anuani zimepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata anuani', 500);
  }
};

const createAddress = async (req, res) => {
  try {
    const addressLine = String(req.body.address_line || '').trim();
    const point = coordinates(req.body.latitude, req.body.longitude);
    if (!addressLine) return error(res, 'Anuani inahitajika', 400);
    if (point === false) return error(res, 'Latitude na longitude si sahihi', 400);

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const isDefault = Boolean(req.body.is_default);
      if (isDefault) {
        await client.query(
          'UPDATE customer_addresses SET is_default = FALSE WHERE customer_id = $1',
          [req.user.id],
        );
      }
      const result = await client.query(
        `INSERT INTO customer_addresses
          (customer_id, label, address_line, landmark, latitude, longitude,
           formatted_address, google_place_id, is_default)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
        [req.user.id, req.body.label || null, addressLine,
          req.body.landmark || null, point.latitude, point.longitude,
          req.body.formatted_address || addressLine,
          req.body.google_place_id || null, isDefault],
      );
      await client.query('COMMIT');
      return success(res, result.rows[0], 'Anuani imehifadhiwa', 201);
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kuhifadhi anuani', 500);
  }
};

const deleteAddress = async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM customer_addresses WHERE id = $1 AND customer_id = $2 RETURNING id',
      [req.params.id, req.user.id],
    );
    if (!result.rows.length) return error(res, 'Anuani haipo', 404);
    return success(res, null, 'Anuani imefutwa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kufuta anuani', 500);
  }
};

module.exports = { listAddresses, createAddress, deleteAddress };
