// ============================================================
// FIKAGO - ORDER ROUTES
// ============================================================
const express = require('express');
const router = express.Router();
const {
  createOrder,
  getMyOrders,
  getOrder,
  cancelOrder,
  confirmDelivery,
  createComplaint,
  createReview,
} = require('../controllers/orderController');
const { authenticate, authorize } = require('../middlewares/auth');

router.use(authenticate);

router.post('/', authorize('customer'), createOrder);
router.get('/', authorize('customer'), getMyOrders);
router.get('/:id', getOrder);
router.put('/:id/cancel', authorize('customer'), cancelOrder);
router.put('/:id/confirm-delivery', authorize('customer'), confirmDelivery);
router.post('/:id/complaints', authorize('customer'), createComplaint);
router.post('/:id/reviews', authorize('customer'), createReview);

module.exports = router;
