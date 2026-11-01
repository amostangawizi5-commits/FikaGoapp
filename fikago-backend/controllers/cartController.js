// ============================================================
// FIKAGO - CART CONTROLLER
// ============================================================
const pool = require('../config/db');
const { success, error } = require('../utils/response');
const { calculateDistance, calculateDeliveryFee } = require('../services/googleMapsService');

const parseCoordinates = (latitude, longitude) => {
  if (latitude === undefined && longitude === undefined) return null;
  const lat = Number(latitude);
  const lng = Number(longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng) ||
      Math.abs(lat) > 90 || Math.abs(lng) > 180) return false;
  return { latitude: lat, longitude: lng };
};

const getCartData = async (cartId) => {
  const cartResult = await pool.query(
    `SELECT c.id, c.restaurant_id, r.name AS restaurant_name
     FROM carts c LEFT JOIN restaurants r ON r.id = c.restaurant_id
     WHERE c.id = $1`, [cartId]
  );
  if (cartResult.rows.length === 0) return null;
  const summary = await calculateCartTotal(cartId);
  const cart = cartResult.rows[0];
  return {
    cart_id: cart.id,
    restaurant_id: cart.restaurant_id,
    restaurant_name: cart.restaurant_name || '',
    ...summary,
  };
};

// Helper: Calculate cart total
const calculateCartTotal = async (cartId, destination = {}) => {
  const client = await pool.connect();
  try {
    const itemsResult = await client.query(
      `SELECT ci.*, mi.name, mi.restaurant_id FROM cart_items ci
       JOIN menu_items mi ON ci.menu_item_id = mi.id
       WHERE ci.cart_id = $1`, [cartId]
    );
    const items = itemsResult.rows;

    const subtotal = items.reduce(
      (sum, item) => sum + parseFloat(item.unit_price) * item.quantity, 0
    );

    const cartResult = await client.query('SELECT * FROM carts WHERE id = $1', [cartId]);
    const cart = cartResult.rows[0];

    let deliveryFee = parseFloat(cart.delivery_fee) || 2000;
    let deliveryDistanceKm = cart.delivery_distance_km == null
      ? null : parseFloat(cart.delivery_distance_km);
    let deliveryDurationMin = cart.delivery_duration_min == null
      ? null : parseInt(cart.delivery_duration_min, 10);

    const coordinates = parseCoordinates(
      destination.delivery_latitude, destination.delivery_longitude,
    );
    if (coordinates === false) throw new Error('Delivery coordinates are invalid');
    if (coordinates && cart.restaurant_id) {
      const restaurantResult = await client.query(
        'SELECT latitude, longitude FROM restaurants WHERE id = $1',
        [cart.restaurant_id],
      );
      const restaurant = restaurantResult.rows[0];
      if (restaurant && restaurant.latitude != null && restaurant.longitude != null) {
        const estimate = await calculateDistance(
          { lat: Number(restaurant.latitude), lng: Number(restaurant.longitude) },
          { lat: coordinates.latitude, lng: coordinates.longitude },
        );
        deliveryDistanceKm = estimate.distance_km;
        deliveryDurationMin = estimate.duration_min;
        deliveryFee = calculateDeliveryFee(deliveryDistanceKm);
      }
    }
    const serviceFee = subtotal * 0.02;

    let discount = 0;
    if (cart.promo_code) {
      const promoResult = await client.query(
        `SELECT * FROM promotions WHERE UPPER(code) = UPPER($1) AND is_active = TRUE
         AND starts_at <= NOW() AND expiry_date > NOW() AND min_order_amount <= $2`,
        [cart.promo_code, subtotal]
      );
      if (promoResult.rows.length > 0) {
        const promo = promoResult.rows[0];
        const promoType = promo.discount_type || promo.type;
        if (promoType === 'percentage') discount = (subtotal * promo.value) / 100;
        else if (promoType === 'fixed') discount = Math.min(promo.value, subtotal);
        else if (promoType === 'free_delivery') deliveryFee = 0;
      }
    }

    const totalAmount = subtotal + deliveryFee + serviceFee - discount;

    await client.query(
      `UPDATE carts SET subtotal = $1, delivery_fee = $2, service_fee = $3,
       discount = $4, total_amount = $5, delivery_distance_km = $6,
       delivery_duration_min = $7, updated_at = NOW() WHERE id = $8`,
      [subtotal, deliveryFee, serviceFee, discount, totalAmount,
       deliveryDistanceKm, deliveryDurationMin, cartId]
    );

    return {
      items,
      subtotal: parseFloat(subtotal.toFixed(2)),
      delivery_fee: parseFloat(deliveryFee.toFixed(2)),
      service_fee: parseFloat(serviceFee.toFixed(2)),
      discount: parseFloat(discount.toFixed(2)),
      total_amount: parseFloat(totalAmount.toFixed(2)),
      delivery_distance_km: deliveryDistanceKm,
      delivery_duration_min: deliveryDurationMin,
    };
  } finally {
    client.release();
  }
};

// GET /api/cart
const getCart = async (req, res) => {
  try {
    const customerId = req.user.id;
    const cartResult = await pool.query(
      `SELECT c.id FROM carts c
       WHERE c.customer_id = $1 AND c.restaurant_id IS NOT NULL
         AND EXISTS (SELECT 1 FROM cart_items ci WHERE ci.cart_id = c.id)
       ORDER BY c.id`, [customerId]
    );
    const carts = [];
    for (const row of cartResult.rows) {
      const cart = await getCartData(row.id);
      if (cart) carts.push(cart);
    }
    return success(res, { carts }, 'Vikapu vimepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata cart', 500);
  }
};

// POST /api/cart/quote - Recalculate checkout charges for a destination.
const quoteCart = async (req, res) => {
  try {
    const coordinates = parseCoordinates(
      req.body.delivery_latitude, req.body.delivery_longitude,
    );
    if (coordinates === false) {
      return error(res, 'Latitude na longitude si sahihi', 400);
    }

    const cartId = Number(req.body.cart_id);
    if (!Number.isInteger(cartId) || cartId < 1) {
      return error(res, 'Cart ID si sahihi', 400);
    }
    const cartResult = await pool.query(
      'SELECT id FROM carts WHERE customer_id = $1 AND id = $2',
      [req.user.id, cartId],
    );
    if (cartResult.rows.length === 0) return error(res, 'Cart haipo', 404);

    await calculateCartTotal(cartId, req.body);
    const cart = await getCartData(cartId);
    return success(res, cart, 'Quote imepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata quote ya oda', 400);
  }
};

// POST /api/cart/add
const addToCart = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { menu_item_id, quantity = 1, special_instructions } = req.body;
    const customerId = req.user.id;

    const itemResult = await client.query(
      'SELECT * FROM menu_items WHERE id = $1 AND is_available = TRUE', [menu_item_id]
    );
    if (itemResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return error(res, 'Chakula hakipatikani', 404);
    }
    const menuItem = itemResult.rows[0];

    const cartResult = await client.query(
      `INSERT INTO carts (customer_id, restaurant_id) VALUES ($1, $2)
       ON CONFLICT (customer_id, restaurant_id)
       DO UPDATE SET restaurant_id = EXCLUDED.restaurant_id
       RETURNING id`, [customerId, menuItem.restaurant_id]
    );
    const cartId = cartResult.rows[0].id;

    const existing = await client.query(
      'SELECT * FROM cart_items WHERE cart_id = $1 AND menu_item_id = $2',
      [cartId, menu_item_id]
    );

    if (existing.rows.length > 0) {
      await client.query(
        `UPDATE cart_items SET quantity = quantity + $1,
         total_price = (quantity + $1) * unit_price
         WHERE cart_id = $2 AND menu_item_id = $3`,
        [quantity, cartId, menu_item_id]
      );
    } else {
      await client.query(
        `INSERT INTO cart_items (cart_id, menu_item_id, quantity, unit_price, total_price, special_instructions)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [cartId, menu_item_id, quantity, menuItem.price, menuItem.price * quantity, special_instructions]
      );
    }

    await client.query('COMMIT');
    const cart = await getCartData(cartId);
    return success(res, cart, 'Bidhaa imeongezwa kwenye tiketi ya mgahawa');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    return error(res, 'Imeshindwa kuongeza', 500);
  } finally {
    client.release();
  }
};

// PUT /api/cart/item/:itemId
const updateCartItem = async (req, res) => {
  try {
    const { itemId } = req.params;
    const { quantity } = req.body;
    const customerId = req.user.id;

    if (quantity < 1) return error(res, 'Quantity lazima iwe 1+', 400);

    const itemResult = await pool.query(
      `SELECT ci.*, c.id AS cart_id FROM cart_items ci
       JOIN carts c ON ci.cart_id = c.id
       WHERE ci.id = $1 AND c.customer_id = $2`,
      [itemId, customerId]
    );
    if (itemResult.rows.length === 0) return error(res, 'Cart item haipo', 404);

    await pool.query(
      'UPDATE cart_items SET quantity = $1, total_price = $1 * unit_price WHERE id = $2',
      [quantity, itemId]
    );

    const cart = await getCartData(itemResult.rows[0].cart_id);
    return success(res, cart, 'Cart item imesasishwa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kusasisha', 500);
  }
};

// DELETE /api/cart/item/:itemId
const removeFromCart = async (req, res) => {
  try {
    const { itemId } = req.params;
    const customerId = req.user.id;

    const itemResult = await pool.query(
      `SELECT ci.*, c.id AS cart_id FROM cart_items ci
       JOIN carts c ON ci.cart_id = c.id
       WHERE ci.id = $1 AND c.customer_id = $2`,
      [itemId, customerId]
    );
    if (itemResult.rows.length === 0) return error(res, 'Cart item haipo', 404);

    await pool.query('DELETE FROM cart_items WHERE id = $1', [itemId]);
    const cart = await getCartData(itemResult.rows[0].cart_id);
    return success(res, cart, 'Bidhaa imeondolewa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kuondoa', 500);
  }
};

// DELETE /api/cart
const clearCart = async (req, res) => {
  try {
    const customerId = req.user.id;
    const cartId = req.params.cartId ? Number(req.params.cartId) : null;
    if (cartId !== null && (!Number.isInteger(cartId) || cartId < 1)) {
      return error(res, 'Cart ID si sahihi', 400);
    }
    if (cartId === null) {
      await pool.query(
        `DELETE FROM cart_items WHERE cart_id IN
         (SELECT id FROM carts WHERE customer_id = $1)`, [customerId]
      );
      await pool.query(
        `DELETE FROM carts WHERE customer_id = $1`, [customerId]
      );
      return success(res, null, 'Vikapu vyote vimeondolewa');
    }

    await pool.query(
      'DELETE FROM cart_items WHERE cart_id = $1 AND cart_id IN (SELECT id FROM carts WHERE customer_id = $2)',
      [cartId, customerId]
    );
    const result = await pool.query(
      'DELETE FROM carts WHERE id = $1 AND customer_id = $2 RETURNING id',
      [cartId, customerId]
    );
    if (result.rows.length === 0) return error(res, 'Cart haipo', 404);
    return success(res, { cart_id: cartId }, 'Tiketi imeondolewa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kufuta', 500);
  }
};

// POST /api/cart/promo
const applyPromo = async (req, res) => {
  try {
    const { promo_code } = req.body;
    const cartId = Number(req.body.cart_id);
    if (!Number.isInteger(cartId) || cartId < 1) {
      return error(res, 'Cart ID si sahihi', 400);
    }
    const customerId = req.user.id;

    const promoResult = await pool.query(
      `SELECT * FROM promotions WHERE UPPER(code) = UPPER($1) AND is_active = TRUE
       AND starts_at <= NOW() AND expiry_date > NOW()`,
      [promo_code]
    );
    if (promoResult.rows.length === 0) return error(res, 'Promo code si sahihi', 400);

    const cartResult = await pool.query(
      `SELECT c.id, COALESCE(SUM(ci.total_price), 0) AS subtotal
       FROM carts c LEFT JOIN cart_items ci ON ci.cart_id = c.id
       WHERE c.customer_id = $1 AND c.id = $2 GROUP BY c.id`,
      [customerId, cartId]
    );
    if (cartResult.rows.length === 0) return error(res, 'Cart haipo', 404);
    if (Number(cartResult.rows[0].subtotal) < Number(promoResult.rows[0].min_order_amount || 0)) {
      return error(res, 'Kiasi cha chini cha oda hakijafikiwa', 400);
    }

    await pool.query(
      'UPDATE carts SET promo_code = $1 WHERE id = $2',
      [promo_code, cartResult.rows[0].id]
    );

    const cart = await getCartData(cartResult.rows[0].id);
    return success(res, cart, 'Promo code imetumika');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kutumia promo', 500);
  }
};

module.exports = {
  getCart,
  quoteCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
  applyPromo,
  calculateCartTotal,
};
