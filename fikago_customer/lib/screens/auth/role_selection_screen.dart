// ============================================================
// FIKAGO - ROLE SELECTION SCREEN
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../customer/home/home_screen.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.forestGreen,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: DropdownButton<Locale>(
                                value: context.locale,
                                dropdownColor: FikaGoColors.lightGreen,
                                underline: const SizedBox.shrink(),
                                style: GoogleFonts.montserrat(
                                  color: FikaGoColors.charcoal,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: Locale('sw'),
                                    child: Text('Kiswahili'),
                                  ),
                                  DropdownMenuItem(
                                    value: Locale('en'),
                                    child: Text('English'),
                                  ),
                                ],
                                onChanged: (locale) {
                                  if (locale != null) context.setLocale(locale);
                                },
                              ),
                            ),
                            Image.asset('assets/images/fikaGO.png',
                                height: 100),
                            const SizedBox(height: 24),
                            Text(
                              context.localized(
                                  'Karibu FikaGo', 'Welcome to FikaGo'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: FikaGoColors.lightGreen,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.localized(
                                'Chagua aina ya akaunti yako ili kuendelea',
                                'Choose your account type to continue',
                              ),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: FikaGoColors.lightGreen
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 36),
                            _roleCard(
                              context: context,
                              icon: Icons.person,
                              title: context.localized(
                                  'Mimi ni Mteja', 'I am a customer'),
                              subtitle: context.localized(
                                'Natakiwa kuagiza chakula',
                                'I want to order food',
                              ),
                              color: FikaGoColors.sunYellow,
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HomeScreen()),
                                  (route) => false,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _roleCard(
                              context: context,
                              icon: Icons.delivery_dining,
                              title: context.localized(
                                  'Mimi ni Dereva', 'I am a rider'),
                              subtitle: context.localized(
                                'Natakiwa kusafirisha chakula',
                                'I want to deliver orders',
                              ),
                              color: FikaGoColors.lightGreen,
                              iconColor: FikaGoColors.forestGreen,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LoginScreen(role: 'rider'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() => Column(
        children: [
          Text.rich(
            TextSpan(
              style: GoogleFonts.montserrat(
                color: FikaGoColors.lightGreen.withValues(alpha: 0.72),
                fontSize: 11,
              ),
              children: [
                const TextSpan(text: 'Powered by '),
                TextSpan(
                  text: 'FikaGo',
                  style: GoogleFonts.montserrat(
                    color: FikaGoColors.lightGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            '© 2026 FikaGo · Developed by Ginger',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: FikaGoColors.lightGreen.withValues(alpha: 0.48),
              fontSize: 9,
              letterSpacing: 0.15,
            ),
          ),
        ],
      );

  Widget _roleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Color iconColor = FikaGoColors.forestGreen,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: FikaGoColors.charcoal.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: FikaGoColors.charcoal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: FikaGoColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: FikaGoColors.charcoal,
            ),
          ],
        ),
      ),
    );
  }
}
