import '../config/api_config.dart';
import 'api_service.dart';

class RiderService {
  static Future<Map<String, dynamic>> getAssignments({
    String status = 'new',
  }) =>
      ApiService.get('${ApiConfig.baseUrl}/api/rider/assignments?status=$status');

  static Future<Map<String, dynamic>> updateStatus(bool isOnline) =>
      ApiService.put(
        '${ApiConfig.baseUrl}/api/rider/status',
        {'is_online': isOnline},
      );

  static Future<Map<String, dynamic>> acceptAssignment(int assignmentId) =>
      ApiService.post(
        '${ApiConfig.baseUrl}/api/rider/assignments/$assignmentId/accept',
        {},
      );

  static Future<Map<String, dynamic>> declineAssignment(int assignmentId) =>
      ApiService.post(
        '${ApiConfig.baseUrl}/api/rider/assignments/$assignmentId/decline',
        {},
      );

  static Future<Map<String, dynamic>> getWallet() =>
      ApiService.get('${ApiConfig.baseUrl}/api/rider/wallet');
}
