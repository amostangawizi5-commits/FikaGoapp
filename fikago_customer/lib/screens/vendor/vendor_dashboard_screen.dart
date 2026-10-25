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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // ============================================
      // BOTTOM NAVIGATION
      // ============================================
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }
}
