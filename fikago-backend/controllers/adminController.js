const pool = require('../config/db');
const { success, error } = require('../utils/response');
const { normalizeTzPhone, phoneCandidates } = require('../utils/phone');

const getPeople = async (req, res) => {
  try {
    const { role, search = '' } = req.query;
    if (!['customer', 'vendor', 'rider'].includes(role)) return error(res, 'Role si sahihi', 400);
    const term = `%${String(search).trim()}%`;
    let query;
    if (role === 'customer') {
      query = await pool.query(
        `SELECT u.id, u.full_name AS name, u.phone_number, u.email, u.is_active,
                'customer' AS role,
                COUNT(DISTINCT o.id)::int AS order_count,
                COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'delivered'), 0) AS lifetime_spend
         FROM users u LEFT JOIN orders o ON o.customer_id = u.id
         WHERE u.role = 'customer' AND ($1 = '%%' OR u.full_name ILIKE $1 OR u.phone_number ILIKE $1 OR COALESCE(u.email,'') ILIKE $1)
         GROUP BY u.id ORDER BY u.created_at DESC LIMIT 200`, [term]);
    } else if (role === 'vendor') {
      query = await pool.query(
        `SELECT u.id, r.id AS restaurant_id, r.name, r.address, u.full_name, u.phone_number, u.email,
                u.is_active AS user_active, r.is_active, r.is_approved, r.approval_status,
                r.rating_avg,
                COUNT(DISTINCT o.id)::int AS order_count,
                COALESCE(SUM(o.vendor_payout) FILTER (WHERE o.status = 'delivered'), 0) AS earnings
         FROM restaurants r JOIN users u ON u.id = r.owner_id
         LEFT JOIN orders o ON o.restaurant_id = r.id
         WHERE ($1 = '%%' OR r.name ILIKE $1 OR u.full_name ILIKE $1 OR u.phone_number ILIKE $1)
         GROUP BY u.id, r.id ORDER BY r.created_at DESC LIMIT 200`, [term]);
    } else {
      query = await pool.query(
        `SELECT u.id, u.full_name AS name, u.phone_number, u.email, u.is_active,
                rp.is_approved, rp.approval_status, rp.is_online, rp.is_busy, rp.rating_avg,
                rp.total_deliveries, rp.vehicle_type, rp.license_plate,
                COALESCE(SUM(da.earnings) FILTER (WHERE da.status = 'delivered'), 0) AS earnings
         FROM users u JOIN rider_profiles rp ON rp.user_id = u.id
         LEFT JOIN delivery_assignments da ON da.rider_id = u.id
         WHERE u.role = 'rider' AND ($1 = '%%' OR u.full_name ILIKE $1 OR u.phone_number ILIKE $1)
         GROUP BY u.id, rp.user_id, rp.is_approved, rp.approval_status,
                  rp.is_online, rp.is_busy, rp.rating_avg, rp.total_deliveries,
                  rp.vehicle_type, rp.license_plate
         ORDER BY u.created_at DESC LIMIT 200`, [term]);
    }
    return success(res, query.rows, 'Records zimepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata records', 500);
  }
};

const updatePerson = async (req, res) => {
  try {
    const { role, id } = req.params;
    const { action } = req.body;
    if (!['customer', 'vendor', 'rider'].includes(role) || !/^\d+$/.test(id)) return error(res, 'Record si sahihi', 400);
    if (role === 'customer') {
      if (!['suspend', 'reactivate'].includes(action)) return error(res, 'Action si sahihi', 400);
      const result = await pool.query("UPDATE users SET is_active = $1, updated_at = NOW() WHERE id = $2 AND role = 'customer' RETURNING id, is_active", [action === 'reactivate', id]);
      if (!result.rows.length) return error(res, 'Mteja hapatikani', 404);
      return success(res, result.rows[0], 'Hali ya mteja imesasishwa');
    }
    if (role === 'vendor') {
      if (action === 'edit') {
        const fullName = String(req.body.full_name || '').trim();
        const restaurantName = String(req.body.restaurant_name || '').trim();
        const address = String(req.body.address || '').trim();
        const email = String(req.body.email || '').trim().toLowerCase();
        const phoneNumber = normalizeTzPhone(req.body.phone_number);
        if (!fullName || !restaurantName || !address || !phoneNumber || !email) {
          return error(res, 'Jina, simu, email na eneo vinahitajika', 400);
        }
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
          return error(res, 'Email si sahihi', 400);
        }

        const client = await pool.connect();
        try {
          await client.query('BEGIN');
          const account = await client.query(
            `SELECT id FROM users WHERE id = $1 AND role = 'vendor' FOR UPDATE`, [id]);
          if (!account.rows.length) {
            await client.query('ROLLBACK');
            return error(res, 'Vendor hapatikani', 404);
          }
          const restaurant = await client.query(
            'SELECT id FROM restaurants WHERE owner_id = $1 FOR UPDATE', [id]);
          if (!restaurant.rows.length) {
            await client.query('ROLLBACK');
            return error(res, 'Mgahawa haupatikani', 404);
          }
          const duplicatePhone = await client.query(
            'SELECT id FROM users WHERE id <> $1 AND phone_number = ANY($2::text[]) LIMIT 1',
            [id, phoneCandidates(phoneNumber)]);
          if (duplicatePhone.rows.length) {
            await client.query('ROLLBACK');
            return error(res, 'Namba hii inatumiwa na akaunti nyingine', 409);
          }
          const duplicateEmail = await client.query(
            'SELECT id FROM users WHERE id <> $1 AND LOWER(email) = LOWER($2) LIMIT 1',
            [id, email]);
          if (duplicateEmail.rows.length) {
            await client.query('ROLLBACK');
            return error(res, 'Email hii inatumiwa na akaunti nyingine', 409);
          }
          await client.query(
            'UPDATE users SET full_name = $1, phone_number = $2, email = $3, updated_at = NOW() WHERE id = $4',
            [fullName, phoneNumber, email, id]);
          const updatedRestaurant = await client.query(
            'UPDATE restaurants SET name = $1, phone_number = $2, address = $3, updated_at = NOW() WHERE owner_id = $4 RETURNING id, name, phone_number, address',
            [restaurantName, phoneNumber, address, id]);
          await client.query('COMMIT');
          return success(res, { id: Number(id), ...updatedRestaurant.rows[0] }, 'Taarifa za vendor zimesasishwa');
        } catch (err) {
          await client.query('ROLLBACK').catch(() => {});
          if (err.code === '23505') return error(res, 'Namba au email tayari imesajiliwa', 409);
          throw err;
        } finally {
          client.release();
        }
      }

      if (!['approve', 'reject', 'suspend', 'reactivate', 'delete'].includes(action)) return error(res, 'Action si sahihi', 400);
      if (action === 'delete') {
        const client = await pool.connect();
        try {
          await client.query('BEGIN');
          const restaurant = await client.query(
            `UPDATE restaurants SET is_approved = FALSE, is_active = FALSE,
               approval_status = 'deleted', updated_at = NOW()
             WHERE owner_id = $1 RETURNING id`, [id]);
          const account = await client.query(
            `UPDATE users SET is_active = FALSE, updated_at = NOW()
             WHERE id = $1 AND role = 'vendor' RETURNING id`, [id]);
          if (!restaurant.rows.length || !account.rows.length) {
            await client.query('ROLLBACK');
            return error(res, 'Vendor hapatikani', 404);
          }
          await client.query('COMMIT');
          return success(res, { id: Number(id), status: 'deleted' }, 'Vendor ameondolewa kwenye mfumo');
        } catch (err) {
          await client.query('ROLLBACK').catch(() => {});
          throw err;
        } finally {
          client.release();
        }
      }
      const state = {
        approve: [true, true, 'approved'], reject: [false, false, 'rejected'],
        suspend: [true, false, 'suspended'], reactivate: [true, true, 'approved'],
      }[action];
      const result = await pool.query(
        `UPDATE restaurants SET is_approved = $1, is_active = $2, approval_status = $3, updated_at = NOW()
         WHERE owner_id = $4 RETURNING id, is_approved, is_active, approval_status`, [...state, id]);
      if (!result.rows.length) return error(res, 'Mgahawa haupatikani', 404);
      await pool.query('UPDATE users SET is_active = $1, updated_at = NOW() WHERE id = $2 AND role = \'vendor\'', [action === 'suspend' || action === 'reject' ? false : true, id]);
      return success(res, result.rows[0], 'Hali ya mgahawa imesasishwa');
    }
    if (!['approve', 'reject', 'suspend', 'reactivate'].includes(action)) return error(res, 'Action si sahihi', 400);
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const state = { approve: [true, 'approved'], reject: [false, 'rejected'], suspend: [true, 'suspended'], reactivate: [true, 'approved'] }[action];
      const result = await client.query('UPDATE rider_profiles SET is_approved = $1, approval_status = $2, updated_at = NOW() WHERE user_id = $3 RETURNING user_id, is_approved, approval_status', [...state, id]);
      if (!result.rows.length) { await client.query('ROLLBACK'); return error(res, 'Rider hapatikani', 404); }
      await client.query('UPDATE users SET is_active = $1, updated_at = NOW() WHERE id = $2 AND role = \'rider\'', [action === 'suspend' || action === 'reject' ? false : true, id]);
      await client.query('COMMIT');
      return success(res, result.rows[0], 'Hali ya rider imesasishwa');
    } catch (err) { await client.query('ROLLBACK'); throw err; }
    finally { client.release(); }
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kusasisha hali', 500);
  }
};

const getPersonDetails = async (req, res) => {
  try {
    const { role, id } = req.params;
    if (!/^\d+$/.test(id) || !['customer', 'vendor', 'rider'].includes(role)) return error(res, 'Record si sahihi', 400);
    let details;
    if (role === 'customer') {
      const orders = await pool.query(
        `SELECT o.id, o.order_number, o.status, o.payment_status, o.total_amount, o.created_at, r.name AS restaurant_name
         FROM orders o JOIN restaurants r ON r.id = o.restaurant_id WHERE o.customer_id = $1 ORDER BY o.created_at DESC LIMIT 50`, [id]);
      details = { orders: orders.rows };
    } else if (role === 'vendor') {
      const restaurant = await pool.query('SELECT id FROM restaurants WHERE owner_id = $1', [id]);
      if (!restaurant.rows.length) return error(res, 'Mgahawa haupatikani', 404);
      const metrics = await pool.query(
        `SELECT COUNT(*)::int AS total_orders,
                COUNT(*) FILTER (WHERE status = 'delivered')::int AS completed_orders,
                COALESCE(SUM(vendor_payout) FILTER (WHERE status = 'delivered'), 0) AS earnings
         FROM orders WHERE restaurant_id = $1`, [restaurant.rows[0].id]);
      details = { metrics: metrics.rows[0] };
    } else {
      const metrics = await pool.query(
        `SELECT COUNT(*)::int AS total_deliveries,
                COALESCE(SUM(earnings) FILTER (WHERE status = 'delivered'), 0) AS earnings
         FROM delivery_assignments WHERE rider_id = $1`, [id]);
      details = { metrics: metrics.rows[0] };
    }
    return success(res, details, 'Taarifa zimepatikana');
  } catch (err) { console.error(err); return error(res, 'Imeshindwa kupata taarifa', 500); }
};

const getOrders = async (req, res) => {
  try {
    const { search = '', status = 'all', payment_status = 'all' } = req.query;
    const result = await pool.query(
      `SELECT o.id, o.order_number, o.status, o.payment_status, o.payment_method, o.total_amount,
              o.created_at, u.full_name AS customer_name, u.phone_number AS customer_phone,
              r.name AS restaurant_name
       FROM orders o JOIN users u ON u.id = o.customer_id JOIN restaurants r ON r.id = o.restaurant_id
       WHERE ($1 = '%%' OR o.order_number ILIKE $1 OR u.full_name ILIKE $1 OR u.phone_number ILIKE $1 OR r.name ILIKE $1)
         AND ($2 = 'all' OR o.status = $2) AND ($3 = 'all' OR o.payment_status = $3)
       ORDER BY o.created_at DESC LIMIT 300`, [`%${String(search).trim()}%`, status, payment_status]);
    return success(res, result.rows, 'Oda zimepatikana');
  } catch (err) { console.error(err); return error(res, 'Imeshindwa kupata oda', 500); }
};

const getOrderDetails = async (req, res) => {
  try {
    const order = await pool.query(
      `SELECT o.*, u.full_name AS customer_name, u.phone_number AS customer_phone,
              r.name AS restaurant_name, r.phone_number AS restaurant_phone
       FROM orders o JOIN users u ON u.id = o.customer_id JOIN restaurants r ON r.id = o.restaurant_id
       WHERE o.id = $1`, [req.params.id]);
    if (!order.rows.length) return error(res, 'Oda haipo', 404);
    const [items, logs, refunds] = await Promise.all([
      pool.query('SELECT * FROM order_items WHERE order_id = $1 ORDER BY id', [req.params.id]),
      pool.query('SELECT l.*, u.full_name AS changed_by FROM order_status_logs l LEFT JOIN users u ON u.id = l.changed_by_user_id WHERE l.order_id = $1 ORDER BY l.created_at', [req.params.id]),
      pool.query('SELECT * FROM refunds WHERE order_id = $1 ORDER BY created_at DESC', [req.params.id]),
    ]);
    return success(res, { ...order.rows[0], items: items.rows, status_history: logs.rows, refunds: refunds.rows }, 'Maelezo ya oda yamepatikana');
  } catch (err) { console.error(err); return error(res, 'Imeshindwa kupata maelezo ya oda', 500); }
};

const cancelOrder = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query('SELECT id, status FROM orders WHERE id = $1 FOR UPDATE', [req.params.id]);
    if (!result.rows.length) { await client.query('ROLLBACK'); return error(res, 'Oda haipo', 404); }
    if (!['pending', 'confirmed', 'preparing', 'ready', 'rider_assigned'].includes(result.rows[0].status)) { await client.query('ROLLBACK'); return error(res, 'Oda hii haiwezi kughairiwa baada ya kuchukuliwa au kufungwa', 409); }
    const assignment = await client.query("UPDATE delivery_assignments SET status = 'cancelled', cancellation_reason = $2 WHERE order_id = $1 AND status IN ('pending', 'accepted') RETURNING rider_id, status", [req.params.id, req.body.reason || 'Cancelled by admin']);
    if (assignment.rows.length) {
      await client.query(
        `UPDATE rider_profiles rp SET is_busy = EXISTS (
           SELECT 1 FROM delivery_assignments da WHERE da.rider_id = rp.user_id
             AND da.status IN ('accepted', 'arrived_at_restaurant', 'picked_up', 'on_the_way')
         ), updated_at = NOW() WHERE user_id = ANY($1::bigint[])`,
        [assignment.rows.map((row) => row.rider_id)]);
    }
    await client.query("UPDATE orders SET status = 'cancelled' WHERE id = $1", [req.params.id]);
    await client.query("INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes) VALUES ($1, 'cancelled', $2, $3)", [req.params.id, req.user.id, req.body.reason || 'Cancelled by admin']);
    await client.query('COMMIT');
    return success(res, null, 'Oda imeghairiwa');
  } catch (err) { await client.query('ROLLBACK'); console.error(err); return error(res, 'Imeshindwa kughairi oda', 500); }
  finally { client.release(); }
};

const issueRefund = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await client.query('SELECT * FROM orders WHERE id = $1 FOR UPDATE', [req.params.id]);
    if (!result.rows.length) { await client.query('ROLLBACK'); return error(res, 'Oda haipo', 404); }
    const order = result.rows[0];
    if (!['cancelled', 'rejected', 'delivered'].includes(order.status)) { await client.query('ROLLBACK'); return error(res, 'Refund inaruhusiwa kwa oda iliyokamilika au iliyositishwa tu', 409); }
    if (!['held_in_escrow', 'released'].includes(order.payment_status)) { await client.query('ROLLBACK'); return error(res, 'Malipo hayawezi kurejeshwa kwa sasa', 409); }
    const prior = await client.query('SELECT id FROM refunds WHERE order_id = $1', [order.id]);
    if (prior.rows.length) { await client.query('ROLLBACK'); return error(res, 'Refund imeshatolewa kwa oda hii', 409); }
    const amount = Number(order.total_amount);
    await client.query(
      `INSERT INTO refunds (order_id, customer_id, amount, reason, authorized_by_user_id, status)
       VALUES ($1, $2, $3, $4, $5, 'wallet_credited')`,
      [order.id, order.customer_id, amount, req.body.reason || 'Authorized by admin', req.user.id]);
    const customerWallet = await client.query(
      `INSERT INTO customer_wallets (customer_id, balance) VALUES ($1, $2)
       ON CONFLICT (customer_id) DO UPDATE
       SET balance = COALESCE(customer_wallets.balance, 0) + EXCLUDED.balance
       RETURNING id`, [order.customer_id, amount]);
    await client.query(
      `INSERT INTO customer_wallet_transactions (wallet_id, order_id, type, amount, description)
       VALUES ($1, $2, 'refund', $3, $4)`,
      [customerWallet.rows[0].id, order.id, amount, req.body.reason || 'Authorized by admin']);
    const vendor = await client.query('SELECT owner_id FROM restaurants WHERE id = $1', [order.restaurant_id]);
    if (order.payment_status === 'held_in_escrow') {
      await client.query('UPDATE wallets SET pending_balance = GREATEST(COALESCE(pending_balance, 0) - $1, 0), updated_at = NOW() WHERE user_id = $2', [order.vendor_payout || 0, vendor.rows[0]?.owner_id]);
    } else {
      await client.query('UPDATE wallets SET balance = GREATEST(COALESCE(balance, 0) - $1, 0), updated_at = NOW() WHERE user_id = $2', [order.vendor_payout || 0, vendor.rows[0]?.owner_id]);
      if (order.rider_id) await client.query('UPDATE wallets SET balance = GREATEST(COALESCE(balance, 0) - $1, 0), updated_at = NOW() WHERE user_id = $2', [order.rider_payout || 0, order.rider_id]);
    }
    await client.query("UPDATE orders SET payment_status = 'refunded' WHERE id = $1", [order.id]);
    await client.query("UPDATE transactions SET status = 'refunded' WHERE order_id = $1", [order.id]);
    await client.query("INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes) VALUES ($1, $2, $3, $4)", [order.id, order.status, req.user.id, `Refund of TZS ${amount} authorized: ${req.body.reason || 'Admin refund'}`]);
    await client.query('COMMIT');
    return success(res, { order_id: order.id, amount, status: 'wallet_credited' }, 'Refund imewekwa kwenye wallet ya mteja');
  } catch (err) { await client.query('ROLLBACK'); console.error(err); return error(res, 'Imeshindwa kutoa refund', 500); }
  finally { client.release(); }
};

const getPromotions = async (_req, res) => {
  try { const result = await pool.query('SELECT * FROM promotions ORDER BY created_at DESC'); return success(res, result.rows, 'Promotions zimepatikana'); }
  catch (err) { console.error(err); return error(res, 'Imeshindwa kupata promotions', 500); }
};

const savePromotion = async (req, res) => {
  try {
    const { code, discount_type, value = 0, min_order_amount = 0, starts_at, expiry_date, is_active = true } = req.body;
    const normalizedCode = String(code || '').trim().toUpperCase();
    if (!/^[A-Z0-9_-]{3,32}$/.test(normalizedCode)) return error(res, 'Code iwe na herufi/namba 3–32', 400);
    if (!['percentage', 'fixed', 'free_delivery'].includes(discount_type)) return error(res, 'Aina ya discount si sahihi', 400);
    const amount = Number(value); const minimum = Number(min_order_amount);
    if (!Number.isFinite(amount) || amount < 0 || (discount_type !== 'free_delivery' && amount <= 0) || (discount_type === 'percentage' && amount > 100) || !Number.isFinite(minimum) || minimum < 0) return error(res, 'Thamani ya discount/minimum si sahihi', 400);
    const start = starts_at || new Date().toISOString();
    const expiry = new Date(expiry_date);
    if (!Number.isFinite(expiry.getTime()) || expiry <= new Date(start)) return error(res, 'Tarehe ya mwisho lazima iwe baada ya tarehe ya kuanza', 400);
    const result = await pool.query(
      `INSERT INTO promotions (code, type, discount_type, value, min_order_amount, starts_at, expiry_date, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [normalizedCode, discount_type === 'free_delivery' ? 'fixed' : discount_type, discount_type, discount_type === 'free_delivery' ? 0 : amount, minimum, start, expiry.toISOString(), Boolean(is_active)]);
    return success(res, result.rows[0], 'Promotion imeundwa', 201);
  } catch (err) {
    if (err.code === '23505') return error(res, 'Promo code tayari ipo', 409);
    console.error(err); return error(res, 'Imeshindwa kuunda promotion', 500);
  }
};

const updatePromotion = async (req, res) => {
  try {
    const { is_active } = req.body;
    if (typeof is_active !== 'boolean') return error(res, 'is_active inahitajika', 400);
    const result = await pool.query('UPDATE promotions SET is_active = $1 WHERE id = $2 RETURNING *', [is_active, req.params.id]);
    if (!result.rows.length) return error(res, 'Promotion haipo', 404);
    return success(res, result.rows[0], 'Promotion imesasishwa');
  } catch (err) { console.error(err); return error(res, 'Imeshindwa kusasisha promotion', 500); }
};

const deletePromotion = async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM promotions WHERE id = $1 RETURNING id', [req.params.id]);
    if (!result.rows.length) return error(res, 'Promotion haipo', 404);
    return success(res, null, 'Promotion imefutwa');
  } catch (err) { console.error(err); return error(res, 'Imeshindwa kufuta promotion', 500); }
};

const getComplaints = async (req, res) => {
  try {
    const status = req.query.status || 'all';
    const result = await pool.query(
      `SELECT c.*, u.full_name AS customer_name, u.phone_number, o.order_number
       FROM complaints c JOIN users u ON u.id = c.customer_id LEFT JOIN orders o ON o.id = c.order_id
       WHERE ($1 = 'all' OR c.status = $1) ORDER BY c.created_at DESC LIMIT 300`, [status]);
    return success(res, result.rows, 'Malalamiko yamepatikana');
  } catch (err) { console.error(err); return error(res, 'Imeshindwa kupata malalamiko', 500); }
};

const updateComplaint = async (req, res) => {
  try {
    const { status, resolution } = req.body;
    if (!['in_review', 'resolved', 'dismissed'].includes(status)) return error(res, 'Status si sahihi', 400);
    const result = await pool.query(
      `UPDATE complaints SET status = $1, resolution = $2, resolved_by_user_id = $3,
       updated_at = NOW() WHERE id = $4 RETURNING *`, [status, resolution || null, req.user.id, req.params.id]);
    if (!result.rows.length) return error(res, 'Malalamiko hayapo', 404);
    return success(res, result.rows[0], 'Malalamiko yamesasishwa');
  } catch (err) { console.error(err); return error(res, 'Imeshindwa kusasisha malalamiko', 500); }
};

module.exports = { getPeople, updatePerson, getPersonDetails, getOrders, getOrderDetails, cancelOrder, issueRefund, getPromotions, savePromotion, updatePromotion, deletePromotion, getComplaints, updateComplaint };
