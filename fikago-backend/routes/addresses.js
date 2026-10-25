const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middlewares/auth');
const { listAddresses, createAddress, deleteAddress } = require('../controllers/addressController');

router.use(authenticate, authorize('customer'));
router.get('/', listAddresses);
router.post('/', createAddress);
router.delete('/:id', deleteAddress);

module.exports = router;
