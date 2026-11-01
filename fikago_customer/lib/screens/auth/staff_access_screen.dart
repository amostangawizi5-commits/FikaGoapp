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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          FikaGoColors.forestGreen,
                          Color(0xFF174C3B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color:
                              FikaGoColors.forestGreen.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Image.asset(
                            'assets/images/fikaGO.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FikaGo',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.localized(
                                  'Lango la wafanyakazi',
                                  'Staff portal',
                                ),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.verified_user_outlined,
                          color: FikaGoColors.sunYellow,
                          size: 27,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    context.localized(
                      'Chagua eneo la kuingia',
                      'Choose a sign-in area',
                    ),
                    style: GoogleFonts.montserrat(
                      color: FikaGoColors.charcoal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.localized(
                      'Ingia kwa akaunti ya kazi uliyoidhinishwa.',
                      'Continue with your authorized work account.',
                    ),
                    style: GoogleFonts.montserrat(
                      color: FikaGoColors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _accessCard(
                    context,
                    icon: Icons.storefront_outlined,
                    title: context.localized('Mgahawa', 'Vendor'),
                    subtitle: context.localized(
                      'Simamia oda na menu ya mgahawa.',
                      'Manage restaurant orders and menu.',
                    ),
                    accentColor: FikaGoColors.sunYellow,
                    role: 'vendor',
                  ),
                  const SizedBox(height: 12),
                  _accessCard(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: context.localized('Msimamizi', 'Administrator'),
                    subtitle: context.localized(
                      'Fungua zana za usimamizi wa FikaGo.',
                      'Access FikaGo administration tools.',
                    ),
                    accentColor: FikaGoColors.lightGreen,
                    role: 'admin',
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: FikaGoColors.lightGreen.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: FikaGoColors.forestGreen.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: FikaGoColors.forestGreen,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.localized(
                              'Ufikiaji wa wafanyakazi walioidhinishwa pekee. Ruhusa hukaguliwa wakati wa kuingia.',
                              'Authorized staff only. Account access is verified at sign-in.',
                            ),
                            style: GoogleFonts.montserrat(
                              color: FikaGoColors.forestGreen,
                              fontSize: 10,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Powered by FikaGo',
                      style: GoogleFonts.montserrat(
                        color: FikaGoColors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accessCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required String role,
  }) =>
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: FikaGoColors.forestGreen.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: FikaGoColors.charcoal.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: FikaGoColors.forestGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.montserrat(
                              color: FikaGoColors.charcoal,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: GoogleFonts.montserrat(
                              color: FikaGoColors.grey,
                              fontSize: 10,
                              height: 1.35)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: FikaGoColors.lightGreen.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                    color: FikaGoColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
