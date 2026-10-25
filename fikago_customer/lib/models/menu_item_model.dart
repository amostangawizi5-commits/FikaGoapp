// ============================================================
// FIKAGO - MENU ITEM MODEL
// ============================================================

class MenuItem {
  final int id;
  final int restaurantId;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int preparationTime;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.restaurantId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.preparationTime = 15,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      restaurantId: json['restaurant_id'] ?? 0,
      categoryId: json['category_id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'],
      preparationTime: json['preparation_time'] ?? 15,
      isAvailable: json['is_available'] ?? true,
    );
  }
}

class MenuCategory {
  final int categoryId;
  final String category;
  final List<MenuItem> items;

  MenuCategory({
    required this.categoryId,
    required this.category,
    required this.items,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      categoryId: json['category_id'] ?? 0,
      category: json['category'] ?? '',
      items: (json['items'] as List?)
              ?.map((i) => MenuItem.fromJson(i))
              .toList() ??
          [],
    );
  }
}
