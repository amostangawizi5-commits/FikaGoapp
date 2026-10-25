// ============================================================
// FIKAGO - VALIDATION MIDDLEWARE
// ============================================================
const { error } = require('../utils/response');
const { normalizeTzPhone } = require('../utils/phone');

const validatePhone = (phone) => {
  return normalizeTzPhone(phone) !== null;
};

const validatePhoneMiddleware = (req, res, next) => {
  const { phone_number } = req.body;
  if (!phone_number) return error(res, 'phone_number inahitajika', 400);
  if (!validatePhone(phone_number)) {
    return error(res, 'phone_number si sahihi (mfano: +255712345678)', 400);
  }
  req.body.phone_number = normalizeTzPhone(phone_number);
  next();
};

module.exports = { validatePhone, validatePhoneMiddleware };
