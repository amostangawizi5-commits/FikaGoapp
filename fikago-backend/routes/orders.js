// ============================================================
// FIKAGO - ORDER ROUTES
// ============================================================
const express = require('express');
const router = express.Router();
const { createOrder, getMyOrders, getOrder, cancelOrder, createComplaint } = require('../controllers/orderController');
const { authenticate, authorize } = require('../middlewares/auth');

router.use(authenticate);

router.post('/', authorize('customer'), createOrder);
router.get('/', authorize('customer'), getMyOrders);
router.get('/:id', getOrder);
router.put('/:id/cancel', authorize('customer'), cancelOrder);
router.post('/:id/complaints', authorize('customer'), createComplaint);

module.exports = router;
