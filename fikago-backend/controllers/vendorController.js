// ============================================================
// FIKAGO - VENDOR CONTROLLER
// ============================================================
const pool = require('../config/db');
const { success, error } = require('../utils/response');
const { normalizeTzPhone } = require('../utils/phone');

// Helper: Pata restaurant ya vendor
const getVendorRestaurant = async (userId) => {
  const result = await pool.query(
    'SELECT * FROM restaurants WHERE owner_id = $1', [userId]
  );
  return result.rows[0];
};

const getVendorProfile = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);
    const reviews = await pool.query(
      `SELECT COUNT(*)::int AS review_count,
              CASE WHEN COUNT(*) = 0 THEN $2::numeric
                   ELSE AVG(rating)::numeric(3,2) END AS rating_avg
       FROM restaurant_reviews WHERE restaurant_id = $1`, [restaurant.id, restaurant.rating_avg || 0]
    );
    return success(res, { ...restaurant, ...reviews.rows[0] }, 'Profile imepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata profile', 500);
  }
};

const updateVendorProfile = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);
    const { name, description, address, phone_number, opening_time, closing_time,
      delivery_area, logo_url, cover_image_url, gallery_images } = req.body;
    if (phone_number && !normalizeTzPhone(phone_number)) {
      return error(res, 'Namba ya simu si sahihi (mfano: +255712345678)', 400);
    }
    const result = await pool.query(
      `UPDATE restaurants SET
        name = COALESCE($1, name), description = COALESCE($2, description),
        address = COALESCE($3, address), phone_number = COALESCE($4, phone_number),
        opening_time = COALESCE($5, opening_time), closing_time = COALESCE($6, closing_time),
        delivery_area = COALESCE($7, delivery_area), logo_url = COALESCE($8, logo_url),
        cover_image_url = COALESCE($9, cover_image_url),
        gallery_images = COALESCE($10::jsonb, gallery_images), updated_at = NOW()
       WHERE id = $11 RETURNING *`,
      [name, description, address, normalizeTzPhone(phone_number) || phone_number, opening_time, closing_time,
        delivery_area, logo_url, cover_image_url,
        gallery_images == null ? null : JSON.stringify(gallery_images), restaurant.id]
    );
    return success(res, result.rows[0], 'Profile imesasishwa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kusasisha profile', 500);
  }
};

const getVendorReviews = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);
    const result = await pool.query(
      `SELECT rr.id, rr.rating, rr.comment, rr.created_at, u.full_name AS customer_name
       FROM restaurant_reviews rr JOIN users u ON u.id = rr.customer_id
       WHERE rr.restaurant_id = $1 ORDER BY rr.created_at DESC LIMIT 100`, [restaurant.id]
    );
    return success(res, result.rows, 'Reviews zimepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata reviews', 500);
  }
};

// GET /api/vendor/orders - Vendor's orders
const getVendorOrders = async (req, res) => {
  try {
    const vendorId = req.user.id;
    const restaurant = await getVendorRestaurant(vendorId);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);

    const { status } = req.query;
    let query = `
      SELECT o.*, u.full_name AS customer_name, u.phone_number AS customer_phone,
             COALESCE((
               SELECT json_agg(json_build_object(
                 'name', oi.item_name,
                 'quantity', oi.quantity,
                 'total_price', oi.total_price
               ) ORDER BY oi.id)
               FROM order_items oi WHERE oi.order_id = o.id
             ), '[]'::json) AS items
      FROM orders o
      JOIN users u ON o.customer_id = u.id
      WHERE o.restaurant_id = $1
    `;
    const params = [restaurant.id];
    if (status) {
      params.push(status);
      query += ` AND o.status = $${params.length}`;
    }
    query += ' ORDER BY o.created_at DESC LIMIT 100';

    const result = await pool.query(query, params);
    return success(res, result.rows, 'Oda zimepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata oda', 500);
  }
};

// PUT /api/vendor/orders/:id/accept
const acceptOrder = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const vendorId = req.user.id;
    const { id } = req.params;
    const restaurant = await getVendorRestaurant(vendorId);
    if (!restaurant) {
      await client.query('ROLLBACK');
      return error(res, 'Restaurant haipo', 404);
    }

    const orderResult = await client.query(
      'SELECT * FROM orders WHERE id = $1 AND restaurant_id = $2 FOR UPDATE',
      [id, restaurant.id]
    );
    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return error(res, 'Oda haipo', 404);
    }

    const prepTime = Number(req.body.preparation_time_minutes) || 20;
    if (prepTime < 5 || prepTime > 180) {
      await client.query('ROLLBACK');
      return error(res, 'Muda uwe kati ya dakika 5 na 180', 400);
    }
    if (!['pending', 'rider_assigned'].includes(orderResult.rows[0].status)) {
      await client.query('ROLLBACK');
      return error(res, 'Oda hii haiwezi kukubaliwa tena', 409);
    }
    await client.query(
      'UPDATE orders SET status = $1, preparation_time_minutes = $2 WHERE id = $3',
      ['confirmed', prepTime, id]
    );
    await client.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, 'confirmed', $2, 'Accepted by vendor')`,
      [id, vendorId]
    );

    await client.query('COMMIT');
    return success(res, null, 'Oda imekubaliwa');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Vendor accept order failed:', err);
    return error(res, 'Imeshindwa kukubali', 500);
  } finally {
    client.release();
  }
};

// PUT /api/vendor/orders/:id/reject
const rejectOrder = async (req, res) => {
  try {
    const vendorId = req.user.id;
    const { id } = req.params;
    const { reason } = req.body;
    const restaurant = await getVendorRestaurant(vendorId);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);

    const order = await pool.query('SELECT id, status FROM orders WHERE id = $1 AND restaurant_id = $2', [id, restaurant.id]);
    if (order.rows.length === 0) return error(res, 'Oda haipo', 404);
    if (!['pending', 'rider_assigned'].includes(order.rows[0].status)) {
      return error(res, 'Oda hii haiwezi kukataliwa tena', 409);
    }
    const cancelledAssignments = await pool.query(
      `UPDATE delivery_assignments
       SET status = 'cancelled', cancellation_reason = 'Rejected by restaurant'
       WHERE order_id = $1 AND status IN ('pending', 'accepted')
       RETURNING rider_id`,
      [id],
    );
    await pool.query(
      'UPDATE orders SET status = $1, rider_id = NULL WHERE id = $2',
      ['rejected', id],
    );
    const assignedRiders = [...new Set(
      cancelledAssignments.rows.map((row) => row.rider_id),
    )];
    if (assignedRiders.length) {
      await pool.query(
        `UPDATE rider_profiles rp SET is_busy = FALSE
         WHERE rp.user_id = ANY($1::int[])
           AND NOT EXISTS (
             SELECT 1 FROM delivery_assignments da
             WHERE da.rider_id = rp.user_id
               AND da.status IN ('accepted', 'arrived_at_restaurant',
                                 'picked_up', 'on_the_way')
           )`,
        [assignedRiders],
      );
    }
    await pool.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, 'rejected', $2, $3)`,
      [id, vendorId, reason || 'Rejected by vendor']
    );

    return success(res, null, 'Oda imekataliwa');
  } catch (err) {
    return error(res, 'Imeshindwa kukataa', 500);
  }
};

const updateOrderStatus = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);
    const { id } = req.params;
    const { status } = req.body;
    if (!['preparing', 'ready'].includes(status)) return error(res, 'Status si sahihi', 400);
    const orderResult = await pool.query(
      'SELECT id, status FROM orders WHERE id = $1 AND restaurant_id = $2', [id, restaurant.id]
    );
    if (orderResult.rows.length === 0) return error(res, 'Oda haipo', 404);
    const current = orderResult.rows[0].status;
    const allowed = status === 'preparing' ? ['confirmed'] : ['confirmed', 'preparing'];
    if (!allowed.includes(current)) return error(res, 'Mabadiliko haya ya status hayaruhusiwi', 409);
    await pool.query('UPDATE orders SET status = $1 WHERE id = $2', [status, id]);
    await pool.query(
      `INSERT INTO order_status_logs (order_id, status, changed_by_user_id, notes)
       VALUES ($1, $2, $3, $4)`, [id, status, req.user.id, `Updated by vendor`]
    );
    return success(res, null, 'Status ya oda imesasishwa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kusasisha status', 500);
  }
};

// PUT /api/vendor/orders/:id/assign-rider
const assignRider = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const vendorId = req.user.id;
    const { id } = req.params;
    const { rider_id } = req.body;

    const restaurant = await getVendorRestaurant(vendorId);
    if (!restaurant) {
      await client.query('ROLLBACK');
      return error(res, 'Restaurant haipo', 404);
    }

    const orderResult = await client.query(
      'SELECT * FROM orders WHERE id = $1 AND restaurant_id = $2 FOR UPDATE',
      [id, restaurant.id],
    );
    if (orderResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return error(res, 'Oda haipo', 404);
    }
    const order = orderResult.rows[0];
    if (order.rider_id || order.status === 'rider_assigned' ||
        ['picked_up', 'on_the_way', 'delivered', 'cancelled'].includes(order.status)) {
      await client.query('ROLLBACK');
      return error(res, 'Oda hii tayari imepangiwa rider au imefungwa', 409);
    }

    // Link the rider without changing the restaurant's order status.
    await client.query(
      'UPDATE orders SET rider_id = $1 WHERE id = $2',
      [rider_id, id],
    );

    // Unda delivery assignment
    await client.query(
      `INSERT INTO delivery_assignments (order_id, rider_id, vendor_id, status, earnings)
       VALUES ($1, $2, $3, 'pending', $4)`,
      [id, rider_id, vendorId, order.rider_payout]
    );

    await client.query('COMMIT');
    return success(res, null, 'Rider amepangiwa');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return error(res, 'Imeshindwa kumpanga rider', 500);
  } finally {
    client.release();
  }
};

// GET /api/vendor/riders/available
const getAvailableRiders = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT u.id, u.full_name, u.phone_number,
              rp.vehicle_type, rp.license_plate, rp.rating_avg,
              rp.current_latitude, rp.current_longitude
       FROM users u
       JOIN rider_profiles rp ON u.id = rp.user_id
       WHERE u.role = 'rider' AND rp.is_approved = TRUE
         AND rp.is_online = TRUE AND rp.is_busy = FALSE
       ORDER BY rp.rating_avg DESC`
    );
    return success(res, result.rows, 'Riders waliopo');
  } catch (err) {
    return error(res, 'Imeshindwa kupata riders', 500);
  }
};

// GET /api/vendor/menu
const getVendorMenu = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);

    const result = await pool.query(
      `SELECT mi.*, mc.name AS category_name
       FROM menu_items mi
       LEFT JOIN menu_categories mc ON mi.category_id = mc.id
       WHERE mi.restaurant_id = $1
       ORDER BY mc.sort_order, mi.name`, [restaurant.id]
    );
    return success(res, result.rows, 'Menu imepatikana');
  } catch (err) {
    return error(res, 'Imeshindwa kupata menu', 500);
  }
};

// POST /api/vendor/menu/items
const addMenuItem = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);

    const {
      category_id,
      category_name,
      name,
      description,
      price,
      image_url,
      preparation_time,
      extras,
    } = req.body;
    if (!name || !price) return error(res, 'name na price zinahitajika', 400);

    let resolvedCategoryId = category_id || null;
    if (!resolvedCategoryId && category_name?.trim()) {
      const existingCategory = await pool.query(
        `SELECT id FROM menu_categories
         WHERE restaurant_id = $1 AND LOWER(name) = LOWER($2)
         LIMIT 1`,
        [restaurant.id, category_name.trim()]
      );
      if (existingCategory.rows.length > 0) {
        resolvedCategoryId = existingCategory.rows[0].id;
      } else {
        const newCategory = await pool.query(
          `INSERT INTO menu_categories (restaurant_id, name)
           VALUES ($1, $2) RETURNING id`,
          [restaurant.id, category_name.trim()]
        );
        resolvedCategoryId = newCategory.rows[0].id;
      }
    }

    const result = await pool.query(
      `INSERT INTO menu_items (restaurant_id, category_id, name, description, price, image_url, preparation_time, extras)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb) RETURNING *`,
      [restaurant.id, resolvedCategoryId, name, description, price, image_url, preparation_time || 15, JSON.stringify(extras || [])]
    );
    return success(res, result.rows[0], 'Chakula kimeongezwa', 201);
  } catch (err) {
    console.error('Add vendor menu item failed:', err.message);
    return error(res, 'Imeshindwa kuongeza', 500);
  }
};

// PUT /api/vendor/menu/items/:id
const updateMenuItem = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);

    const { id } = req.params;
    const { name, description, price, image_url, is_available, category_name, extras } = req.body;

    let categoryId;
    if (category_name?.trim()) {
      const found = await pool.query(
        'SELECT id FROM menu_categories WHERE restaurant_id = $1 AND LOWER(name) = LOWER($2) LIMIT 1',
        [restaurant.id, category_name.trim()]
      );
      if (found.rows.length) categoryId = found.rows[0].id;
      else {
        const created = await pool.query(
          'INSERT INTO menu_categories (restaurant_id, name) VALUES ($1, $2) RETURNING id',
          [restaurant.id, category_name.trim()]
        );
        categoryId = created.rows[0].id;
      }
    }

    const result = await pool.query(
      `UPDATE menu_items SET
        name = COALESCE($1, name),
        description = COALESCE($2, description),
        price = COALESCE($3, price),
        image_url = COALESCE($4, image_url),
        is_available = COALESCE($5, is_available),
        category_id = COALESCE($6, category_id),
        extras = COALESCE($7::jsonb, extras),
        updated_at = NOW()
       WHERE id = $8 AND restaurant_id = $9 RETURNING *`,
      [name, description, price, image_url, is_available, categoryId,
        extras == null ? null : JSON.stringify(extras), id, restaurant.id]
    );
    if (result.rows.length === 0) return error(res, 'Chakula hakipo', 404);
    return success(res, result.rows[0], 'Chakula kimesasishwa');
  } catch (err) {
    return error(res, 'Imeshindwa kusasisha', 500);
  }
};

// DELETE /api/vendor/menu/items/:id
const deleteMenuItem = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);

    const result = await pool.query(
      'DELETE FROM menu_items WHERE id = $1 AND restaurant_id = $2 RETURNING id',
      [req.params.id, restaurant.id]
    );
    if (result.rows.length === 0) return error(res, 'Chakula hakipo', 404);
    return success(res, null, 'Chakula kimefutwa');
  } catch (err) {
    return error(res, 'Imeshindwa kufuta', 500);
  }
};

// GET /api/vendor/earnings
const getVendorEarnings = async (req, res) => {
  try {
    const restaurant = await getVendorRestaurant(req.user.id);
    if (!restaurant) return error(res, 'Restaurant haipo', 404);

    const stats = await pool.query(
      `SELECT
        COUNT(*) FILTER (WHERE status = 'delivered') AS total_deliveries,
        COALESCE(SUM(vendor_payout) FILTER (WHERE status = 'delivered'), 0) AS total_earned,
        COALESCE(SUM(vendor_payout) FILTER (WHERE payment_status = 'released'), 0) AS available_balance,
        COALESCE(SUM(vendor_payout) FILTER (WHERE payment_status = 'held_in_escrow'), 0) AS pending_balance
       FROM orders WHERE restaurant_id = $1`, [restaurant.id]
    );

    const recent = await pool.query(
      `SELECT order_number, vendor_payout, status, payment_status, created_at
       FROM orders WHERE restaurant_id = $1
       ORDER BY created_at DESC LIMIT 20`, [restaurant.id]
    );

    return success(res, { stats: stats.rows[0], recent_orders: recent.rows }, 'Mapato yamepatikana');
  } catch (err) {
    return error(res, 'Imeshindwa kupata mapato', 500);
  }
};

module.exports = {
  getVendorProfile, updateVendorProfile, getVendorReviews, updateOrderStatus,
  getVendorOrders, acceptOrder, rejectOrder, assignRider,
  getAvailableRiders, getVendorMenu, addMenuItem, updateMenuItem,
  deleteMenuItem, getVendorEarnings,
};
