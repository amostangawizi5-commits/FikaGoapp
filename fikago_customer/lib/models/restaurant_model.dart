// ============================================================
// FIKAGO - RESTAURANT MODEL
// ============================================================

class Restaurant {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? openingTime;
  final String? closingTime;
  final double ratingAvg;
  final bool isActive;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.logoUrl,
    this.coverImageUrl,
    this.address,
    this.latitude,
    this.longitude,
    this.openingTime,
    this.closingTime,
    this.ratingAvg = 0.0,
    this.isActive = true,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? json['service_category'] ?? json['category_name'],
      logoUrl: json['logo_url'],
      coverImageUrl: json['cover_image_url'],
      address: json['address'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      openingTime: json['opening_time'],
      closingTime: json['closing_time'],
      ratingAvg: json['rating_avg'] != null
          ? double.tryParse(json['rating_avg'].toString()) ?? 0.0
          : 0.0,
      isActive: json['is_active'] ?? true,
    );
  }
}
