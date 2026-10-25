// ============================================================
// FIKAGO - VENDOR SERVICE
// ============================================================
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class VendorService {
  static Future<Map<String, dynamic>> getProfile() =>
      ApiService.get(ApiConfig.vendorProfile);

  static Future<Map<String, dynamic>> updateProfile(
          Map<String, dynamic> values) =>
      ApiService.put(ApiConfig.vendorProfile, values);

  static Future<Map<String, dynamic>> getReviews() =>
      ApiService.get(ApiConfig.vendorReviews);

  static Future<Map<String, dynamic>> getOrders({String? status}) {
    final url = status == null
        ? ApiConfig.vendorOrders
        : '${ApiConfig.vendorOrders}?status=$status';
    return ApiService.get(url);
  }

  static Future<Map<String, dynamic>> acceptOrder(int orderId,
      {int preparationTimeMinutes = 20}) {
    return ApiService.put('${ApiConfig.vendorOrders}/$orderId/accept', {
      'preparation_time_minutes': preparationTimeMinutes,
    });
  }

  static Future<Map<String, dynamic>> rejectOrder(int orderId,
          {String? reason}) =>
      ApiService.put('${ApiConfig.vendorOrders}/$orderId/reject', {
        if (reason != null) 'reason': reason,
      });

  static Future<Map<String, dynamic>> updateOrderStatus(
          int orderId, String status) =>
      ApiService.put(
          '${ApiConfig.vendorOrders}/$orderId/status', {'status': status});

  // 1. Pata Menyu ya Mgahawa
  static Future<Map<String, dynamic>> getMenu() {
    return ApiService.get(ApiConfig.vendorMenu);
  }

  // 2. Ongeza Bidhaa (Pamoja na Image URL)
  static Future<Map<String, dynamic>> addMenuItem({
    required String name,
    required String categoryName,
    required double price,
    String? description,
    String? imageUrl, // <--- Ongeza hii
    List<Map<String, dynamic>> extras = const [],
    int preparationTime = 15,
  }) {
    return ApiService.post(ApiConfig.vendorMenuItems, {
      'name': name,
      'category_name': categoryName,
      'price': price,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (imageUrl != null) 'image_url': imageUrl, // <--- Tuma URL ya picha
      'preparation_time': preparationTime,
      'extras': extras,
    });
  }

  // 3. Update Bidhaa (Availability)
  static Future<Map<String, dynamic>> updateMenuItem({
    required int itemId,
    required bool isAvailable,
    String? name,
    String? categoryName,
    String? description,
    double? price,
    String? imageUrl,
    List<Map<String, dynamic>>? extras,
  }) {
    return ApiService.put(
      '${ApiConfig.vendorMenuItems}/$itemId',
      {
        'is_available': isAvailable,
        if (name != null) 'name': name,
        if (categoryName != null) 'category_name': categoryName,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (imageUrl != null) 'image_url': imageUrl,
        if (extras != null) 'extras': extras,
      },
    );
  }

  // 4. Futa Bidhaa
  static Future<Map<String, dynamic>> deleteMenuItem(int itemId) {
    return ApiService.delete('${ApiConfig.vendorMenuItems}/$itemId');
  }

  // ============================================================
  // 5. PAKIA PICHA (UPLOAD IMAGE) - MPYA
  // ============================================================
  static Future<Map<String, dynamic>> uploadImage(XFile imageFile) async {
    return _uploadImage(imageFile, 'menu');
  }

  static Future<Map<String, dynamic>> uploadRestaurantImage(
      XFile imageFile) async {
    return _uploadImage(imageFile, 'restaurant');
  }

  static Future<Map<String, dynamic>> _uploadImage(
      XFile imageFile, String folder) async {
    try {
      // Tengeneza Multipart Request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/upload/$folder'),
      );
      request.headers.addAll(ApiService.multipartHeaders);

      // Upload the bytes so this works on web, where dart:io File is unavailable.
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
          contentType: MediaType.parse(_imageMimeType(imageFile.name)),
        ),
      );

      // Tuma Request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Decode Response
      final data = jsonDecode(response.body);

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Imeshindwa kupakia picha: $e',
      };
    }
  }

  static String _imageMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
