// ============================================================
// FIKAGO RIDER - PENDING APPROVAL
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../auth/login_screen.dart';

class RiderPendingScreen extends StatelessWidget {
  const RiderPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: FikaGoColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_empty,
                    size: 80, color: FikaGoColors.forestGreen),
              ),
              const SizedBox(height: 32),
              Text(
                  context.localized(
                      'Maombi Yamewasilishwa!', 'Application submitted!'),
                  style: GoogleFonts.montserrat(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(
                context.localized(
                  'Asante kwa kujisajili kama dereva wa FikaGo. Timu yetu inapitia taarifa zako. Utapata taarifa kupitia SMS ndani ya masaa 24.',
                  'Thanks for applying to become a FikaGo rider. Our team is reviewing your details. You will receive an update by SMS within 24 hours.',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 14, color: FikaGoColors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen(role: 'rider')),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FikaGoColors.forestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                      context.localized('RUDI KWENYE LOGIN', 'BACK TO LOGIN'),
                      style:
                          GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
