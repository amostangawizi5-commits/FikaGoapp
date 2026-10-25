// ============================================================
// FIKAGO - PROFILE SCREEN (Professional Design & Multi-Language)
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/role_selection_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        title: Text(
          'profile.title'.tr(),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ============================================
            // 1. PROFILE CARD
            // ============================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FikaGoColors.lightGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: FikaGoColors.charcoal.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: FikaGoColors.lightGreen,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: FikaGoColors.forestGreen, width: 2),
                    ),
                    child: const Icon(Icons.person,
                        size: 40, color: FikaGoColors.forestGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['full_name'] ?? 'profile.guest'.tr(),
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?['phone_number'] ?? 'profile.not_logged_in'.tr(),
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: FikaGoColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: FikaGoColors.forestGreen),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ============================================
            // 2. SETTINGS LIST
            // ============================================
            Container(
              decoration: BoxDecoration(
                color: FikaGoColors.lightGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: FikaGoColors.charcoal.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _profileTile(
                    icon: Icons.location_on_outlined,
                    title: 'profile.addresses'.tr(),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 60),
                  _profileTile(
                    icon: Icons.payment_outlined,
                    title: 'profile.payment_methods'.tr(),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 60),
                  _profileTile(
                    icon: Icons.notifications_none_outlined,
                    title: 'profile.notifications'.tr(),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 60),

                  // ============================================
                  // 3. LANGUAGE SWITCHER
                  // ============================================
                  ListTile(
                    leading: const Icon(Icons.language,
                        color: FikaGoColors.forestGreen),
                    title: Text(
                      'profile.language'.tr(),
                      style:
                          GoogleFonts.montserrat(fontWeight: FontWeight.w500),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: FikaGoColors.lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.locale.languageCode == 'sw'
                            ? 'Kiswahili'
                            : 'English',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: FikaGoColors.forestGreen,
                        ),
                      ),
                    ),
                    onTap: () {
                      if (context.locale.languageCode == 'sw') {
                        context.setLocale(const Locale('en'));
                      } else {
                        context.setLocale(const Locale('sw'));
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 60),

                  _profileTile(
                    icon: Icons.help_outline,
                    title: 'profile.help'.tr(),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ============================================
            // 4. LOGOUT BUTTON
            // ============================================
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FikaGoColors.charcoal.withValues(alpha: 0.1),
                  foregroundColor: FikaGoColors.charcoal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  // Onyesha dialog ya kuthibitisha
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(context.localized('Toka?', 'Log out?'),
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.bold)),
                      content: Text(
                        context.localized('Una uhakika unataka kutoka?',
                            'Are you sure you want to log out?'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(context.localized('HAPANA', 'NO')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            context.localized('NDIYO', 'YES'),
                            style:
                                const TextStyle(color: FikaGoColors.charcoal),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RoleSelectionScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: Text(
                  'profile.logout'.tr(),
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: Profile Tile
  // ============================================================
  Widget _profileTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: FikaGoColors.forestGreen),
      title: Text(
        title,
        style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: FikaGoColors.charcoal),
      onTap: onTap,
    );
  }
}
