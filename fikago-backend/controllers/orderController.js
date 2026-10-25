// ============================================================
// FIKAGO - ORDER CONTROLLER
// ============================================================
const pool = require('../config/db');
const { success, error } = require('../utils/response');
const { generateOrderNumber } = require('../utils/orderNumber');
const { calculateCartTotal } = require('./cartController');
const { normalizeTzPhone } = require('../utils/phone');
const { sendSMS } = require('../services/smsService');

// POST /api/orders - Create order from cart
const createOrder = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const customerId = req.user.id;
    const { customer_name, delivery_address, delivery_landmark, delivery_latitude,
            delivery_longitude, customer_phone, payment_method,
            special_instructions } = req.body;
    const normalizedCustomerPhone = normalizeTzPhone(customer_phone);
    const customerName = String(customer_name || '').trim();
    const deliveryAddress = String(delivery_address || '').trim();
    const selectedPaymentMethod = String(payment_method || 'cash').trim().toLowerCase();
    const allowedPaymentMethods = ['cash', 'mpesa', 'tigopesa', 'airtel'];
    const hasLatitude = delivery_latitude !== undefined && delivery_latitude !== null && delivery_latitude !== '';
    const hasLongitude = delivery_longitude !== undefined && delivery_longitude !== null && delivery_longitude !== '';
    const latitude = hasLatitude ? Number(delivery_latitude) : null;
    const longitude = hasLongitude ? Number(delivery_longitude) : null;

    if (!customerName || !normalizedCustomerPhone || !deliveryAddress) {
      await client.query('ROLLBACK');
      return error(res, 'Jina, simu na anuani ya mteja vinahitajika', 400);
    }
    if (!allowedPaymentMethods.includes(selectedPaymentMethod)) {
      await client.query('ROLLBACK');
      return error(res, 'Payment method si sahihi', 400);
    }
    if (hasLatitude !== hasLongitude ||
        (hasLatitude && (!Number.isFinite(latitude) || !Number.isFinite(longitude) ||
          Math.abs(latitude) > 90 || Math.abs(longitude) > 180))) {
      await client.query('ROLLBACK');
      return error(res, 'Latitude na longitude za anuani si sahihi', 400);
    }

    // 1. Pata cart
    const cartResult = await client.query(
      'SELECT * FROM carts WHERE customer_id = $1', [customerId]
    );
    if (cartResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return error(res, 'Cart haipo', 404);
    }
    const cart = cartResult.rows[0];
    if (!cart.restaurant_id) {
      await client.query('ROLLBACK');
      return error(res, 'Cart haina vyakula', 400);
    }

    // 2. Pata cart items
    const itemsResult = await client.query(
      'SELECT * FROM cart_items WHERE cart_id = $1', [cart.id]
    );
    if (itemsResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return error(res, 'Cart haina vyakula', 400);
    }

    // 3. Calculate
    const summary = await calculateCartTotal(cart.id, {
      delivery_latitude: latitude,
      delivery_longitude: longitude,
    });
    const restaurant = await client.query(
      'SELECT commission_rate FROM restaurants WHERE id = $1', [cart.restaurant_id]
    );
    const commissionRate = parseFloat(restaurant.rows[0].commission_rate) || 15;

    const subtotal = summary.subtotal;
    const deliveryFee = summary.delivery_fee;
    const serviceFee = summary.service_fee;
    const discount = summary.discount;
    const totalAmount = summary.total_amount;

    // Distribution
    const platformCommission = (subtotal * commissionRate) / 100;
    const vendorPayout = subtotal - platformCommission;
    const riderPayout = deliveryFee * 0.8; // 80% ya delivery fee
    const platformDeliveryFee = deliveryFee - riderPayout;

    // 4. Generate order number
    const orderNumber = await generateOrderNumber(client);

    // 5. Unda order
    const orderResult = await client.query(
      `INSERT INTO orders (
        order_number, customer_id, restaurant_id, status, payment_status,
        payment_method, subtotal, delivery_fee, service_fee, discount,
        total_amount, vendor_payout, rider_payout, platform_commission,
        delivery_address, delivery_landmark, delivery_latitude, delivery_longitude,
        delivery_distance_km, delivery_duration_min, customer_phone, special_instructions
      ) VALUES ($1, $2, $3, 'pending', 'pending', $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)
      RETURNING *`,
      [orderNumber, customerId, cart.restaurant_id, selectedPaymentMethod,
       subtotal, deliveryFee, serviceFee, discount, totalAmount,
       vendorPayout, riderPayout, platformCommission,
       deliveryAddress, delivery_landmark, latitude, longitude,
       summary.delivery_distance_km, summary.delivery_duration_min,
       normalizedCustomerPhone, special_instructions]
    );
    const order = orderResult.rows[0];

    await client.query(
      'UPDATE users SET full_name = $1 WHERE id = $2',
      [customerName, customerId]
    );
    order.customer_name = customerName;

    // 6. Copy cart items → order_items
    for (const item of itemsResult.rows) {
      const menuItem = await client.query('SELECT name FROM menu_items WHERE id = $1', [item.menu_item_id]);
      await client.query(
        `INSERT INTO order_items (order_id, menu_item_id, item_name, quantity, unit_price, total_price, special_instructions)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [order.id, item.menu_item_id, menuItem.rows[0].name,
         item.quantity, item.unit_price, item.total_price, item.special_instructions]
      );
    }

    // 7. Log status
    await client.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, 'pending', $2, 'Order created')`,
      [order.id, customerId]
    );

    const notificationBody = `Oda ${order.order_number} imepokelewa. Jumla: TZS ${Number(totalAmount).toFixed(0)}. ` +
      `Anuani: ${deliveryAddress}`;
    const notification = await client.query(
      `INSERT INTO notifications (user_id, title, body, type, reference_id)
       VALUES ($1, $2, $3, 'order_confirmation', $4) RETURNING id`,
      [customerId, 'Order confirmation', notificationBody, order.id]
    );

    // 8. Futa cart
    await client.query('DELETE FROM cart_items WHERE cart_id = $1', [cart.id]);
    await client.query(
      `UPDATE carts SET subtotal = 0, discount = 0, service_fee = 0,
       total_amount = 0, promo_code = NULL, restaurant_id = NULL WHERE id = $1`,
      [cart.id]
    );

    await client.query('COMMIT');
    const sms = await sendSMS(
      normalizedCustomerPhone,
      `FikaGo: Oda ${order.order_number} imepokelewa. Jumla TZS ${Number(totalAmount).toFixed(0)}.`,
    );
    order.confirmation_sent = Boolean(sms.success);
    order.confirmation_notification_id = notification.rows[0].id;
    return success(res, order, 'Oda imeundwa na confirmation imetumwa', 201);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return error(res, 'Imeshindwa kuunda oda', 500);
  } finally {
    client.release();
  }
};

// GET /api/orders - Customer's orders
const getMyOrders = async (req, res) => {
  try {
    const customerId = req.user.id;
    const { status } = req.query;

    let query = `
      SELECT o.*, r.name AS restaurant_name, r.logo_url AS restaurant_logo,
             c.full_name AS customer_name,
             u.full_name AS rider_name, u.phone_number AS rider_phone,
             COALESCE((
               SELECT json_agg(json_build_object(
                 'name', oi.item_name,
                 'quantity', oi.quantity,
                 'unit_price', oi.unit_price,
                 'total_price', oi.total_price
               ) ORDER BY oi.id)
               FROM order_items oi WHERE oi.order_id = o.id
             ), '[]'::json) AS items
      FROM orders o
      JOIN restaurants r ON o.restaurant_id = r.id
      LEFT JOIN users c ON o.customer_id = c.id
      LEFT JOIN users u ON o.rider_id = u.id
      WHERE o.customer_id = $1
    `;
    const params = [customerId];
    if (status) {
      params.push(status);
      query += ` AND o.status = $${params.length}`;
    }
    query += ' ORDER BY o.created_at DESC LIMIT 50';

    const result = await pool.query(query, params);
    return success(res, result.rows, 'Oda zimepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata oda', 500);
  }
};

// GET /api/orders/:id
const getOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const customerId = req.user.id;

    const orderResult = await pool.query(
      `SELECT o.*, r.name AS restaurant_name, r.phone_number AS restaurant_phone,
              r.logo_url AS restaurant_logo,
              u.full_name AS rider_name, u.phone_number AS rider_phone,
              rp.vehicle_type, rp.license_plate
       FROM orders o
       JOIN restaurants r ON o.restaurant_id = r.id
       LEFT JOIN users u ON o.rider_id = u.id
       LEFT JOIN rider_profiles rp ON o.rider_id = rp.user_id
       WHERE o.id = $1 AND o.customer_id = $2`,
      [id, customerId]
    );
    if (orderResult.rows.length === 0) return error(res, 'Oda haipo', 404);

    const itemsResult = await pool.query(
      'SELECT * FROM order_items WHERE order_id = $1', [id]
    );

    const logsResult = await pool.query(
      `SELECT status, notes, created_at FROM order_status_logs
       WHERE order_id = $1 ORDER BY created_at ASC`, [id]
    );

    return success(res, {
      order: orderResult.rows[0],
      items: itemsResult.rows,
      status_history: logsResult.rows,
    }, 'Oda imepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata oda', 500);
  }
};

// PUT /api/orders/:id/cancel
const cancelOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const customerId = req.user.id;

    const orderResult = await pool.query(
      'SELECT * FROM orders WHERE id = $1 AND customer_id = $2', [id, customerId]
    );
    if (orderResult.rows.length === 0) return error(res, 'Oda haipo', 404);

    const order = orderResult.rows[0];
    if (!['pending', 'confirmed'].includes(order.status)) {
      return error(res, 'Oda haiwezi kufutwa kwa hatua hii', 400);
    }

    await pool.query('UPDATE orders SET status = $1 WHERE id = $2', ['cancelled', id]);
    await pool.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, 'cancelled', $2, 'Cancelled by customer')`,
      [id, customerId]
    );

    return success(res, null, 'Oda imefutwa');
  } catch (err) {
    return error(res, 'Imeshindwa kufuta oda', 500);
  }
};

const createComplaint = async (req, res) => {
  try {
    const { id } = req.params;
    const subject = String(req.body.subject || '').trim();
    const description = String(req.body.description || '').trim();
    if (subject.length < 3 || description.length < 10) {
      return error(res, 'Kichwa na maelezo ya malalamiko vinahitajika', 400);
    }
    const order = await pool.query(
      'SELECT id FROM orders WHERE id = $1 AND customer_id = $2', [id, req.user.id]
    );
    if (!order.rows.length) return error(res, 'Oda haipo', 404);
    const result = await pool.query(
      `INSERT INTO complaints (customer_id, order_id, subject, description)
       VALUES ($1, $2, $3, $4) RETURNING *`, [req.user.id, id, subject, description]
    );
    return success(res, result.rows[0], 'Malalamiko yametumwa', 201);
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kutuma malalamiko', 500);
  }
};

module.exports = { createOrder, getMyOrders, getOrder, cancelOrder, createComplaint };
