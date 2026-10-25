// ============================================================
// FIKAGO ADMIN - RESPONSIVE DASHBOARD (Mobile, Tablet, Laptop)
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'admin_manage_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_promotions_screen.dart';
import 'admin_complaints_screen.dart';
import 'admin_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  // Orodha ya Screens zote
  final List<Widget> _screens = [
    const AdminManageScreen(),
    const AdminOrdersScreen(),
    const AdminPromotionsScreen(),
    const AdminComplaintsScreen(),
    const AdminSettingsScreen(),
  ];

  // Orodha ya Menu Items
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.manage_accounts, 'label': 'Manage'},
    {'icon': Icons.receipt_long, 'label': 'Orders'},
    {'icon': Icons.local_offer, 'label': 'Promos'},
    {'icon': Icons.support_agent_outlined, 'label': 'Complaints'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    // Tunapata upana wa screen
    final double width = MediaQuery.of(context).size.width;

    // 1. KAMA NI LAPTOP / DESKTOP (Upana > 900px)
    if (width > 900) {
      return _buildDesktopLayout();
    }
    // 2. KAMA NI TABLET (Upana kati ya 600px na 900px)
    else if (width > 600) {
      return _buildTabletLayout();
    }
    // 3. KAMA NI SIMU (Upana < 600px)
    else {
      return _buildMobileLayout();
    }
  }

  // ============================================================
  // 1. LAPTOP / DESKTOP LAYOUT (Permanent Sidebar)
  // ============================================================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Image.asset('assets/images/fikaGO.png', height: 50),
                ),
                const SizedBox(height: 48),
                // Menu Items
                ...List.generate(_menuItems.length, (index) {
                  final isSelected = _currentIndex == index;
                  return ListTile(
                    leading: Icon(
                      _menuItems[index]['icon'],
                      color: isSelected
                          ? FikaGoColors.forestGreen
                          : FikaGoColors.grey,
                    ),
                    title: Text(
                      _menuItems[index]['label'],
                      style: GoogleFonts.montserrat(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? FikaGoColors.forestGreen
                            : FikaGoColors.grey,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor: FikaGoColors.lightGreen,
                    onTap: () => setState(() => _currentIndex = index),
                  );
                }),
              ],
            ),
          ),
          // CONTENT
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. TABLET LAYOUT (Navigation Rail)
  // ============================================================
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      body: Row(
        children: [
          // NAVIGATION RAIL (Nyembamba)
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme:
                const IconThemeData(color: FikaGoColors.forestGreen),
            selectedLabelTextStyle: GoogleFonts.montserrat(
                color: FikaGoColors.forestGreen, fontWeight: FontWeight.bold),
            unselectedIconTheme: const IconThemeData(color: FikaGoColors.grey),
            unselectedLabelTextStyle:
                GoogleFonts.montserrat(color: FikaGoColors.grey),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Image.asset('assets/images/fikaGO.png', height: 30),
            ),
            destinations: _menuItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item['icon']),
                label: Text(item['label']),
              );
            }).toList(),
          ),
          // CONTENT
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. MOBILE LAYOUT (Bottom Navigation)
  // ============================================================
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/images/fikaGO.png', height: 35),
        backgroundColor: Colors.white,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: FikaGoColors.forestGreen,
        unselectedItemColor: FikaGoColors.grey,
        selectedLabelStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 10),
        items: _menuItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item['icon']),
            label: item['label'],
          );
        }).toList(),
      ),
    );
  }
}
