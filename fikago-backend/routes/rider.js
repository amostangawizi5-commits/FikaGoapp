// ============================================================
// FIKAGO - RIDER ROUTES
// ============================================================
const express = require('express');
const router = express.Router();
const {
  updateStatus, updateLocation, getAssignments, acceptAssignment, declineAssignment,
  markPickedUp, markDelivered, getWallet,
} = require('../controllers/riderController');
const { authenticate, authorize } = require('../middlewares/auth');

router.use(authenticate);
router.use(authorize('rider'));

router.put('/status', updateStatus);
router.put('/location', updateLocation);
router.get('/assignments', getAssignments);
router.post('/assignments/:id/accept', acceptAssignment);
router.post('/assignments/:id/decline', declineAssignment);
router.put('/assignments/:id/pickup', markPickedUp);
router.put('/assignments/:id/deliver', markDelivered);
router.get('/wallet', getWallet);

module.exports = router;
