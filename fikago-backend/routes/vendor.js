// ============================================================
// FIKAGO - VENDOR ROUTES
// ============================================================
const express = require('express');
const router = express.Router();
const {
  getVendorProfile, updateVendorProfile, getVendorReviews, updateOrderStatus,
  getVendorOrders, acceptOrder, rejectOrder, assignRider,
  getAvailableRiders, getVendorMenu, addMenuItem, updateMenuItem,
  deleteMenuItem, getVendorEarnings,
} = require('../controllers/vendorController');
const { authenticate, authorize } = require('../middlewares/auth');

router.use(authenticate);
router.use(authorize('vendor'));

// Restaurant profile and customer feedback
router.get('/profile', getVendorProfile);
router.put('/profile', updateVendorProfile);
router.get('/reviews', getVendorReviews);

// Orders
router.get('/orders', getVendorOrders);
router.put('/orders/:id/accept', acceptOrder);
router.put('/orders/:id/reject', rejectOrder);
router.put('/orders/:id/status', updateOrderStatus);
router.put('/orders/:id/assign-rider', assignRider);
router.get('/riders/available', getAvailableRiders);

// Menu
router.get('/menu', getVendorMenu);
router.post('/menu/items', addMenuItem);
router.put('/menu/items/:id', updateMenuItem);
router.delete('/menu/items/:id', deleteMenuItem);

// Earnings
router.get('/earnings', getVendorEarnings);

module.exports = router;	
