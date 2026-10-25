// ============================================================
// FIKAGO - RESTAURANT CONTROLLER
// ============================================================
const pool = require('../config/db');
const { success, error } = require('../utils/response');

// GET /api/restaurants
const listRestaurants = async (req, res) => {
  try {
    const { search, category } = req.query;
    let query = `
      SELECT r.id, r.name, r.description, r.phone_number, r.logo_url, r.cover_image_url,
             r.address, r.latitude, r.longitude, r.opening_time, r.closing_time,
             r.rating_avg, r.is_active,
             COALESCE(to_jsonb(r)->>'category', to_jsonb(r)->>'service_category') AS category
      FROM restaurants r
      WHERE r.is_approved = TRUE AND r.is_active = TRUE
    `;
    const params = [];
    if (search) {
      params.push(`%${search}%`);
      query += ` AND (r.name ILIKE $1 OR r.description ILIKE $1)`;
    }
    if (category) {
      params.push(category);
      query += ` AND lower(COALESCE(to_jsonb(r)->>'category', to_jsonb(r)->>'service_category', '')) = lower($${params.length})`;
    }
    query += ' ORDER BY r.rating_avg DESC, r.name ASC';

    const result = await pool.query(query, params);
    return success(res, result.rows, 'Restaurants zimepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata restaurants', 500);
  }
};

// GET /api/restaurants/:id
const getRestaurant = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM restaurants WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return error(res, 'Restaurant haipo', 404);
    return success(res, result.rows[0], 'Restaurant imepatikana');
  } catch (err) {
    return error(res, 'Imeshindwa kupata restaurant', 500);
  }
};

// GET /api/restaurants/:id/menu
const getRestaurantMenu = async (req, res) => {
  try {
    const { id } = req.params;
    const categoriesResult = await pool.query(
      `SELECT id, name, sort_order FROM menu_categories
       WHERE restaurant_id = $1 AND is_active = TRUE
       ORDER BY sort_order ASC`, [id]
    );

    const menu = [];
    for (const category of categoriesResult.rows) {
      const itemsResult = await pool.query(
        `SELECT id, name, description, price, image_url, preparation_time, is_available
         FROM menu_items
         WHERE category_id = $1 AND restaurant_id = $2 AND is_available = TRUE
         ORDER BY name ASC`, [category.id, id]
      );
      menu.push({
        category: category.name,
        category_id: category.id,
        items: itemsResult.rows,
      });
    }

    return success(res, { restaurant_id: parseInt(id), menu }, 'Menu imepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata menu', 500);
  }
};

// GET /api/restaurants/category/:category/items
// List available products from every approved restaurant for a home category.
const getCategoryItems = async (req, res) => {
  try {
    const category = String(req.params.category || '').trim().toLowerCase();
    const categoryAliases = {
      food: ['food', 'chakula'],
      groceries: ['grocery', 'groceries', 'vyakula'],
      shops: ['shop', 'shops', 'maduka'],
      liquor: ['drink', 'drinks', 'liquor', 'vileo'],
      pharmacy: ['pharmacy', 'duka la dawa'],
      salons: ['salon', 'salons', 'saluni'],
      parcels: ['parcel', 'parcels', 'kifurushi', 'vifurushi'],
    };
    const names = categoryAliases[category] || [category];
    const result = await pool.query(
      `SELECT mi.id, mi.restaurant_id, mi.category_id, mi.name, mi.description,
              mi.price, mi.image_url, mi.preparation_time, mi.is_available,
              r.name AS restaurant_name, mc.name AS category_name
       FROM menu_items mi
       JOIN restaurants r ON r.id = mi.restaurant_id
       JOIN menu_categories mc ON mc.id = mi.category_id
       WHERE r.is_approved = TRUE AND r.is_active = TRUE
         AND mi.is_available = TRUE AND mc.is_active = TRUE
         AND LOWER(BTRIM(mc.name)) = ANY($1::text[])
       ORDER BY mi.name ASC, r.name ASC`,
      [names]
    );
    return success(res, result.rows, 'Bidhaa za category zimepatikana');
  } catch (err) {
    console.error('Category menu lookup failed:', err.message);
    return error(res, 'Imeshindwa kupata bidhaa za category', 500);
  }
};

// GET /api/restaurants/search/menu?q=wali
const searchMenuItems = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q) return error(res, 'query (q) inahitajika', 400);

    const result = await pool.query(
      `SELECT mi.id, mi.name, mi.description, mi.price, mi.image_url,
              mi.is_available, r.id AS restaurant_id, r.name AS restaurant_name,
              mc.name AS category_name
       FROM menu_items mi
       JOIN restaurants r ON mi.restaurant_id = r.id
       JOIN menu_categories mc ON mi.category_id = mc.id
       WHERE (mi.name ILIKE $1 OR mi.description ILIKE $1)
         AND mi.is_available = TRUE AND r.is_approved = TRUE
       ORDER BY mi.name ASC LIMIT 50`, [`%${q}%`]
    );
    return success(res, result.rows, 'Matokeo ya utafutaji');
  } catch (err) {
    return error(res, 'Imeshindwa kutafuta', 500);
  }
};

module.exports = {
  listRestaurants,
  getRestaurant,
  getRestaurantMenu,
  getCategoryItems,
  searchMenuItems,
};
