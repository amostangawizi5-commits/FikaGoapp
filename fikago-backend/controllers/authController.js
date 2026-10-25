// ============================================================
// FIKAGO - AUTH CONTROLLER
// ============================================================
const pool = require('../config/db');
const { success, error } = require('../utils/response');
const { generateToken } = require('../utils/jwt');
const { createAndSendOTP, verifyOTP } = require('../services/otpService');
const { normalizeTzPhone, phoneCandidates } = require('../utils/phone');

const normalizeVehicleType = (value) => {
  const normalized = String(value || '').trim().toLowerCase();
  const vehicleTypes = {
    pikipiki: 'motorcycle',
    motorcycle: 'motorcycle',
    motorbike: 'motorcycle',
    baiskeli: 'bicycle',
    bicycle: 'bicycle',
    bike: 'bicycle',
    gari: 'car',
    car: 'car',
  };
  return vehicleTypes[normalized] || '';
};

// POST /api/auth/send-otp
const sendOTP = async (req, res) => {
  try {
    const { purpose = 'login' } = req.body;
    const phone_number = normalizeTzPhone(req.body.phone_number);
    if (!phone_number) return error(res, 'Namba ya simu si sahihi (mfano: +255712345678)', 400);
    const result = await createAndSendOTP(phone_number, purpose);
    if (!result.success) return error(res, result.error, 500);

    return success(res, {
      phone_number,
      otp_sent: true,
      expires_in_minutes: parseInt(process.env.OTP_EXPIRY_MINUTES) || 5,
      // DEV ONLY: Onyesha OTP kwenye response
      dev_otp: process.env.NODE_ENV === 'development' ? result.otp : undefined,
    }, 'OTP imetumwa kwa simu yako');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kutuma OTP', 500);
  }
};

// POST /api/auth/verify-otp
const verifyOTPAndLogin = async (req, res) => {
  try {
    const { otp_code, full_name, email, role } = req.body;
    const phone_number = normalizeTzPhone(req.body.phone_number);
    if (!phone_number) return error(res, 'Namba ya simu si sahihi (mfano: +255712345678)', 400);

    const otpResult = await verifyOTP(phone_number, otp_code, 'login');
    if (!otpResult.success) return error(res, otpResult.error, 400);

    let userResult = await pool.query(
      'SELECT * FROM users WHERE phone_number = ANY($1::text[]) ORDER BY CASE WHEN phone_number = $2 THEN 0 ELSE 1 END LIMIT 1',
      [phoneCandidates(phone_number), phone_number]
    );

    let user;
    let isNewUser = false;

    if (userResult.rows.length === 0) {
      isNewUser = true;
      if (!full_name) return error(res, 'full_name inahitajika kwa mtumiaji mpya', 400);

      const newUser = await pool.query(
        `INSERT INTO users (phone_number, full_name, email, role, is_verified)
         VALUES ($1, $2, $3, $4, TRUE)
         RETURNING id, phone_number, full_name, email, role`,
        [phone_number, full_name, email || null, role || 'customer']
      );
      user = newUser.rows[0];
    } else {
      if (userResult.rows[0].is_active === false) {
        return error(res, 'Akaunti hii imesimamishwa. Wasiliana na FikaGo support.', 403);
      }
      await pool.query('UPDATE users SET is_verified = TRUE WHERE id = $1', [userResult.rows[0].id]);
      user = userResult.rows[0];
    }

    const token = generateToken({
      id: user.id,
      phone_number: normalizeTzPhone(user.phone_number) || user.phone_number,
      role: user.role,
    });

    return success(res, { user, token, is_new_user: isNewUser },
      isNewUser ? 'Usajili umefanikiwa' : 'Login imefanikiwa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kuthibitisha OTP', 500);
  }
};

// GET /api/auth/profile
const getProfile = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, phone_number, full_name, email, role, profile_image_url,
              language_pref, is_verified, is_active, created_at
       FROM users WHERE id = $1`, [req.user.id]
    );
    if (result.rows.length === 0) return error(res, 'User haipo', 404);
    return success(res, result.rows[0], 'Profile imepatikana');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kupata profile', 500);
  }
};

// PUT /api/auth/profile
const updateProfile = async (req, res) => {
  try {
    const { full_name, email, language_pref } = req.body;
    const result = await pool.query(
      `UPDATE users SET full_name = COALESCE($1, full_name),
                        email = COALESCE($2, email),
                        language_pref = COALESCE($3, language_pref),
                        updated_at = NOW()
       WHERE id = $4
       RETURNING id, phone_number, full_name, email, role, language_pref`,
      [full_name, email, language_pref, req.user.id]
    );
    return success(res, result.rows[0], 'Profile imesasishwa');
  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kusasisha profile', 500);
  }
};

// ============================================================
// REGISTER WITH PASSWORD
// POST /api/auth/register
// ============================================================
const registerWithPassword = async (req, res) => {
  let client;
  let transactionStarted = false;

  try {
    const {
      password,
      full_name,
      email,
      role,
      restaurant_name,
      restaurant_location,
      vehicle_type: requestedVehicleType,
      license_number,
      license_plate,
    } = req.body;
    const vehicle_type = normalizeVehicleType(requestedVehicleType);
    const phone_number = normalizeTzPhone(req.body.phone_number);
    if (!phone_number) return error(res, 'Namba ya simu si sahihi (mfano: +255712345678)', 400);
    const accountRole = ['vendor', 'rider'].includes(role) ? role : 'customer';

    // 1. Hakikisha namba ipo
    if (!phone_number || !password || !full_name) {
      return error(res, 'phone_number, password na full_name zinahitajika', 400);
    }
    if (accountRole === 'vendor' && (!email || !restaurant_name || !restaurant_location)) {
      return error(res, 'Jina la mgahawa, simu, email na eneo vinahitajika kwa usajili wa vendor.', 400);
    }
    if (accountRole === 'rider' && (!vehicle_type || !license_number || !license_plate)) {
      return error(res, 'Aina ya usafiri, namba ya leseni na namba ya gari vinahitajika kwa usajili wa rider.', 400);
    }

    // 2. Angalia kama namba au email imetumika
    const existing = await pool.query(
      `SELECT phone_number, email
       FROM users
       WHERE phone_number = ANY($1::text[])
          OR ($2::text IS NOT NULL AND LOWER(email) = LOWER($2))
       LIMIT 1`,
      [phoneCandidates(phone_number), email || null]
    );

    if (existing.rows.length > 0) {
      const matchedUser = existing.rows[0];
      if (phoneCandidates(phone_number).includes(matchedUser.phone_number)) {
        return error(res, 'Namba hii imesajiliwa tayari. Tafadhali ingia kwenye akaunti yako.', 409);
      }
      return error(res, 'Email hii imesajiliwa tayari. Tafadhali ingia kwenye akaunti yako au tumia email nyingine.', 409);
    }

    // 3. Hash password
    const bcrypt = require('bcrypt');
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create the account and restaurant together so vendor signups stay complete.
    client = await pool.connect();
    await client.query('BEGIN');
    transactionStarted = true;

    const newUser = await client.query(
      `INSERT INTO users (phone_number, full_name, email, password_hash, role, is_verified)
       VALUES ($1, $2, $3, $4, $5, TRUE)
       RETURNING id, phone_number, full_name, email, role`,
      [phone_number, full_name, email || null, hashedPassword, accountRole]
    );

    const user = newUser.rows[0];

    if (accountRole === 'vendor') {
      await client.query(
        `INSERT INTO restaurants (owner_id, name, phone_number, address, is_active, is_approved, approval_status)
         VALUES ($1, $2, $3, $4, FALSE, FALSE, 'pending')`,
        [user.id, restaurant_name, phone_number, restaurant_location]
      );
    }
    if (accountRole === 'rider') {
      await client.query(
        `INSERT INTO rider_profiles
          (user_id, vehicle_type, license_number, license_plate, is_approved, approval_status)
         VALUES ($1, $2, $3, $4, FALSE, 'pending')`,
        [user.id, vehicle_type, license_number, license_plate]
      );
    }

    await client.query('COMMIT');
    transactionStarted = false;

    // 5. Tengeneza JWT Token
    const token = generateToken({
      id: user.id,
      phone_number: normalizeTzPhone(user.phone_number) || user.phone_number,
      role: user.role,
    });

    return success(res, { user, token }, 'Usajili umefanikiwa', 201);

  } catch (err) {
    if (transactionStarted && client) {
      await client.query('ROLLBACK').catch(() => {});
    }
    // Handle races where two registration requests pass the pre-check together.
    if (err.code === '23505') {
      if (err.constraint === 'users_email_key') {
        return error(res, 'Email hii imesajiliwa tayari. Tafadhali ingia kwenye akaunti yako au tumia email nyingine.', 409);
      }
      if (err.constraint === 'users_phone_number_key') {
        return error(res, 'Namba hii imesajiliwa tayari. Tafadhali ingia kwenye akaunti yako.', 409);
      }
    }
    console.error(err);
    return error(res, 'Imeshindwa kusajili', 500);
  } finally {
    client?.release();
  }
};

// ============================================================
// LOGIN WITH PASSWORD
// POST /api/auth/login
// ============================================================
const loginWithPassword = async (req, res) => {
  try {
    const { password } = req.body;
    const requestedRole = ['customer', 'vendor', 'rider', 'admin'].includes(req.body.role)
      ? req.body.role
      : null;
    const phone_number = normalizeTzPhone(req.body.phone_number);

    // 1. Hakikisha namba na password zipo
    if (!phone_number || !password) {
      return error(res, 'phone_number na password zinahitajika', 400);
    }

    // 2. Pata user
    const result = await pool.query(
      `SELECT * FROM users
       WHERE phone_number = ANY($1::text[]) AND ($3::text IS NULL OR role = $3)
       ORDER BY CASE WHEN phone_number = $2 THEN 0 ELSE 1 END`,
      [phoneCandidates(phone_number), phone_number, requestedRole]
    );

    if (result.rows.length === 0) {
      return error(res, 'Namba au password si sahihi', 401);
    }

    // Equivalent phone formats can exist in older databases. Check every
    // matching row (and the selected role) instead of failing on the first one.
    const bcrypt = require('bcrypt');
    let user = null;
    let hasPasswordHash = false;
    for (const candidate of result.rows) {
      if (!candidate.password_hash) continue;
      hasPasswordHash = true;
      if (await bcrypt.compare(password, candidate.password_hash)) {
        user = candidate;
        break;
      }
    }

    if (!user && !hasPasswordHash) {
      return error(res, 'Akaunti hii inatumia OTP. Tafadhali login kwa OTP.', 400);
    }
    if (!user) {
      return error(res, 'Namba au password si sahihi', 401);
    }

    if (user.is_active === false) {
      return error(res, 'Akaunti hii imesimamishwa. Wasiliana na FikaGo support.', 403);
    }

    // 5. Tengeneza Token
    const token = generateToken({
      id: user.id,
      phone_number: normalizeTzPhone(user.phone_number) || user.phone_number,
      role: user.role,
    });

    return success(res, {
      user: {
        id: user.id,
        phone_number: user.phone_number,
        full_name: user.full_name,
        email: user.email,
        role: user.role,
      },
      token,
    }, 'Login imefanikiwa');

  } catch (err) {
    console.error(err);
    return error(res, 'Imeshindwa kuingia', 500);
  }
};
module.exports = {
  sendOTP,
  verifyOTPAndLogin,
  getProfile,
  updateProfile,
  registerWithPassword,
  loginWithPassword,
};
