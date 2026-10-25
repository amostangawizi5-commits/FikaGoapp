// ============================================================
// FIKAGO - HOME SCREEN (Modern UI like design)
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../models/restaurant_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/restaurant_service.dart';
import '../../../services/location_service.dart';
import '../../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../wallet/wallet_screen.dart';
import 'restaurant_detail_screen.dart';
import 'category_items_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  String? _currentCity;
  String? _currentAddress;
  String? _locationAttribution;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
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
        _locationAttribution = location?.attribution;
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

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    final response = await RestaurantService.getRestaurants(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      category: _selectedCategory,
    );

    if (response['success'] == true) {
      final data = response['data'] as List;
      setState(() {
        _restaurants = data.map((e) => Restaurant.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeTab(),
      const OrdersScreen(),
      const WalletScreen(),
      const ProfileScreen(),
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
      // BOTTOM NAVIGATION (Modern Design)
      // ============================================
      bottomNavigationBar: BottomAppBar(
        color: FikaGoColors.lightGreen,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home,
                  context.localized('Nyumbani', 'Home'), 0),
              _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long,
                  context.localized('Oda', 'Orders'), 1),
              _buildNavItem(
                  Icons.account_balance_wallet_outlined,
                  Icons.account_balance_wallet,
                  context.localized('Wallet', 'Wallet'),
                  2),
              _buildNavItem(Icons.person_outline, Icons.person,
                  context.localized('Wasifu', 'Profile'), 3),
            ],
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
          Icons.receipt_long,
          context.localized('Oda', 'Orders'),
          Icons.receipt_long_outlined,
          Icons.receipt_long
        ),
        (
          Icons.account_balance_wallet,
          context.localized('Wallet', 'Wallet'),
          Icons.account_balance_wallet_outlined,
          Icons.account_balance_wallet
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
          builder: (context, cart, _) => Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}'),
            child: const Icon(Icons.shopping_bag_outlined,
                color: FikaGoColors.lightGreen),
          ),
        ),
      );

  Widget _buildNavItem(
      IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color:
                isSelected ? FikaGoColors.forestGreen : FikaGoColors.charcoal,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected ? FikaGoColors.forestGreen : FikaGoColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOME TAB CONTENT (Modern UI)
  // ============================================================
  Widget _buildHomeTab() {
    final authProvider = context.watch<AuthProvider>();
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
        onRefresh: _loadRestaurants,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LOGO KATIKATI (Center Top)
              Center(
                child: Image.asset(
                  'assets/images/fikaGO.png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // 2. LOCATION & PROFILE
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: FikaGoColors.forestGreen, size: 20),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLocating
                              ? context.localized('Inatafuta eneo lako...',
                                  'Finding your location...')
                              : locationLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_locationAttribution != null)
                          Text(
                            _locationAttribution!,
                            style: GoogleFonts.montserrat(
                                fontSize: 9, color: FikaGoColors.grey),
                          ),
                      ],
                    ),
                  ),
                  if (!_isLocating &&
                      (_currentCity == null || _currentCity!.isEmpty) &&
                      (_currentAddress == null || _currentAddress!.isEmpty))
                    IconButton(
                      tooltip: context.localized('Jaribu tena', 'Try again'),
                      onPressed: () => _loadCustomerLocation(
                        openSettingsIfUnavailable: true,
                      ),
                      icon: const Icon(Icons.my_location,
                          color: FikaGoColors.forestGreen),
                    )
                  else
                    const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: FikaGoColors.lightGreen,
                    child: Icon(Icons.person,
                        color: FikaGoColors.forestGreen, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. GREETING
              Text(
                context.localized('Leo unataka kula nini?',
                    'What would you like to eat today?'),
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: FikaGoColors.charcoal,
                ),
              ),
              const SizedBox(height: 16),

              // 4. SEARCH BAR
              TextField(
                onSubmitted: (value) {
                  setState(() => _searchQuery = value);
                  _loadRestaurants();
                },
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

              // 5. LOGIN BANNER (Kama hajaingia)
              if (!authProvider.isLoggedIn)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FikaGoColors.sunYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: FikaGoColors.sunYellow),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: FikaGoColors.forestGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.localized(
                                  'Karibu Mgeni!', 'Welcome, Guest!'),
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              context.localized(
                                'Chagua chakula; utajaza taarifa za usajili ukiweka oda.',
                                'Choose your food; you can register when adding it to your order.',
                              ),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: FikaGoColors.charcoal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          context.localized('INGIA', 'LOG IN'),
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: FikaGoColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                    onPressed: () {
                      setState(() => _selectedCategory = null);
                      _loadRestaurants();
                    },
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

              // 8. RESTAURANTS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.localized(
                        'Migahawa Iliyo Karibu', 'Nearby Restaurants'),
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.localized('Ona Yote', 'See all'),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: FikaGoColors.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_restaurants.isEmpty)
                Center(
                  child: Text(
                    context.localized('Hakuna migahawa iliyopatikana',
                        'No restaurants found'),
                    style: GoogleFonts.montserrat(color: FikaGoColors.charcoal),
                  ),
                )
              else
                ..._restaurants.map((r) => _restaurantCard(r)),

              const SizedBox(height: 80), // Nafasi ya FAB
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

  // Restaurant Card
  Widget _restaurantCard(Restaurant r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: FikaGoColors.lightGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FikaGoColors.charcoal.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailScreen(restaurant: r),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: FikaGoColors.lightGreen,
                  borderRadius: BorderRadius.circular(16),
                  image: r.logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(r.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: r.logoUrl == null
                    ? const Icon(Icons.restaurant,
                        color: FikaGoColors.forestGreen, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.address ??
                          context.localized(
                              'Eneo halipo', 'Address unavailable'),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: FikaGoColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 16, color: FikaGoColors.sunYellow),
                        const SizedBox(width: 4),
                        Text(
                          r.ratingAvg.toStringAsFixed(1),
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.timer,
                            size: 16, color: FikaGoColors.charcoal),
                        const SizedBox(width: 4),
                        Text(
                          '30 min',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: FikaGoColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: FikaGoColors.charcoal),
            ],
          ),
        ),
      ),
    );
  }
}
