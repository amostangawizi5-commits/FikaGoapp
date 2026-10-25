// ============================================================
// FIKAGO - ORDER MODEL
// ============================================================

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final double totalAmount;
  final String? restaurantName;
  final String? riderName;
  final String? riderPhone;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    this.restaurantName,
    this.riderName,
    this.riderPhone,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      restaurantName: json['restaurant_name'],
      riderName: json['rider_name'],
      riderPhone: json['rider_phone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
