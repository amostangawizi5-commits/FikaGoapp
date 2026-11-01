// ============================================================
// FIKAGO - CART ROUTES
// ============================================================
const express = require('express');
const router = express.Router();
const {
  getCart,
  quoteCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
  applyPromo,
} = require('../controllers/cartController');

const { authenticate, authorize } = require('../middlewares/auth');

router.use(authenticate);
router.use(authorize('customer'));

router.get('/', getCart);
router.post('/quote', quoteCart);
router.post('/add', addToCart);
router.put('/item/:itemId', updateCartItem);
router.delete('/item/:itemId', removeFromCart);
router.delete('/:cartId', clearCart);
router.delete('/', clearCart);
router.post('/promo', applyPromo);

module.exports = router;
