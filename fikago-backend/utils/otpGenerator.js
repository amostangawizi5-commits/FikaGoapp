// ============================================================
// FIKAGO - OTP GENERATOR
// ============================================================

const generateOTP = (length = 6) => {
  let otp = '';
  for (let i = 0; i < length; i++) {
    otp += Math.floor(Math.random() * 10);
  }
  return otp;
};

const getOTPExpiry = (minutes = 5) => {
  const expiry = new Date();
  expiry.setMinutes(expiry.getMinutes() + minutes);
  return expiry;
};

module.exports = { generateOTP, getOTPExpiry };
