import '../config/api_config.dart';
import 'api_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> initiatePayment({
    required int orderId,
    required String paymentMethod,
  }) async {
    return await ApiService.post(
      ApiConfig.initiatePayment,
      {
        'order_id': orderId,
        'payment_method': paymentMethod,
      },
    );
  }
}
