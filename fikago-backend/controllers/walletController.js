// ============================================================
// FIKAGO - WALLET CONTROLLER (Customer Wallet)
// ============================================================
const pool = require('../config/db');
const { success, error } = require('../utils/response');

// GET /api/wallet
const getWallet = async (req, res) => {
  try {
    const customerId = req.user.id;
    let walletResult = await pool.query(
      'SELECT * FROM customer_wallets WHERE customer_id = $1', [customerId]
    );
    if (walletResult.rows.length === 0) {
      walletResult = await pool.query(
        'INSERT INTO customer_wallets (customer_id) VALUES ($1) RETURNING *', [customerId]
      );
    }
    return success(res, walletResult.rows[0], 'Wallet imepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa', 500);
  }
};

// GET /api/wallet/transactions
const getTransactions = async (req, res) => {
  try {
    const customerId = req.user.id;
    const { type, limit = 20, offset = 0 } = req.query;

    const walletResult = await pool.query(
      'SELECT id FROM customer_wallets WHERE customer_id = $1', [customerId]
    );
    if (walletResult.rows.length === 0) return success(res, [], 'Hakuna transactions');

    let query = `
      SELECT cwt.*, o.order_number, r.name AS restaurant_name
      FROM customer_wallet_transactions cwt
      LEFT JOIN orders o ON cwt.order_id = o.id
      LEFT JOIN restaurants r ON o.restaurant_id = r.id
      WHERE cwt.wallet_id = $1
    `;
    const params = [walletResult.rows[0].id];

    if (type && type !== 'all') {
      params.push(type);
      query += ` AND cwt.type = $${params.length}`;
    }

    params.push(limit, offset);
    query += ` ORDER BY cwt.created_at DESC LIMIT $${params.length - 1} OFFSET $${params.length}`;

    const result = await pool.query(query, params);
    return success(res, result.rows, 'Transactions zimepatikana');
  } catch (err) {
    return error(res, 'Imeshindwa', 500);
  }
};

module.exports = { getWallet, getTransactions };
