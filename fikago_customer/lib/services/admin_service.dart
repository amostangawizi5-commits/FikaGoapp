import '../config/api_config.dart';
import 'api_service.dart';

class AdminService {
  static Future<
      Map<String,
          dynamic>> getPeople(String role, {String search = ''}) => ApiService.get(
      '${ApiConfig.admin}/people?role=$role&search=${Uri.encodeQueryComponent(search)}');

  static Future<Map<String, dynamic>> updatePerson(
          String role, int id, String action) =>
      ApiService.put('${ApiConfig.admin}/people/$role/$id', {'action': action});

  static Future<Map<String, dynamic>> updateVendor(
          int id, Map<String, dynamic> values) =>
      ApiService.put('${ApiConfig.admin}/people/vendor/$id', {
        'action': 'edit',
        ...values,
      });

  static Future<Map<String, dynamic>> getPersonDetails(String role, int id) =>
      ApiService.get('${ApiConfig.admin}/people/$role/$id/details');

  static Future<Map<String, dynamic>> getOrders(
          {String search = '',
          String status = 'all',
          String paymentStatus = 'all'}) =>
      ApiService.get(
          '${ApiConfig.admin}/orders?search=${Uri.encodeQueryComponent(search)}&status=$status&payment_status=$paymentStatus');

  static Future<Map<String, dynamic>> getOrder(int id) =>
      ApiService.get('${ApiConfig.admin}/orders/$id');
  static Future<Map<String, dynamic>> cancelOrder(int id,
          {String reason = ''}) =>
      ApiService.put(
          '${ApiConfig.admin}/orders/$id/cancel', {'reason': reason});
  static Future<Map<String, dynamic>> refundOrder(int id, String reason) =>
      ApiService.post(
          '${ApiConfig.admin}/orders/$id/refund', {'reason': reason});

  static Future<Map<String, dynamic>> getPromotions() =>
      ApiService.get('${ApiConfig.admin}/promotions');
  static Future<Map<String, dynamic>> createPromotion(
          Map<String, dynamic> values) =>
      ApiService.post('${ApiConfig.admin}/promotions', values);
  static Future<Map<String, dynamic>> updatePromotion(int id, bool active) =>
      ApiService.put(
          '${ApiConfig.admin}/promotions/$id', {'is_active': active});
  static Future<Map<String, dynamic>> deletePromotion(int id) =>
      ApiService.delete('${ApiConfig.admin}/promotions/$id');

  static Future<Map<String, dynamic>> getComplaints({String status = 'all'}) =>
      ApiService.get('${ApiConfig.admin}/complaints?status=$status');
  static Future<Map<String, dynamic>> updateComplaint(int id, String status,
          {String? resolution}) =>
      ApiService.put('${ApiConfig.admin}/complaints/$id',
          {'status': status, if (resolution != null) 'resolution': resolution});
}
