// ============================================================
// FIKAGO - RESTAURANT SERVICE
// ============================================================
import '../config/api_config.dart';
import 'api_service.dart';

class RestaurantService {
  // Get all restaurants
  static Future<Map<String, dynamic>> getRestaurants({
    String? search,
    String? category,
  }) async {
    final query = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category.isNotEmpty) 'category': category,
    };
    final url = query.isEmpty
        ? ApiConfig.restaurants
        : Uri.parse(ApiConfig.restaurants)
            .replace(queryParameters: query)
            .toString();
    return await ApiService.get(url);
  }

  // Get single restaurant
  static Future<Map<String, dynamic>> getRestaurant(int id) async {
    return await ApiService.get('${ApiConfig.restaurants}/$id');
  }

  // Get restaurant menu
  static Future<Map<String, dynamic>> getMenu(int restaurantId) async {
    return await ApiService.get('${ApiConfig.restaurants}/$restaurantId/menu');
  }

  // Get available items across all restaurants for one home category.
  static Future<Map<String, dynamic>> getCategoryItems(String category) async {
    final encodedCategory = Uri.encodeComponent(category);
    return ApiService.get(
      '${ApiConfig.restaurants}/category/$encodedCategory/items',
    );
  }

  static Future<Map<String, dynamic>> getFeaturedMenuItems() async =>
      ApiService.get(ApiConfig.featuredMenu);

  // Search menu items
  static Future<Map<String, dynamic>> searchMenu(String query) async {
    final url = Uri.parse(ApiConfig.searchMenu)
        .replace(queryParameters: {'q': query}).toString();
    return await ApiService.get(url);
  }
}
