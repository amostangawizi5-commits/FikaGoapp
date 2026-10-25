// ============================================================
// FIKAGO - CART PROVIDER
// ============================================================
import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  Cart? _cart;
  final List<CartItem> _guestItems = [];
  int _nextGuestItemId = -1;
  int? _guestRestaurantId;
  bool _isLoading = false;

  Cart? get cart => _cart;
  List<CartItem> get items => [...?_cart?.items, ..._guestItems];
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      (_cart?.totalAmount ?? 0.0) +
      _guestItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isLoading => _isLoading;
  bool get hasGuestItems => _guestItems.isNotEmpty;

  // Load cart kutoka backend
  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await CartService.getCart();
      if (response['success'] == true) {
        _cart = Cart.fromJson(response['data']);
        _guestItems.clear();
        _guestRestaurantId = null;
      }
    } catch (e) {
      debugPrint('Cart load error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  bool addGuestItem({
    required int menuItemId,
    required int restaurantId,
    required String name,
    required double unitPrice,
    int quantity = 1,
  }) {
    if (_guestItems.isNotEmpty && _guestRestaurantId != restaurantId) {
      return false;
    }

    _guestRestaurantId = restaurantId;
    final existingIndex = _guestItems.indexWhere(
      (item) => item.menuItemId == menuItemId,
    );
    if (existingIndex >= 0) {
      final oldItem = _guestItems[existingIndex];
      final newQuantity = oldItem.quantity + quantity;
      _guestItems[existingIndex] = CartItem(
        id: oldItem.id,
        menuItemId: oldItem.menuItemId,
        name: oldItem.name,
        quantity: newQuantity,
        unitPrice: oldItem.unitPrice,
        totalPrice: oldItem.unitPrice * newQuantity,
        restaurantId: oldItem.restaurantId,
      );
    } else {
      _guestItems.add(CartItem(
        id: _nextGuestItemId--,
        menuItemId: menuItemId,
        name: name,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: unitPrice * quantity,
        restaurantId: restaurantId,
      ));
    }
    notifyListeners();
    return true;
  }

  Future<bool> syncGuestItems() async {
    if (_guestItems.isEmpty) return true;

    final failedItems = <CartItem>[];
    for (final item in List<CartItem>.from(_guestItems)) {
      try {
        final response = await CartService.addToCart(
          menuItemId: item.menuItemId,
          quantity: item.quantity,
        );
        if (response['success'] == true) {
          _cart = Cart.fromJson(response['data']);
        } else {
          failedItems.add(item);
        }
      } catch (e) {
        debugPrint('Guest cart sync error: $e');
        failedItems.add(item);
      }
    }

    _guestItems
      ..clear()
      ..addAll(failedItems);
    if (_guestItems.isEmpty) _guestRestaurantId = null;
    notifyListeners();
    return _guestItems.isEmpty;
  }

  Future<bool> quoteForLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await CartService.quoteCart(
        latitude: latitude,
        longitude: longitude,
      );
      if (response['success'] == true) {
        _cart = Cart.fromJson(response['data']);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Cart quote error: $e');
    }
    return false;
  }

  // Ongeza kwenye cart
  Future<bool> addToCart({
    required int menuItemId,
    int quantity = 1,
    String? specialInstructions,
  }) async {
    try {
      final response = await CartService.addToCart(
        menuItemId: menuItemId,
        quantity: quantity,
        specialInstructions: specialInstructions,
      );

      if (response['success'] == true) {
        _cart = Cart.fromJson(response['data']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Add to cart error: $e');
      return false;
    }
  }

  // Update quantity
  Future<void> updateQuantity(int itemId, int quantity) async {
    if (quantity < 1) return;

    final guestIndex = _guestItems.indexWhere((item) => item.id == itemId);
    if (guestIndex >= 0) {
      final item = _guestItems[guestIndex];
      _guestItems[guestIndex] = CartItem(
        id: item.id,
        menuItemId: item.menuItemId,
        name: item.name,
        quantity: quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.unitPrice * quantity,
        restaurantId: item.restaurantId,
      );
      notifyListeners();
      return;
    }

    try {
      final response = await CartService.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );

      if (response['success'] == true) {
        _cart = Cart.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update quantity error: $e');
    }
  }

  // Remove item
  Future<void> removeItem(int itemId) async {
    final guestIndex = _guestItems.indexWhere((item) => item.id == itemId);
    if (guestIndex >= 0) {
      _guestItems.removeAt(guestIndex);
      if (_guestItems.isEmpty) _guestRestaurantId = null;
      notifyListeners();
      return;
    }

    try {
      final response = await CartService.removeFromCart(itemId);
      if (response['success'] == true) {
        _cart = Cart.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Remove error: $e');
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    if (_cart == null) {
      _guestItems.clear();
      _guestRestaurantId = null;
      notifyListeners();
      return;
    }

    try {
      final response = await CartService.clearCart();
      if (response['success'] == true) {
        _cart = null;
        _guestItems.clear();
        _guestRestaurantId = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Clear error: $e');
    }
  }

  // Apply promo
  Future<bool> applyPromo(String promoCode) async {
    try {
      final response = await CartService.applyPromo(promoCode);
      if (response['success'] == true) {
        _cart = Cart.fromJson(response['data']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Promo error: $e');
      return false;
    }
  }
}
