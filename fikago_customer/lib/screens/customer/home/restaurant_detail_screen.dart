// ============================================================
// FIKAGO - RESTAURANT DETAIL
// ============================================================
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

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  List<MenuCategory> _menu = [];
  bool _isLoading = true;
  int? _addingItemId;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    final res = await RestaurantService.getMenu(widget.restaurant.id);
    if (res['success'] == true) {
      final data = res['data'];
      final menu =
          (data['menu'] as List).map((e) => MenuCategory.fromJson(e)).toList();
      setState(() {
        _menu = menu;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart(MenuItem item) async {
    final cart = context.read<CartProvider>();
    setState(() => _addingItemId = item.id);
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    final ok = isLoggedIn
        ? await cart.addToCart(menuItemId: item.id, quantity: 1)
        : cart.addGuestItem(
            menuItemId: item.id,
            restaurantId: item.restaurantId,
            name: item.name,
            unitPrice: item.price,
          );
    if (!mounted) return;
    setState(() => _addingItemId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? context.localized(
                  '${item.name} imeongezwa', '${item.name} added to cart')
              : context.localized('Imeshindwa', 'Something went wrong'),
        ),
        backgroundColor: ok ? FikaGoColors.forestGreen : FikaGoColors.charcoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.restaurant.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                ..._menu.map((category) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.category,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: category.items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 190,
                          ),
                          itemBuilder: (context, index) {
                            final item = category.items[index];
                            return MenuItemCard(
                              item: item,
                              restaurantName: widget.restaurant.name,
                              isAdding: _addingItemId == item.id,
                              onBuy: () => _addToCart(item),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    )),
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
}
