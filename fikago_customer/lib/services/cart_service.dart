// ============================================================
// FIKAGO - CART SERVICE
// ============================================================
import '../config/api_config.dart';
import 'api_service.dart';

class CartService {
  // Get cart
  static Future<Map<String, dynamic>> getCart() async {
    return await ApiService.get(ApiConfig.cart);
  }

  static Future<Map<String, dynamic>> quoteCart({
    required int cartId,
    required double latitude,
    required double longitude,
  }) async {
    return await ApiService.post('${ApiConfig.cart}/quote', {
      'cart_id': cartId,
      'delivery_latitude': latitude,
      'delivery_longitude': longitude,
    });
  }

  // Add to cart
  static Future<Map<String, dynamic>> addToCart({
    required int menuItemId,
    int quantity = 1,
    String? specialInstructions,
  }) async {
    return await ApiService.post(
      ApiConfig.addToCart,
      {
        'menu_item_id': menuItemId,
        'quantity': quantity,
        if (specialInstructions != null)
          'special_instructions': specialInstructions,
      },
    );
  }

  // Update cart item
  static Future<Map<String, dynamic>> updateCartItem({
    required int itemId,
    required int quantity,
  }) async {
    return await ApiService.put(
      '${ApiConfig.cart}/item/$itemId',
      {'quantity': quantity},
    );
  }

  // Remove from cart
  static Future<Map<String, dynamic>> removeFromCart(int itemId) async {
    return await ApiService.delete('${ApiConfig.cart}/item/$itemId');
  }

  // Clear cart
  static Future<Map<String, dynamic>> clearCart({int? cartId}) async {
    final url = cartId == null ? ApiConfig.cart : '${ApiConfig.cart}/$cartId';
    return await ApiService.delete(url);
  }

  // Apply promo
  static Future<Map<String, dynamic>> applyPromo(
    String promoCode, {
    required int cartId,
  }) async {
    return await ApiService.post(
      ApiConfig.applyPromo,
      {'promo_code': promoCode, 'cart_id': cartId},
    );
  }
}
