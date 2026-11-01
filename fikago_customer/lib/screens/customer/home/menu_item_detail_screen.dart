import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';

class MenuItemDetailScreen extends StatefulWidget {
  final MenuItem item;
  final String restaurantName;
  final double? restaurantRating;
  final int? reviewCount;
  final ValueChanged<int>? onNavigateToTab;

  const MenuItemDetailScreen({
    super.key,
    required this.item,
    required this.restaurantName,
    this.restaurantRating,
    this.reviewCount,
    this.onNavigateToTab,
  });

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  int _quantity = 1;
  bool _isAdding = false;
  bool _isFavorite = false;
  bool _showMoreDetails = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    final cart = context.read<CartProvider>();
    final added = context.read<AuthProvider>().isLoggedIn
        ? await cart.addToCart(
            menuItemId: widget.item.id,
            quantity: _quantity,
          )
        : cart.addGuestItem(
            menuItemId: widget.item.id,
            restaurantId: widget.item.restaurantId,
            name: widget.item.name,
            unitPrice: widget.item.price,
            restaurantName: widget.restaurantName,
            quantity: _quantity,
          );
    if (!mounted) return;
    setState(() => _isAdding = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added
          ? context.localized(
              '${widget.item.name} imeongezwa kwenye kikapu.',
              '${widget.item.name} added to cart.',
            )
          : context.localized(
              'Kikapu kina bidhaa za mgahawa mwingine.',
              'Your cart contains items from another restaurant.',
            )),
      backgroundColor: added ? FikaGoColors.forestGreen : FikaGoColors.charcoal,
    ));
  }

  Future<void> _shareItem() async {
    await Clipboard.setData(ClipboardData(text: widget.item.name));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.localized(
        'Jina la chakula limenakiliwa.',
        'Food name copied.',
      )),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final description = item.description?.trim();
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.forestGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(context.localized('Maelezo', 'Details')),
        leading: Padding(
          padding: const EdgeInsets.all(7),
          child: Material(
            color: FikaGoColors.white.withValues(alpha: 0.8),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: context.localized('Rudi nyuma', 'Go back'),
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.localized('Shiriki', 'Share'),
            onPressed: _shareItem,
            icon: const Icon(Icons.ios_share_outlined, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          Container(
            height: 250,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: FikaGoColors.lightGrey,
              borderRadius: BorderRadius.circular(22),
            ),
            child: item.imageUrl?.isNotEmpty == true
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 21,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: FikaGoColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.localized(
                        'Kuanzia: TZS ${item.price.toStringAsFixed(0)}',
                        'From: TZS ${item.price.toStringAsFixed(0)}',
                      ),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: FikaGoColors.charcoal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: FikaGoColors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: context.localized('Hifadhi', 'Save'),
                  onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite
                        ? FikaGoColors.red
                        : FikaGoColors.forestGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _detailMetric(
                  icon: Icons.star,
                  iconColor: FikaGoColors.sunYellow,
                  value: widget.restaurantRating?.toStringAsFixed(1) ?? '—',
                ),
              ),
              _metricDivider(),
              Expanded(
                child: _detailMetric(
                  icon: Icons.access_time,
                  iconColor: FikaGoColors.forestGreen,
                  value: '${item.preparationTime} min',
                ),
              ),
              _metricDivider(),
              Expanded(
                child: _detailMetric(
                  icon: Icons.delivery_dining,
                  iconColor: FikaGoColors.forestGreen,
                  value: context.localized('FikaGo', 'Delivery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            context.localized('Maelezo', 'Description'),
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: FikaGoColors.charcoal,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description?.isNotEmpty == true
                ? description!
                : context.localized(
                    'Maelezo ya chakula hiki hayajawekwa bado.',
                    'No description has been added for this item yet.',
                  ),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              height: 1.5,
              color: FikaGoColors.grey,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: FikaGoColors.forestGreen.withValues(alpha: 0.2)),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _showMoreDetails = !_showMoreDetails),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.localized('Maelezo zaidi', 'More details'),
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FikaGoColors.charcoal,
                      ),
                    ),
                  ),
                  Icon(
                    _showMoreDetails
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: FikaGoColors.forestGreen,
                  ),
                ],
              ),
            ),
          ),
          if (_showMoreDetails) ...[
            _detailRow(
              Icons.storefront_outlined,
              context.localized('Mgahawa', 'Restaurant'),
              widget.restaurantName,
            ),
            const SizedBox(height: 10),
            _detailRow(
              item.isAvailable ? Icons.check_circle_outline : Icons.block,
              context.localized('Upatikanaji', 'Availability'),
              context.localized(
                item.isAvailable ? 'Inapatikana' : 'Haipo',
                item.isAvailable ? 'Available' : 'Unavailable',
              ),
            ),
            if (widget.reviewCount != null) ...[
              const SizedBox(height: 10),
              _detailRow(
                Icons.reviews_outlined,
                context.localized('Maoni', 'Reviews'),
                '${widget.reviewCount}',
              ),
            ],
          ],
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _detailMetric({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 17),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                color: FikaGoColors.charcoal,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _metricDivider() => Container(
        height: 22,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        color: FikaGoColors.forestGreen.withValues(alpha: 0.25),
      );

  Widget _detailRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: FikaGoColors.forestGreen, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: FikaGoColors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: GoogleFonts.montserrat(
                color: FikaGoColors.charcoal,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _bottomBar() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: FikaGoColors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: FikaGoColors.lightGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _quantityButton(
                        Icons.remove,
                        enabled: _quantity > 1,
                        onTap: () => setState(() => _quantity--),
                      ),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _quantityButton(
                        Icons.add,
                        onTap: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _isAdding || !widget.item.isAvailable
                          ? null
                          : _addToCart,
                      style: FilledButton.styleFrom(
                        backgroundColor: FikaGoColors.sunYellow,
                        foregroundColor: FikaGoColors.charcoal,
                        disabledBackgroundColor: FikaGoColors.lightGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: _isAdding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: FikaGoColors.forestGreen,
                              ),
                            )
                          : Text(
                              context.localized(
                                'Ongeza kwenye kikapu',
                                'Add to Cart',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onNavigateToTab != null)
            SafeArea(
              top: false,
              child: Container(
                height: 56,
                color: FikaGoColors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(Icons.home_outlined, Icons.home,
                        context.localized('Nyumbani', 'Home'), 0),
                    _navItem(Icons.search, Icons.search,
                        context.localized('Tafuta', 'Search'), 1,
                        selected: true),
                    _navItem(Icons.receipt_long_outlined, Icons.receipt_long,
                        context.localized('Oda', 'Orders'), 2),
                    _navItem(Icons.person_outline, Icons.person,
                        context.localized('Wasifu', 'Profile'), 3),
                  ],
                ),
              ),
            ),
        ],
      );

  Widget _quantityButton(IconData icon,
          {bool enabled = true, required VoidCallback onTap}) =>
      Material(
        color: !enabled
            ? FikaGoColors.white
            : icon == Icons.add
                ? FikaGoColors.forestGreen
                : FikaGoColors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon,
                size: 19,
                color: !enabled
                    ? FikaGoColors.grey
                    : icon == Icons.add
                        ? FikaGoColors.white
                        : FikaGoColors.charcoal),
          ),
        ),
      );

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index,
          {bool selected = false}) =>
      InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.onNavigateToTab?.call(index);
        },
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon,
                  color:
                      selected ? FikaGoColors.forestGreen : FikaGoColors.grey,
                  size: 21),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  style: GoogleFonts.montserrat(
                      color: selected
                          ? FikaGoColors.forestGreen
                          : FikaGoColors.grey,
                      fontSize: 9,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      );

  Widget _imagePlaceholder() => ColoredBox(
        color: FikaGoColors.lightGreen,
        child: const Center(
            child: Icon(Icons.fastfood,
                size: 50, color: FikaGoColors.forestGreen)),
      );
}
