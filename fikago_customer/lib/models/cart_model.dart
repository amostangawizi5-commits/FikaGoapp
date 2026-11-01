// ============================================================
// FIKAGO - CART MODEL
// ============================================================

class CartItem {
  final int id;
  final int menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final int? restaurantId;

  CartItem({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.restaurantId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      menuItemId: json['menu_item_id'],
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
      restaurantId: int.tryParse(json['restaurant_id']?.toString() ?? ''),
    );
  }
}

class Cart {
  final int cartId;
  final int? restaurantId;
  final String restaurantName;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double totalAmount;

  Cart({
    required this.cartId,
    this.restaurantId,
    this.restaurantName = '',
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.totalAmount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      cartId: json['cart_id'] ?? 0,
      restaurantId: int.tryParse(json['restaurant_id']?.toString() ?? ''),
      restaurantName: json['restaurant_name']?.toString() ?? '',
      items:
          (json['items'] as List?)?.map((i) => CartItem.fromJson(i)).toList() ??
              [],
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      deliveryFee: double.tryParse(json['delivery_fee'].toString()) ?? 0.0,
      serviceFee: double.tryParse(json['service_fee'].toString()) ?? 0.0,
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
    );
  }
}
