// ============================================================
// FIKAGO - PAYMENT CONTROLLER (Selcom Mock)
// ============================================================
const pool = require('../config/db');
const { success, error } = require('../utils/response');
const { initiatePayment } = require('../services/selcomService');
const { normalizeTzPhone } = require('../utils/phone');

// POST /api/payments/initiate
const initiateOrderPayment = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const customerId = req.user.id;
    const { order_id, payment_method } = req.body;

    const orderResult = await client.query(
      'SELECT * FROM orders WHERE id = $1 AND customer_id = $2', [order_id, customerId]
    );
    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return error(res, 'Oda haipo', 404);
    }
    const order = orderResult.rows[0];
    if (order.payment_status !== 'pending') {
      await client.query('ROLLBACK');
      return error(res, 'Malipo yameshalipwa', 400);
    }

    // Initiate payment
    const paymentResult = await initiatePayment({
      orderId: order.id,
      amount: order.total_amount,
      phone: normalizeTzPhone(order.customer_phone) || order.customer_phone,
      method: payment_method,
    });

    if (!paymentResult.success) {
      await client.query('ROLLBACK');
      return error(res, 'Malipo yameshindwa', 500);
    }

    // Save transaction
    await client.query(
      `INSERT INTO transactions (order_id, customer_id, selcom_transaction_ref, amount, payment_method, status)
       VALUES ($1, $2, $3, $4, $5, 'pending')`,
      [order.id, customerId, paymentResult.transaction_ref, order.total_amount, payment_method]
    );

    // Update order
    await client.query(
      `UPDATE orders SET selcom_transaction_ref = $1, payment_method = $2,
       payment_status = 'held_in_escrow', paid_at = NOW()
       WHERE id = $3`,
      [paymentResult.transaction_ref, payment_method, order.id]
    );

    // Hold escrow
    await client.query(
      `UPDATE wallets SET pending_balance = pending_balance + $1
       WHERE user_id = (SELECT owner_id FROM restaurants WHERE id = $2)`,
      [order.vendor_payout, order.restaurant_id]
    );

    await client.query('COMMIT');
    return success(res, {
      transaction_ref: paymentResult.transaction_ref,
      status: 'held_in_escrow',
    }, 'Malipo yameanza (mock)');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return error(res, 'Imeshindwa kuanzisha malipo', 500);
  } finally {
    client.release();
  }
};

module.exports = { initiateOrderPayment };
