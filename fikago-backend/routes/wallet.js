// ============================================================
// FIKAGO - WALLET ROUTES
// ============================================================
const express = require('express');
const router = express.Router();
const { getWallet, getTransactions } = require('../controllers/walletController');
const { authenticate, authorize } = require('../middlewares/auth');

router.use(authenticate);
router.use(authorize('customer'));

router.get('/', getWallet);
router.get('/transactions', getTransactions);

module.exports = router;
