// ============================================================
// FIKAGO - OTP SERVICE
// ============================================================
const pool = require('../config/db');
const { generateOTP, getOTPExpiry } = require('../utils/otpGenerator');
const { sendSMS } = require('./smsService');

const createAndSendOTP = async (phoneNumber, purpose = 'login') => {
  try {
    await pool.query(
      `UPDATE otp_verifications 
       SET is_used = TRUE 
       WHERE phone_number = $1 AND purpose = $2 AND is_used = FALSE`,
      [phoneNumber, purpose]
    );

    const otp = generateOTP(6);
    const expiresAt = getOTPExpiry(parseInt(process.env.OTP_EXPIRY_MINUTES) || 5);

    await pool.query(
      `INSERT INTO otp_verifications (phone_number, otp_code, purpose, expires_at)
       VALUES ($1, $2, $3, $4)`,
      [phoneNumber, otp, purpose, expiresAt]
    );

    await sendSMS(phoneNumber, `FikaGo: Code yako ni ${otp}. Inaisha baada ya dakika 5.`);

    return { success: true, otp };
  } catch (error) {
    console.error('❌ OTP Error:', error.message);
    return { success: false, error: error.message };
  }
};

const verifyOTP = async (phoneNumber, otpCode, purpose = 'login') => {
  try {
    const result = await pool.query(
      `SELECT * FROM otp_verifications 
       WHERE phone_number = $1 
         AND otp_code = $2 
         AND purpose = $3 
         AND is_used = FALSE 
         AND expires_at > NOW()
       ORDER BY created_at DESC 
       LIMIT 1`,
      [phoneNumber, otpCode, purpose]
    );

    if (result.rows.length === 0) {
      return { success: false, error: 'OTP si sahihi au imeisha muda' };
    }

    await pool.query(
      `UPDATE otp_verifications SET is_used = TRUE WHERE id = $1`,
      [result.rows[0].id]
    );

    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

module.exports = { createAndSendOTP, verifyOTP };
