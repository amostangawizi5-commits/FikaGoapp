// ============================================================
// FIKAGO - RESTAURANT ROUTES
// ============================================================
const express = require('express');
const router = express.Router();
const {
  listRestaurants, getRestaurant, getRestaurantMenu, getCategoryItems,
  getFeaturedMenuItems, searchMenuItems,
} = require('../controllers/restaurantController');

router.get('/', listRestaurants);
router.get('/search/menu', searchMenuItems);
router.get('/featured/menu', getFeaturedMenuItems);
router.get('/category/:category/items', getCategoryItems);
router.get('/:id', getRestaurant);
router.get('/:id/menu', getRestaurantMenu);

module.exports = router;
