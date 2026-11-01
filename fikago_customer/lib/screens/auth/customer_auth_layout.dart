import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_localizations.dart';
import '../../config/theme.dart';

class CustomerAuthLayout extends StatelessWidget {
  final Widget child;
  final ValueChanged<int>? onNavigateToTab;

  const CustomerAuthLayout({
    super.key,
    required this.child,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: FikaGoColors.forestGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 78,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 27),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('FikaGo',
                                style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 19)),
                            Text(
                              context.localized(
                                  'Tunakufikishia', 'We bring it to you'),
                              style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.localized('Taarifa', 'Notifications'),
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_none,
                            color: Colors.white),
                      ),
                      IconButton(
                        tooltip: context.localized('Wasifu', 'Profile'),
                        onPressed: onNavigateToTab == null
                            ? null
                            : () {
                                Navigator.pop(context);
                                onNavigateToTab!(3);
                              },
                        icon: const Icon(Icons.account_circle_outlined,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: onNavigateToTab == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                height: 56,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(context, Icons.home_outlined, Icons.home,
                        context.localized('Nyumbani', 'Home'), 0),
                    _navItem(context, Icons.search, Icons.search,
                        context.localized('Tafuta', 'Search'), 1),
                    _navItem(
                        context,
                        Icons.receipt_long_outlined,
                        Icons.receipt_long,
                        context.localized('Oda', 'Orders'),
                        2),
                    _navItem(context, Icons.person_outline, Icons.person,
                        context.localized('Wasifu', 'Profile'), 3,
                        selected: true),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, IconData activeIcon,
      String label, int index,
      {bool selected = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pop(context);
        onNavigateToTab?.call(index);
      },
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon,
                color: selected ? FikaGoColors.forestGreen : FikaGoColors.grey,
                size: 21),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                style: GoogleFonts.montserrat(
                    color:
                        selected ? FikaGoColors.forestGreen : FikaGoColors.grey,
                    fontSize: 9,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
