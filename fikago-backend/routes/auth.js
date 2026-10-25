const express = require('express');
const router = express.Router();

const {
  sendOTP,
  verifyOTPAndLogin,
  getProfile,
  updateProfile,
  registerWithPassword, // ✅
  loginWithPassword,    // ✅
} = require('../controllers/authController');

const { authenticate } = require('../middlewares/auth');
const { validatePhoneMiddleware } = require('../middlewares/validation');

// OTP Routes
router.post('/send-otp', validatePhoneMiddleware, sendOTP);
router.post('/verify-otp', verifyOTPAndLogin);

// Password Routes
router.post('/register', registerWithPassword); // ✅
router.post('/login', loginWithPassword);       // ✅

// Profile Routes
router.get('/profile', authenticate, getProfile);
router.put('/profile', authenticate, updateProfile);

module.exports = router;
