// ============================================================
// FIKAGO - HOME SCREEN (Modern UI like design)
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../models/menu_item_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/restaurant_service.dart';
import '../../../services/location_service.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import 'search_screen.dart';
import 'menu_item_detail_screen.dart';
import 'category_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _foodItems = [];
  bool _isLoadingFoods = true;
  String? _currentCity;
  String? _currentAddress;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _loadHomeFoods();
    _loadCustomerLocation();
  }

  Future<void> _loadCustomerLocation(
      {bool openSettingsIfUnavailable = false}) async {
    CustomerLocation? location;
    try {
      location = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentCity = location?.city;
        _currentAddress = location?.address;
        _isLocating = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLocating = false);
    }
    if (location == null && openSettingsIfUnavailable && mounted) {
      await LocationService.openRelevantSettings();
    }
  }

  Future<void> _loadHomeFoods() async {
    if (mounted) setState(() => _isLoadingFoods = true);
    final response = await RestaurantService.getFeaturedMenuItems();
    if (!mounted) return;
    setState(() {
      _foodItems = response['success'] == true && response['data'] is List
          ? (response['data'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
          : [];
      _isLoadingFoods = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeTab(),
      SearchScreen(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      OrdersScreen(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
      ProfileScreen(
        onNavigateToTab: (index) => setState(() => _currentIndex = index),
      ),
    ];

    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1000) return _buildDesktopLayout(screens);
    if (width >= 640) return _buildTabletLayout(screens);

    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // ============================================
      // FLOATING ACTION BUTTON (Cart)
      // ============================================
      floatingActionButton: _currentIndex == 0 ? _cartButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ============================================
      // BOTTOM NAVIGATION
      // ============================================
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: FikaGoColors.charcoal.withValues(alpha: 0.08),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home,
                    context.localized('Nyumbani', 'Home'), 0),
                _buildNavItem(Icons.search, Icons.search,
                    context.localized('Tafuta', 'Search'), 1),
                _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long,
                    context.localized('Oda', 'Orders'), 2),
                _buildNavItem(Icons.person_outline, Icons.person,
                    context.localized('Wasifu', 'Profile'), 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(List<Widget> screens) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      body: Row(
        children: [
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 28),
                Image.asset('assets/images/fikaGO.png', height: 48),
                const SizedBox(height: 32),
                ..._navigationItems(context).asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final selected = _currentIndex == index;
                  return ListTile(
                    leading: Icon(item.$1,
                        color: selected
                            ? FikaGoColors.forestGreen
                            : FikaGoColors.grey),
                    title: Text(item.$2,
                        style: GoogleFonts.montserrat(
                          color: selected
                              ? FikaGoColors.forestGreen
                              : FikaGoColors.charcoal,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        )),
                    selected: selected,
                    selectedTileColor: FikaGoColors.lightGreen,
                    onTap: () => setState(() => _currentIndex = index),
                  );
                }),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: Text(context.localized('Kikapu', 'Cart')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: IndexedStack(index: _currentIndex, children: screens),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? _cartButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTabletLayout(List<Widget> screens) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Image.asset('assets/images/fikaGO.png', width: 56),
            ),
            destinations: _navigationItems(context)
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.$3),
                      selectedIcon: Icon(item.$4),
                      label: Text(item.$2),
                    ))
                .toList(),
          ),
          Expanded(
              child: IndexedStack(index: _currentIndex, children: screens)),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? _cartButton() : null,
    );
  }

  List<(IconData, String, IconData, IconData)> _navigationItems(
          BuildContext context) =>
      [
        (
          Icons.home,
          context.localized('Nyumbani', 'Home'),
          Icons.home_outlined,
          Icons.home
        ),
        (
          Icons.search,
          context.localized('Tafuta', 'Search'),
          Icons.search,
          Icons.search
        ),
        (
          Icons.receipt_long,
          context.localized('Oda', 'Orders'),
          Icons.receipt_long_outlined,
          Icons.receipt_long
        ),
        (
          Icons.person,
          context.localized('Wasifu', 'Profile'),
          Icons.person_outline,
          Icons.person
        ),
      ];

  Widget _cartButton() => FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
        backgroundColor: FikaGoColors.forestGreen,
        tooltip: context.localized('Fungua kikapu', 'Open cart'),
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            final itemCount = cart.itemCount;
            return Badge(
              isLabelVisible: itemCount > 0,
              label: Text('$itemCount'),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: FikaGoColors.lightGreen),
            );
          },
        ),
      );

  Widget _buildNavItem(
      IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? FikaGoColors.forestGreen : FikaGoColors.grey;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 23,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HOME TAB CONTENT (Modern UI)
  // ============================================================
  Widget _buildHomeTab() {
    final locationParts = [
      if (_currentAddress?.isNotEmpty == true) _currentAddress!,
      if (_currentCity?.isNotEmpty == true &&
          !(_currentAddress
                  ?.toLowerCase()
                  .contains(_currentCity!.toLowerCase()) ??
              false))
        _currentCity!,
    ];
    final locationLabel = locationParts.isEmpty
        ? context.localized('Washa location', 'Enable location')
        : locationParts.join(', ');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHomeFoods,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                decoration: BoxDecoration(
                  color: FikaGoColors.forestGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 21),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('FikaGo',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                _isLocating
                                    ? context.localized('Inatafuta eneo...',
                                        'Finding your location...')
                                    : locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        if (!_isLocating)
                          IconButton(
                            tooltip:
                                context.localized(
                                    'Sasisha eneo', 'Refresh location'),
                            onPressed: () => _loadCustomerLocation(
                                openSettingsIfUnavailable: true),
                            icon: const Icon(Icons.my_location,
                                color: Colors.white, size: 20),
                          ),
                        IconButton(
                          tooltip: context.localized('Wasifu', 'Profile'),
                          onPressed: () => setState(() => _currentIndex = 3),
                          icon: const Icon(Icons.person_outline,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      context.localized('Njaa? Tunakufikishia haraka!',
                          'Hungry? We bring it to you!'),
                      style: GoogleFonts.montserrat(
                        fontSize: 23,
                        height: 1.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.localized(
                        'Chakula unachopenda, kimefika mlangoni mwako.',
                        'Your favorite food, delivered to your door.',
                      ),
                      style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.86)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. SEARCH BAR
              TextField(
                readOnly: true,
                onTap: () => setState(() => _currentIndex = 1),
                decoration: InputDecoration(
                  hintText: context.localized('Tafuta chakula au mgahawa...',
                      'Search food or restaurants...'),
                  prefixIcon:
                      const Icon(Icons.search, color: FikaGoColors.charcoal),
                  filled: true,
                  fillColor: FikaGoColors.lightGreen,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // 6. CATEGORIES (Kama kwenye picha - Cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.localized('Kategoria', 'Categories'),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: Text(
                      context.localized('Ona Zote', 'See all'),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: FikaGoColors.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FikaGoColors.lightGreen,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1100
                        ? 7
                        : constraints.maxWidth >= 700
                            ? 5
                            : constraints.maxWidth < 360
                                ? 3
                                : 4;
                    return GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.95,
                      children: [
                        _categoryCard(
                          'food',
                          Icons.restaurant,
                          context.localized('Chakula', 'Food'),
                          FikaGoColors.forestGreen,
                          FikaGoColors.lightGreen,
                        ),
                        _categoryCard(
                          'groceries',
                          Icons.shopping_cart,
                          context.localized('Vyakula', 'Groceries'),
                          FikaGoColors.forestGreen,
                          FikaGoColors.lightGreen,
                        ),
                        _categoryCard(
                          'shops',
                          Icons.shopping_bag,
                          context.localized('Maduka', 'Shops & Malls'),
                          FikaGoColors.forestGreen,
                          FikaGoColors.lightGreen,
                        ),
                        _categoryCard(
                          'liquor',
                          Icons.local_bar,
                          context.localized('Vileo', 'Liquor'),
                          FikaGoColors.forestGreen,
                          FikaGoColors.lightGreen,
                        ),
                        _categoryCard(
                          'pharmacy',
                          Icons.local_pharmacy,
                          context.localized('Duka la dawa', 'Pharmacy'),
                          FikaGoColors.forestGreen,
                          FikaGoColors.lightGreen,
                        ),
                        _categoryCard(
                          'salons',
                          Icons.content_cut,
                          context.localized('Saluni', 'Salons'),
                          FikaGoColors.forestGreen,
                          FikaGoColors.lightGreen,
                        ),
                        _categoryCard(
                          'parcels',
                          Icons.inventory_2,
                          context.localized('Vifurushi', 'Parcels'),
                          FikaGoColors.forestGreen,
                          FikaGoColors.lightGreen,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 7. PROMO BANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FikaGoColors.forestGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.delivery_dining,
                        color: FikaGoColors.sunYellow, size: 50),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.localized(
                                'Usafirishaji Bure!', 'Free Delivery!'),
                            style: GoogleFonts.montserrat(
                              color: FikaGoColors.lightGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            context.localized(
                              'Kwa oda yako ya kwanza. Tumia code: FIKA50',
                              'On your first order. Use code: FIKA50',
                            ),
                            style: GoogleFonts.montserrat(
                              color: FikaGoColors.lightGreen
                                  .withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 8. AVAILABLE FOOD FROM RESTAURANTS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.localized(
                        'Vyakula Vinavyopatikana', 'Food Near You'),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: Text(
                      context.localized('Ona Yote', 'See all'),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: FikaGoColors.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoadingFoods)
                const Center(child: CircularProgressIndicator())
              else if (_foodItems.isEmpty)
                Center(
                  child: Text(
                    context.localized(
                        'Hakuna chakula kinachopatikana kwa sasa.',
                        'No food is available right now.'),
                    style: GoogleFonts.montserrat(color: FikaGoColors.charcoal),
                  ),
                )
              else
                ..._foodItems.take(10).map(_foodCard),

              const SizedBox(height: 88), // Nafasi ya FAB
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS ZA DESIGN
  // ============================================================

  // Rounded category tiles arranged in a compact grid.
  Widget _categoryCard(
    String category,
    IconData icon,
    String label,
    Color iconColor,
    Color tileColor,
  ) {
    return Material(
      color: tileColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryItemsScreen(
              category: category,
              title: label,
              icon: icon,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: FikaGoColors.charcoal.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: FikaGoColors.lightGreen.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFoodDetails(Map<String, dynamic> data) async {
    final item = MenuItem.fromJson(data);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuItemDetailScreen(
          item: item,
          restaurantName: data['restaurant_name']?.toString() ?? '',
          restaurantRating:
              double.tryParse(data['rating_avg']?.toString() ?? ''),
          reviewCount: int.tryParse(data['review_count']?.toString() ?? ''),
          onNavigateToTab: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }

  Widget _foodCard(Map<String, dynamic> data) {
    final item = MenuItem.fromJson(data);
    final restaurant = data['restaurant_name']?.toString() ?? 'FikaGo';
    final rating = double.tryParse(data['rating_avg']?.toString() ?? '') ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: FikaGoColors.charcoal.withValues(alpha: 0.09),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _openFoodDetails(data),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: item.imageUrl?.isNotEmpty == true
                      ? Image.network(item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _foodPlaceholder())
                      : _foodPlaceholder(),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$restaurant - ${item.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: FikaGoColors.sunYellow),
                        const SizedBox(width: 3),
                        Text(rating.toStringAsFixed(1),
                            style: GoogleFonts.montserrat(
                                fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
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
                          height: 32,
                          child: FilledButton(
                            onPressed: () => _openFoodDetails(data),
                            style: FilledButton.styleFrom(
                              backgroundColor: FikaGoColors.sunYellow,
                              foregroundColor: FikaGoColors.charcoal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9)),
                            ),
                            child: Text(context.localized('Agiza', 'Order'),
                                style: GoogleFonts.montserrat(
                                    fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _foodPlaceholder() => const ColoredBox(
        color: FikaGoColors.lightGreen,
        child: Center(
          child: Icon(Icons.fastfood,
              color: FikaGoColors.forestGreen, size: 32),
        ),
      );
}
