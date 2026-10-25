// ============================================================
// FIKAGO - PAYMENT ROUTES
// ============================================================
const express = require('express');
const router = express.Router();
const { initiateOrderPayment } = require('../controllers/paymentController');
const { authenticate, authorize } = require('../middlewares/auth');

router.use(authenticate);
router.use(authorize('customer'));

router.post('/initiate', initiateOrderPayment);

module.exports = router;
