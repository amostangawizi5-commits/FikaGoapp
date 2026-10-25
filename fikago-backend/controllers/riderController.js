// ============================================================
// FIKAGO - RIDER CONTROLLER
// ============================================================
const pool = require('../config/db');
const { success, error } = require('../utils/response');

// PUT /api/rider/status - Online/Offline
const updateStatus = async (req, res) => {
  try {
    const riderId = req.user.id;
    const { is_online } = req.body;

    await pool.query(
      `UPDATE rider_profiles SET is_online = $1, updated_at = NOW()
       WHERE user_id = $2`, [is_online, riderId]
    );
    return success(res, { is_online }, 'Status imesasishwa');
  } catch (err) {
    return error(res, 'Imeshindwa kusasisha status', 500);
  }
};

// PUT /api/rider/location - GPS position used by dispatch/vendor views.
const updateLocation = async (req, res) => {
  try {
    const latitude = Number(req.body.latitude);
    const longitude = Number(req.body.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude) ||
        Math.abs(latitude) > 90 || Math.abs(longitude) > 180) {
      return error(res, 'Latitude na longitude si sahihi', 400);
    }
    const result = await pool.query(
      `UPDATE rider_profiles
       SET current_latitude = $1, current_longitude = $2, updated_at = NOW()
       WHERE user_id = $3
       RETURNING current_latitude, current_longitude`,
      [latitude, longitude, req.user.id],
    );
    if (!result.rows.length) return error(res, 'Rider profile haipo', 404);
    return success(res, result.rows[0], 'Location ya rider imesasishwa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kusasisha location', 500);
  }
};

// GET /api/rider/assignments?status=new|active|done
const getAssignments = async (req, res) => {
  try {
    const riderId = req.user.id;
    const { status } = req.query;

    let statusFilter = '';
    if (status === 'new') {
      statusFilter = `AND da.status = 'pending'`;
    } else if (status === 'active') {
      statusFilter = `AND da.status IN ('accepted', 'arrived_at_restaurant', 'picked_up', 'on_the_way')`;
    } else if (status === 'done') {
      statusFilter = `AND da.status = 'delivered'`;
    }

    const result = status === 'new'
      ? await pool.query(
          `SELECT da.id, da.order_id, da.rider_id, da.vendor_id, da.status,
                  da.earnings, da.created_at, o.order_number, o.delivery_address,
                  o.delivery_landmark, o.delivery_latitude, o.delivery_longitude,
                  o.customer_phone, o.special_instructions, o.payment_method,
                  o.subtotal, o.delivery_fee, o.service_fee, o.discount,
                  o.total_amount, r.name AS restaurant_name,
                  r.phone_number AS restaurant_phone, r.address AS restaurant_address,
                  r.latitude AS restaurant_lat, r.longitude AS restaurant_lng,
                  u.full_name AS customer_name
           FROM delivery_assignments da
           JOIN orders o ON da.order_id = o.id
           JOIN restaurants r ON o.restaurant_id = r.id
           JOIN users u ON o.customer_id = u.id
           WHERE da.rider_id = $1 AND da.status = 'pending'
             AND o.rider_id = $1
           UNION ALL
           SELECT -o.id AS id, o.id AS order_id, $1 AS rider_id,
                  r.owner_id AS vendor_id, 'pending' AS status,
                  o.rider_payout AS earnings, o.created_at, o.order_number,
                  o.delivery_address, o.delivery_landmark, o.delivery_latitude,
                  o.delivery_longitude, o.customer_phone, o.special_instructions,
                  o.payment_method, o.subtotal, o.delivery_fee, o.service_fee,
                  o.discount, o.total_amount, r.name AS restaurant_name,
                  r.phone_number AS restaurant_phone, r.address AS restaurant_address,
                  r.latitude AS restaurant_lat, r.longitude AS restaurant_lng,
                  u.full_name AS customer_name
           FROM orders o
           JOIN restaurants r ON o.restaurant_id = r.id
           JOIN users u ON o.customer_id = u.id
           WHERE o.status IN ('pending', 'confirmed', 'preparing', 'ready')
             AND o.rider_id IS NULL
             AND r.is_approved = TRUE AND r.is_active = TRUE
             AND EXISTS (
               SELECT 1 FROM rider_profiles rp
               WHERE rp.user_id = $1 AND rp.is_approved = TRUE
                 AND rp.is_online = TRUE AND rp.is_busy = FALSE
             )
             AND NOT EXISTS (
               SELECT 1 FROM delivery_assignments da
               WHERE da.order_id = o.id
                 AND da.status IN ('pending', 'accepted', 'arrived_at_restaurant',
                                   'picked_up', 'on_the_way', 'delivered')
             )
             AND NOT EXISTS (
               SELECT 1 FROM delivery_assignments declined
               WHERE declined.order_id = o.id AND declined.rider_id = $1
                 AND declined.status = 'cancelled'
                 AND declined.cancellation_reason = 'Declined by rider'
             )
           ORDER BY created_at DESC
           LIMIT 100`,
          [riderId],
        )
      : await pool.query(
          `SELECT da.*, o.order_number, o.delivery_address, o.delivery_landmark,
                  o.delivery_latitude, o.delivery_longitude, o.customer_phone,
                  o.special_instructions, o.payment_method, o.subtotal,
                  o.delivery_fee, o.service_fee, o.discount, o.total_amount,
                  r.name AS restaurant_name, r.phone_number AS restaurant_phone,
                  r.address AS restaurant_address, r.latitude AS restaurant_lat,
                  r.longitude AS restaurant_lng,
                  u.full_name AS customer_name
           FROM delivery_assignments da
           JOIN orders o ON da.order_id = o.id
           JOIN restaurants r ON o.restaurant_id = r.id
           JOIN users u ON o.customer_id = u.id
           WHERE da.rider_id = $1 ${statusFilter}
           ORDER BY da.created_at DESC
           LIMIT 50`,
          [riderId],
        );
    return success(res, result.rows, 'Assignments zimepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata assignments', 500);
  }
};

// POST /api/rider/assignments/:id/accept
const acceptAssignment = async (req, res) => {
  const assignmentId = Number(req.params.id);
  if (Number.isInteger(assignmentId) && assignmentId < 0) {
    return acceptOpenOrder(Math.abs(assignmentId), req.user.id, res);
  }

  try {
    const { id } = req.params;
    const riderId = req.user.id;

    const result = await pool.query(
      `UPDATE delivery_assignments SET status = 'accepted', accepted_at = NOW()
       WHERE id = $1 AND rider_id = $2 AND status = 'pending'
       RETURNING *`, [id, riderId]
    );
    if (result.rows.length === 0) return error(res, 'Assignment haipo', 404);

    await pool.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, 'rider_accepted', $2, 'Rider accepted')`,
      [result.rows[0].order_id, riderId]
    );
    await pool.query(
      'UPDATE rider_profiles SET is_busy = TRUE WHERE user_id = $1', [riderId]
    );

    return success(res, result.rows[0], 'Assignment imekubaliwa');
  } catch (err) {
    return error(res, 'Imeshindwa kukubali', 500);
  }
};

const acceptOpenOrder = async (orderId, riderId, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const riderResult = await client.query(
      `SELECT is_approved, is_online, is_busy
       FROM rider_profiles WHERE user_id = $1 FOR UPDATE`,
      [riderId],
    );
    if (!riderResult.rows.length || !riderResult.rows[0].is_approved ||
        !riderResult.rows[0].is_online || riderResult.rows[0].is_busy) {
      await client.query('ROLLBACK');
      return error(res, 'Rider lazima awe online na asiwe na oda nyingine', 409);
    }
    const orderResult = await client.query(
      `SELECT o.id, o.rider_payout, r.owner_id AS vendor_id
       FROM orders o
       JOIN restaurants r ON r.id = o.restaurant_id
       WHERE o.id = $1 AND o.status IN ('pending', 'confirmed', 'preparing', 'ready')
         AND o.rider_id IS NULL
         AND NOT EXISTS (
           SELECT 1 FROM delivery_assignments da
           WHERE da.order_id = o.id
             AND da.status IN ('pending', 'accepted', 'arrived_at_restaurant',
                               'picked_up', 'on_the_way', 'delivered')
         )
       FOR UPDATE OF o`,
      [orderId],
    );
    if (!orderResult.rows.length) {
      await client.query('ROLLBACK');
      return error(res, 'Oda hii tayari imechukuliwa na rider mwingine', 409);
    }

    const order = orderResult.rows[0];
    const assignment = await client.query(
      `INSERT INTO delivery_assignments (order_id, rider_id, vendor_id, status, earnings)
       VALUES ($1, $2, $3, 'accepted', $4) RETURNING *`,
      [orderId, riderId, order.vendor_id, order.rider_payout],
    );
    await client.query(
      `UPDATE orders SET rider_id = $1, status = 'rider_assigned' WHERE id = $2`,
      [riderId, orderId],
    );
    await client.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, 'rider_accepted', $2, 'Rider accepted open order')`,
      [orderId, riderId],
    );
    await client.query(
      'UPDATE rider_profiles SET is_busy = TRUE WHERE user_id = $1',
      [riderId],
    );
    await client.query('COMMIT');
    return success(res, assignment.rows[0], 'Assignment imekubaliwa');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return error(res, 'Imeshindwa kukubali oda', 500);
  } finally {
    client.release();
  }
};

// POST /api/rider/assignments/:id/decline
const declineAssignment = async (req, res) => {
  const assignmentId = Number(req.params.id);
  if (Number.isInteger(assignmentId) && assignmentId < 0) {
    try {
      const orderId = Math.abs(assignmentId);
      const result = await pool.query(
        `INSERT INTO delivery_assignments (order_id, rider_id, vendor_id, status,
                                           earnings, cancellation_reason)
         SELECT o.id, $2, r.owner_id, 'cancelled', o.rider_payout, 'Declined by rider'
         FROM orders o
         JOIN restaurants r ON r.id = o.restaurant_id
         WHERE o.id = $1 AND o.status IN ('confirmed', 'preparing', 'ready')
           AND o.rider_id IS NULL
           AND NOT EXISTS (
             SELECT 1 FROM delivery_assignments active
             WHERE active.order_id = o.id
               AND active.status IN ('pending', 'accepted', 'arrived_at_restaurant',
                                     'picked_up', 'on_the_way', 'delivered')
           )
         RETURNING id`,
        [orderId, req.user.id],
      );
      if (!result.rowCount) return error(res, 'Oda haipo tena kwenye orodha', 409);
      return success(res, null, 'Oda imekataliwa');
    } catch (err) {
      console.error(err);
      return error(res, 'Imeshindwa kukataa oda', 500);
    }
  }

  try {
    const { id } = req.params;
    const riderId = req.user.id;

    const result = await pool.query(
      `UPDATE delivery_assignments SET status = 'cancelled', cancellation_reason = 'Declined by rider'
       WHERE id = $1 AND rider_id = $2 AND status = 'pending'
       RETURNING order_id`, [id, riderId]
    );
    if (result.rows.length) {
      await pool.query(
        `UPDATE orders SET rider_id = NULL
         WHERE id = $1 AND rider_id = $2`,
        [result.rows[0].order_id, riderId],
      );
    }
    return success(res, null, 'Assignment imekataliwa');
  } catch (err) {
    return error(res, 'Imeshindwa kukataa', 500);
  }
};

// PUT /api/rider/assignments/:id/pickup
const markPickedUp = async (req, res) => {
  try {
    const { id } = req.params;
    const riderId = req.user.id;

    await pool.query(
      `UPDATE delivery_assignments SET status = 'picked_up', picked_up_at = NOW()
       WHERE id = $1 AND rider_id = $2`, [id, riderId]
    );

    const assignment = await pool.query('SELECT order_id FROM delivery_assignments WHERE id = $1', [id]);
    await pool.query('UPDATE orders SET status = $1 WHERE id = $2',
      ['picked_up', assignment.rows[0].order_id]);
    await pool.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, 'picked_up', $2, 'Picked up by rider')`,
      [assignment.rows[0].order_id, riderId]
    );

    return success(res, null, 'Chakula kimechukuliwa');
  } catch (err) {
    return error(res, 'Imeshindwa', 500);
  }
};

// PUT /api/rider/assignments/:id/deliver
const markDelivered = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { id } = req.params;
    const { delivery_code } = req.body;
    const riderId = req.user.id;

    const assignment = await client.query(
      'SELECT * FROM delivery_assignments WHERE id = $1 AND rider_id = $2', [id, riderId]
    );
    if (assignment.rows.length === 0) {
      await client.query('ROLLBACK');
      return error(res, 'Assignment haipo', 404);
    }

    const order = await client.query('SELECT * FROM orders WHERE id = $1', [assignment.rows[0].order_id]);

    // Update order
    await client.query(
      `UPDATE orders SET status = 'delivered', payment_status = 'released',
       delivered_at = NOW(), payout_released_at = NOW() WHERE id = $1`,
      [order.rows[0].id]
    );

    // Update assignment
    await client.query(
      `UPDATE delivery_assignments SET status = 'delivered', delivered_at = NOW()
       WHERE id = $1`, [id]
    );

    // Release escrow kwa rider na vendor
    const riderPayout = parseFloat(order.rows[0].rider_payout) || 0;
    const vendorPayout = parseFloat(order.rows[0].vendor_payout) || 0;

    await client.query(
      `UPDATE wallets SET balance = balance + $1, total_earned = total_earned + $1,
       pending_balance = GREATEST(pending_balance - $1, 0), updated_at = NOW()
       WHERE user_id = $2`, [riderPayout, riderId]
    );

    // Update rider stats
    await client.query(
      `UPDATE rider_profiles SET is_busy = FALSE, total_deliveries = total_deliveries + 1
       WHERE user_id = $1`, [riderId]
    );

    // Update vendor wallet
    const vendorUser = await client.query(
      'SELECT owner_id FROM restaurants WHERE id = $1', [order.rows[0].restaurant_id]
    );
    if (vendorUser.rows.length > 0) {
      await client.query(
        `UPDATE wallets SET balance = balance + $1, total_earned = total_earned + $1,
         pending_balance = GREATEST(pending_balance - $1, 0), updated_at = NOW()
         WHERE user_id = $2`, [vendorPayout, vendorUser.rows[0].owner_id]
      );
    }

    await client.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, 'delivered', $2, 'Delivered - payment released')`,
      [order.rows[0].id, riderId]
    );

    await client.query('COMMIT');
    return success(res, { rider_payout: riderPayout, vendor_payout: vendorPayout }, 'Delivery imekamilika');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return error(res, 'Imeshindwa', 500);
  } finally {
    client.release();
  }
};

// GET /api/rider/wallet
const getWallet = async (req, res) => {
  try {
    const riderId = req.user.id;
    let walletResult = await pool.query('SELECT * FROM wallets WHERE user_id = $1', [riderId]);
    if (walletResult.rows.length === 0) {
      walletResult = await pool.query(
        'INSERT INTO wallets (user_id) VALUES ($1) RETURNING *', [riderId]
      );
    }
    return success(res, walletResult.rows[0], 'Wallet imepatikana');
  } catch (err) {
    return error(res, 'Imeshindwa', 500);
  }
};

module.exports = { updateStatus, updateLocation, getAssignments, acceptAssignment, declineAssignment, markPickedUp, markDelivered, getWallet };
