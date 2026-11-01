import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/restaurant_service.dart';
import 'menu_item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const SearchScreen({super.key, this.onNavigateToTab});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<_SearchProduct> _results = [];
  bool _isLoading = true;
  bool _hasSearched = false;
  int? _addingItemId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
    });
    try {
      final response = await RestaurantService.searchMenu(query);
      if (!mounted || _controller.text.trim() != query) return;
      if (response['success'] != true || response['data'] is! List) {
        throw Exception('Search failed');
      }
      setState(() {
        _results = (response['data'] as List).map((row) {
          final data = Map<String, dynamic>.from(row as Map);
          return _SearchProduct(
            MenuItem.fromJson(data),
            data['restaurant_name']?.toString() ?? '',
            double.tryParse(data['rating_avg']?.toString() ?? ''),
            int.tryParse(data['review_count']?.toString() ?? ''),
          );
        }).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _error = context.localized(
          'Imeshindikana kupata matokeo. Jaribu tena.',
          'Could not load results. Please try again.',
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(_SearchProduct product) async {
    setState(() => _addingItemId = product.item.id);
    final cart = context.read<CartProvider>();
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    final added = loggedIn
        ? await cart.addToCart(menuItemId: product.item.id)
        : cart.addGuestItem(
            menuItemId: product.item.id,
            restaurantId: product.item.restaurantId,
            name: product.item.name,
            unitPrice: product.item.price,
            restaurantName: product.restaurantName,
          );
    if (!mounted) return;
    setState(() => _addingItemId = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added
          ? context.localized('Imeongezwa kwenye kikapu.', 'Added to cart.')
          : context.localized(
              'Kikapu kina bidhaa za mgahawa mwingine.',
              'Your cart contains items from another restaurant.',
            )),
      backgroundColor: added ? FikaGoColors.forestGreen : FikaGoColors.charcoal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: const BoxDecoration(
                color: FikaGoColors.forestGreen,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    context.localized('Tafuta Chakula', 'Search Results'),
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  elevation: 5,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  child: TextField(
                    controller: _controller,
                    onChanged: _onQueryChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    decoration: InputDecoration(
                      hintText: context.localized(
                        'Tafuta chakula au mgahawa...',
                        'Search food or restaurants...',
                      ),
                      prefixIcon:
                          const Icon(Icons.search, color: FikaGoColors.grey),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.localized('Futa', 'Clear'),
                              onPressed: () {
                                _controller.clear();
                                _onQueryChanged('');
                              },
                              icon: const Icon(Icons.close),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: FikaGoColors.forestGreen))
                  : _error != null
                      ? _message(_error!,
                          icon: Icons.wifi_off_outlined,
                          action: TextButton(
                            onPressed: () => _search(_controller.text),
                            child:
                                Text(context.localized('Jaribu tena', 'Retry')),
                          ))
                      : !_hasSearched
                          ? _message(
                              context.localized(
                                'Bidhaa hazipatikani kwa sasa.',
                                'No products are available right now.',
                              ),
                              icon: Icons.restaurant_menu,
                            )
                          : _results.isEmpty
                              ? _message(
                                  context.localized(
                                    'Hakuna chakula kilichopatikana.',
                                    'No items found.',
                                  ),
                                  icon: Icons.search_off,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          18, 0, 18, 10),
                                      child: Text(
                                        _controller.text.trim().isEmpty
                                            ? context.localized(
                                                'Bidhaa zote (${_results.length})',
                                                'All products (${_results.length})',
                                              )
                                            : context.localized(
                                                'Matokeo ${_results.length} ya "${_controller.text.trim()}"',
                                                '${_results.length} results for "${_controller.text.trim()}"',
                                              ),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          color: FikaGoColors.grey,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                            14, 0, 14, 24),
                                        itemCount: _results.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) =>
                                            _resultCard(_results[index]),
                                      ),
                                    ),
                                  ],
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String message, {required IconData icon, Widget? action}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: FikaGoColors.forestGreen),
              const SizedBox(height: 12),
              Text(message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: FikaGoColors.grey)),
              if (action != null) action,
            ],
          ),
        ),
      );

  Widget _resultCard(_SearchProduct product) {
    final item = product.item;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MenuItemDetailScreen(
              item: product.item,
              restaurantName: product.restaurantName,
              restaurantRating: product.restaurantRating,
              reviewCount: product.reviewCount,
              onNavigateToTab: widget.onNavigateToTab,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: item.imageUrl?.isNotEmpty == true
                      ? Image.network(item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _foodPlaceholder())
                      : _foodPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${product.restaurantName} - ${item.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (product.restaurantRating != null) ...[
                          const Icon(Icons.star,
                              size: 14, color: FikaGoColors.sunYellow),
                          const SizedBox(width: 3),
                          Text(product.restaurantRating!.toStringAsFixed(1),
                              style: GoogleFonts.montserrat(
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                        ],
                        const Icon(Icons.schedule,
                            size: 12, color: FikaGoColors.grey),
                        const SizedBox(width: 3),
                        Text('${item.preparationTime} min',
                            style: GoogleFonts.montserrat(
                                fontSize: 9, color: FikaGoColors.grey)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: FikaGoColors.forestGreen,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            context.localized('DELIVERY', 'DELIVERY'),
                            style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text('TZS ${item.price.toStringAsFixed(0)}',
                              maxLines: 1,
                              style: GoogleFonts.montserrat(
                                  color: FikaGoColors.forestGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          height: 34,
                          child: FilledButton(
                            onPressed: _addingItemId == item.id
                                ? null
                                : () => _addToCart(product),
                            style: FilledButton.styleFrom(
                              backgroundColor: FikaGoColors.sunYellow,
                              foregroundColor: FikaGoColors.charcoal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 11),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _addingItemId == item.id
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: FikaGoColors.forestGreen))
                                : Text(
                                    context.localized('Ongeza', 'Add to Cart'),
                                    style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _foodPlaceholder() => ColoredBox(
        color: FikaGoColors.lightGreen,
        child: const Center(
          child: Icon(Icons.fastfood, color: FikaGoColors.forestGreen),
        ),
      );
}

class _SearchProduct {
  final MenuItem item;
  final String restaurantName;
  final double? restaurantRating;
  final int? reviewCount;

  const _SearchProduct(
      this.item, this.restaurantName, this.restaurantRating, this.reviewCount);
}
