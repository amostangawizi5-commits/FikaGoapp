import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../models/menu_item_model.dart';
import '../../../models/restaurant_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/restaurant_service.dart';
import '../../../widgets/menu_item_card.dart';
import '../cart/cart_screen.dart';
import 'restaurant_detail_screen.dart';

class CategoryItemsScreen extends StatefulWidget {
  final String category;
  final String title;
  final IconData icon;

  const CategoryItemsScreen({
    super.key,
    required this.category,
    required this.title,
    required this.icon,
  });

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final _searchController = TextEditingController();
  List<_CategoryProduct> _products = [];
  bool _isLoading = true;
  String? _error;
  int? _addingItemId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final response =
          await RestaurantService.getCategoryItems(widget.category);
      if (response['success'] != true || response['data'] is! List) {
        throw Exception('Could not load category');
      }

      final products = (response['data'] as List).map((row) {
        final data = Map<String, dynamic>.from(row as Map);
        return _CategoryProduct(
          MenuItem.fromJson(data),
          data['restaurant_name']?.toString() ?? '',
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = context.localized(
          'Imeshindikana kupakia bidhaa. Jaribu tena.',
          'Could not load items. Please try again.',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(_CategoryProduct product) async {
    setState(() => _addingItemId = product.item.id);
    final cart = context.read<CartProvider>();
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    final added = isLoggedIn
        ? await cart.addToCart(menuItemId: product.item.id, quantity: 1)
        : cart.addGuestItem(
            menuItemId: product.item.id,
            restaurantId: product.item.restaurantId,
            name: product.item.name,
            unitPrice: product.item.price,
          );
    if (!mounted) return;
    setState(() => _addingItemId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added
            ? context.localized(
                '${product.item.name} imeongezwa kwenye kikapu.',
                '${product.item.name} added to cart.',
              )
            : context.localized(
                'Imeshindwa kuongeza bidhaa. Kikapu kinaweza kuwa na bidhaa za mgahawa mwingine.',
                'Could not add item. Your cart may contain items from another restaurant.',
              )),
        backgroundColor:
            added ? FikaGoColors.forestGreen : FikaGoColors.charcoal,
      ),
    );
  }

  Future<void> _openRestaurant(_CategoryProduct product) async {
    final response =
        await RestaurantService.getRestaurant(product.item.restaurantId);
    if (!mounted) return;
    if (response['success'] != true || response['data'] is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localized(
            'Imeshindikana kufungua mgahawa. Jaribu tena.',
            'Could not open the restaurant. Please try again.',
          )),
        ),
      );
      return;
    }

    final restaurant = Restaurant.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
      ),
    );
  }

  List<_CategoryProduct> get _visibleProducts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _products;
    return _products.where((product) {
      return product.item.name.toLowerCase().contains(query) ||
          product.restaurantName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
        leading: IconButton(
          tooltip: context.localized('Rudi nyuma', 'Go back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining,
                color: FikaGoColors.forestGreen, size: 27),
            const SizedBox(width: 7),
            Text(
              'FikaGo',
              style: GoogleFonts.montserrat(
                color: FikaGoColors.forestGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    context.localized('Tafuta bidhaa...', 'Search items...'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(widget.icon, color: FikaGoColors.forestGreen),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: GoogleFonts.montserrat(
                      fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: FikaGoColors.forestGreen))
                : _error != null
                    ? _emptyState(_error!, showRetry: true)
                    : products.isEmpty
                        ? _emptyState(
                            _searchController.text.isEmpty
                                ? context.localized(
                                    'Hakuna bidhaa kwenye category hii kwa sasa.',
                                    'No items in this category yet.',
                                  )
                                : context.localized(
                                    'Hakuna bidhaa inayolingana na utafutaji.',
                                    'No items match your search.',
                                  ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                            itemCount: products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 8,
                              mainAxisExtent: 190,
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return MenuItemCard(
                                item: product.item,
                                restaurantName: product.restaurantName,
                                isAdding: _addingItemId == product.item.id,
                                onTap: () => _openRestaurant(product),
                                onBuy: () => _addToCart(product),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: _cartButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _cartButton() => FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
        backgroundColor: FikaGoColors.forestGreen,
        tooltip: context.localized('Fungua kikapu', 'Open cart'),
        child: Consumer<CartProvider>(
          builder: (context, cart, _) => Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            child: const Icon(Icons.shopping_bag_outlined,
                color: FikaGoColors.lightGreen),
          ),
        ),
      );

  Widget _emptyState(String message, {bool showRetry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 42, color: FikaGoColors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (showRetry) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadProducts();
                },
                child: Text(context.localized('Jaribu tena', 'Try again')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryProduct {
  final MenuItem item;
  final String restaurantName;

  const _CategoryProduct(this.item, this.restaurantName);
}
