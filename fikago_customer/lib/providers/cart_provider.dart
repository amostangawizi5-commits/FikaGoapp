// ============================================================
// FIKAGO - CART PROVIDER
// ============================================================
import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  List<Cart>? _cartTickets;
  List<Cart> get _carts => _cartTickets ??= <Cart>[];
  final List<CartItem> _guestItems = [];
  Map<int, String>? _cartRestaurantNames;
  Map<int, String> get _guestRestaurantNames =>
      _cartRestaurantNames ??= <int, String>{};
  int _nextGuestItemId = -1;
  int? _activeCartId;
  bool _isLoading = false;

  List<Cart> get carts => List.unmodifiable(_carts);
  Cart? get cart {
    if (_activeCartId != null) {
      for (final ticket in _carts) {
        if (ticket.cartId == _activeCartId) return ticket;
      }
    }
    return _carts.isEmpty ? null : _carts.first;
  }

  List<Cart> get tickets {
    final result = [..._carts];
    final guestByRestaurant = <int, List<CartItem>>{};
    for (final item in _guestItems) {
      final restaurantId = item.restaurantId ?? 0;
      guestByRestaurant.putIfAbsent(restaurantId, () => []).add(item);
    }
    for (final entry in guestByRestaurant.entries) {
      final subtotal = entry.value.fold<double>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      result.add(Cart(
        cartId: -(entry.key == 0 ? 999999 : entry.key),
        restaurantId: entry.key == 0 ? null : entry.key,
        restaurantName: _guestRestaurantNames[entry.key] ?? '',
        items: entry.value,
        subtotal: subtotal,
        deliveryFee: 0,
        serviceFee: 0,
        discount: 0,
        totalAmount: subtotal,
      ));
    }
    return result;
  }

  List<CartItem> get items => [
        ..._carts.expand((ticket) => ticket.items),
        ..._guestItems,
      ];
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _carts.fold<double>(
        0,
        (sum, ticket) => sum + ticket.totalAmount,
      ) +
      _guestItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
  bool get isLoading => _isLoading;
  bool get hasGuestItems => _guestItems.isNotEmpty;

  void selectCart(int cartId) {
    _activeCartId = cartId;
    notifyListeners();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await CartService.getCart();
      if (response['success'] == true && response['data'] is Map) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        final rawCarts = data['carts'];
        _carts
          ..clear()
          ..addAll(rawCarts is List
              ? rawCarts.whereType<Map>().map((row) => Cart.fromJson(
                    Map<String, dynamic>.from(row),
                  ))
              : data['cart_id'] != null
                  ? [Cart.fromJson(data)]
                  : <Cart>[]);
        _guestItems.clear();
        _guestRestaurantNames.clear();
        if (_activeCartId != null &&
            !_carts.any((ticket) => ticket.cartId == _activeCartId)) {
          _activeCartId = null;
        }
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
    String restaurantName = '',
    int quantity = 1,
  }) {
    _guestRestaurantNames[restaurantId] = restaurantName;
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
        if (response['success'] == true && response['data'] is Map) {
          _upsertCart(Cart.fromJson(
            Map<String, dynamic>.from(response['data'] as Map),
          ));
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
    notifyListeners();
    return _guestItems.isEmpty;
  }

  Future<bool> quoteForLocation({
    required int cartId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await CartService.quoteCart(
        cartId: cartId,
        latitude: latitude,
        longitude: longitude,
      );
      if (response['success'] == true && response['data'] is Map) {
        _upsertCart(Cart.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        ));
        _activeCartId = cartId;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Cart quote error: $e');
    }
    return false;
  }

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
      if (response['success'] == true && response['data'] is Map) {
        final ticket = Cart.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        );
        _upsertCart(ticket);
        _activeCartId = ticket.cartId;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Add to cart error: $e');
    }
    return false;
  }

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
      if (response['success'] == true && response['data'] is Map) {
        _upsertCart(Cart.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        ));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update quantity error: $e');
    }
  }

  Future<void> removeItem(int itemId) async {
    final guestIndex = _guestItems.indexWhere((item) => item.id == itemId);
    if (guestIndex >= 0) {
      _guestItems.removeAt(guestIndex);
      notifyListeners();
      return;
    }
    try {
      final response = await CartService.removeFromCart(itemId);
      if (response['success'] == true && response['data'] is Map) {
        final ticket = Cart.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        );
        _upsertCart(ticket);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Remove error: $e');
    }
  }

  Future<bool> removeCart(int cartId) async {
    if (cartId < 0) {
      final restaurantId = -cartId;
      _guestItems.removeWhere((item) => item.restaurantId == restaurantId);
      _guestRestaurantNames.remove(restaurantId);
      notifyListeners();
      return true;
    }
    try {
      final response = await CartService.clearCart(cartId: cartId);
      if (response['success'] == true) {
        _carts.removeWhere((ticket) => ticket.cartId == cartId);
        if (_activeCartId == cartId) _activeCartId = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Remove cart error: $e');
    }
    return false;
  }

  void removeCompletedCart(int cartId) {
    _carts.removeWhere((ticket) => ticket.cartId == cartId);
    if (_activeCartId == cartId) _activeCartId = null;
    notifyListeners();
  }

  Future<bool> clearCart() async {
    try {
      final response = await CartService.clearCart();
      if (response['success'] == true) {
        _carts.clear();
        _guestItems.clear();
        _guestRestaurantNames.clear();
        _activeCartId = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Clear error: $e');
    }
    return false;
  }

  Future<bool> applyPromo(String promoCode) async {
    final active = cart;
    if (active == null) return false;
    try {
      final response = await CartService.applyPromo(
        promoCode,
        cartId: active.cartId,
      );
      if (response['success'] == true && response['data'] is Map) {
        _upsertCart(Cart.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        ));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Promo error: $e');
    }
    return false;
  }

  void _upsertCart(Cart cart) {
    final index = _carts.indexWhere((ticket) => ticket.cartId == cart.cartId);
    if (cart.items.isEmpty) {
      if (index >= 0) _carts.removeAt(index);
      return;
    }
    if (index < 0) {
      _carts.add(cart);
    } else {
      _carts[index] = cart;
    }
  }
}
