// ============================================================
// FIKAGO - AUTH MIDDLEWARE
// ============================================================
const { verifyToken } = require('../utils/jwt');
const { error } = require('../utils/response');
const pool = require('../config/db');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return error(res, 'No token provided', 401);
    }
    const token = authHeader.split(' ')[1];
    const user = verifyToken(token);
    const account = await pool.query('SELECT is_active, role FROM users WHERE id = $1', [user.id]);
    if (!account.rows.length || account.rows[0].is_active === false || account.rows[0].role !== user.role) {
      return error(res, 'Akaunti imesimamishwa au haipatikani', 403);
    }
    if (user.role === 'vendor') {
      const restaurant = await pool.query('SELECT is_approved, is_active FROM restaurants WHERE owner_id = $1', [user.id]);
      if (!restaurant.rows.length || !restaurant.rows[0].is_approved || !restaurant.rows[0].is_active) {
        return error(res, 'Akaunti ya mgahawa inasubiri idhini au imesimamishwa', 403);
      }
    }
    if (user.role === 'rider') {
      const rider = await pool.query('SELECT is_approved FROM rider_profiles WHERE user_id = $1', [user.id]);
      if (!rider.rows.length || !rider.rows[0].is_approved) {
        return error(res, 'Akaunti ya rider inasubiri idhini au imekataliwa', 403);
      }
    }
    req.user = user;
    next();
  } catch (err) {
    return error(res, 'Invalid or expired token', 401);
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) return error(res, 'Unauthorized', 401);
    if (!roles.includes(req.user.role)) {
      return error(res, `Access denied. Required: ${roles.join(' or ')}`, 403);
    }
    next();
  };
};

module.exports = { authenticate, authorize };
