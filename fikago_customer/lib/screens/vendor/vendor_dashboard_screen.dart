// ============================================================
// FIKAGO VENDOR - MAIN DASHBOARD
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import 'vendor_orders_screen.dart';
import 'vendor_menu_screen.dart';
import 'vendor_earnings_screen.dart';
import 'vendor_profile_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _currentIndex = 0;

  // Hapa tunaweka screens zote 4 za Vendor
  final List<Widget> _screens = [
    const VendorOrdersScreen(),
    const VendorMenuScreen(),
    const VendorEarningsScreen(),
    const VendorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Scaffold(
          body: isDesktop
              ? Row(
                  children: [
                    SizedBox(width: 250, child: _buildSidebar(context)),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _screens,
                      ),
                    ),
                  ],
                )
              : IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
          bottomNavigationBar:
              isDesktop ? null : _buildBottomNavigation(context),
        );
      },
    );
  }

  Widget _buildBottomNavigation(BuildContext context) => BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: FikaGoColors.forestGreen,
        unselectedItemColor: FikaGoColors.charcoal,
        selectedLabelStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: context.localized('Oda', 'Orders'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.restaurant_menu_outlined),
            activeIcon: const Icon(Icons.restaurant_menu),
            label: context.localized('Menyu', 'Menu'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            activeIcon: const Icon(Icons.account_balance_wallet),
            label: context.localized('Mapato', 'Earnings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: context.localized('Wasifu', 'Profile'),
          ),
        ],
      );

  Widget _buildSidebar(BuildContext context) {
    final labels = [
      context.localized('Oda', 'Orders'),
      context.localized('Menyu', 'Menu'),
      context.localized('Mapato', 'Earnings'),
      context.localized('Wasifu', 'Profile'),
    ];
    const icons = [
      Icons.receipt_long_outlined,
      Icons.restaurant_menu_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.person_outline,
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 28),
            child: Row(
              children: [
                const Icon(Icons.restaurant, color: FikaGoColors.forestGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'FikaGo ${context.localized('Mgahawa', 'Vendor')}',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: FikaGoColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < labels.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _sidebarItem(
                label: labels[index],
                icon: icons[index],
                selected: _currentIndex == index,
                onTap: () => setState(() => _currentIndex = index),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Material(
        color: selected ? FikaGoColors.lightGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            child: Row(
              children: [
                Icon(icon,
                    color: selected
                        ? FikaGoColors.forestGreen
                        : FikaGoColors.grey),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? FikaGoColors.forestGreen
                        : FikaGoColors.charcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
