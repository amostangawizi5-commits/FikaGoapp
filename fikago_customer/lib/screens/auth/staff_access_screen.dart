import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import 'login_screen.dart';

class StaffAccessScreen extends StatelessWidget {
  const StaffAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGrey,
      appBar: AppBar(
        backgroundColor: FikaGoColors.forestGreen,
        foregroundColor: Colors.white,
        title: Text(
            context.localized('Ufikiaji wa Wafanyakazi', 'Staff Access'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FikaGoColors.forestGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 38, color: FikaGoColors.sunYellow),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.localized(
                        'Sehemu hii ni kwa akaunti za wafanyakazi zilizoidhinishwa pekee.',
                        'This area is for authorized staff accounts only.',
                      ),
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.localized(
                  'Chagua eneo la kuingia', 'Choose a sign-in area'),
              style: GoogleFonts.montserrat(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _accessCard(
              context,
              icon: Icons.storefront_outlined,
              title: context.localized('Mgahawa', 'Vendor'),
              subtitle: context.localized(
                  'Ingia kusimamia oda na menu ya mgahawa.',
                  'Sign in to manage restaurant orders and menu.'),
              role: 'vendor',
            ),
            const SizedBox(height: 12),
            _accessCard(
              context,
              icon: Icons.admin_panel_settings_outlined,
              title: context.localized('Msimamizi', 'Administrator'),
              subtitle: context.localized(
                  'Ingia kwenye zana za usimamizi wa FikaGo.',
                  'Sign in to access FikaGo administration tools.'),
              role: 'admin',
            ),
            const SizedBox(height: 20),
            Text(
              context.localized(
                'Akaunti na ruhusa hukaguliwa na mfumo wakati wa kuingia.',
                'Account roles and access are verified by the server at sign-in.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  color: FikaGoColors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accessCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String role,
  }) =>
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: FikaGoColors.lightGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: FikaGoColors.forestGreen),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: GoogleFonts.montserrat(
                              color: FikaGoColors.grey, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 15, color: FikaGoColors.grey),
              ],
            ),
          ),
        ),
      );
}
