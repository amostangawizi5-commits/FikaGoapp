// ============================================================
// FIKAGO - ORDER SERVICE
// ============================================================
import '../config/api_config.dart';
import 'api_service.dart';

class OrderService {
  // Create order
  static Future<Map<String, dynamic>> createOrder({
    required String deliveryAddress,
    required String customerName,
    String? deliveryLandmark,
    double? deliveryLatitude,
    double? deliveryLongitude,
    required String customerPhone,
    String paymentMethod = 'cash',
    String? specialInstructions,
  }) async {
    return await ApiService.post(
      ApiConfig.orders,
      {
        'delivery_address': deliveryAddress,
        'customer_name': customerName,
        if (deliveryLandmark != null) 'delivery_landmark': deliveryLandmark,
        if (deliveryLatitude != null) 'delivery_latitude': deliveryLatitude,
        if (deliveryLongitude != null) 'delivery_longitude': deliveryLongitude,
        'customer_phone': customerPhone,
        'payment_method': paymentMethod,
        if (specialInstructions != null)
          'special_instructions': specialInstructions,
      },
    );
  }

  // Get my orders
  static Future<Map<String, dynamic>> getMyOrders({String? status}) async {
    final url = status != null
        ? '${ApiConfig.orders}?status=$status'
        : ApiConfig.orders;
    return await ApiService.get(url);
  }

  // Get single order
  static Future<Map<String, dynamic>> getOrder(int id) async {
    return await ApiService.get('${ApiConfig.orders}/$id');
  }

  // Cancel order
  static Future<Map<String, dynamic>> cancelOrder(int id) async {
    return await ApiService.put('${ApiConfig.orders}/$id/cancel', {});
  }

  static Future<Map<String, dynamic>> createComplaint({
    required int orderId,
    required String subject,
    required String description,
  }) =>
      ApiService.post('${ApiConfig.orders}/$orderId/complaints', {
        'subject': subject,
        'description': description,
      });
}
