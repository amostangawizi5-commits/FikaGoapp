// ============================================================
// FIKAGO - OTP SCREEN
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../customer/home/home_screen.dart';
import '../rider/rider_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../vendor/vendor_dashboard_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? devOtp;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    this.devOtp,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.devOtp != null) {
      _otpController.text = widget.devOtp!;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localized(
              'OTP lazima iwe tarakimu 6', 'OTP must be 6 digits')),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.verifyOtp(
      phoneNumber: widget.phoneNumber,
      otpCode: otp,
      fullName: 'Mteja Mpya',
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'];
      final token = data['token'];
      final user = data['user'];

      await context.read<AuthProvider>().setAuth(
            token: token,
            user: user,
          );

      if (!mounted) return;
      final Widget dashboard = switch (user['role']) {
        'admin' => const AdminDashboardScreen(),
        'vendor' => const VendorDashboardScreen(),
        'rider' => const RiderDashboardScreen(),
        _ => const HomeScreen(),
      };
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message'] ??
                context.localized('OTP si sahihi', 'OTP is incorrect'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
          title: Text(context.localized('Thibitisha OTP', 'Verify OTP'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              context.localized('Tumekutumia OTP kwa', 'We sent an OTP to'),
              style: GoogleFonts.montserrat(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              widget.phoneNumber,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.devOtp != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FikaGoColors.lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${context.localized('DEV OTP', 'DEV OTP')}: ${widget.devOtp}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: FikaGoColors.forestGreen,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: GoogleFonts.montserrat(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
              ),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '------',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(context.localized('THIBITISHA', 'VERIFY')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
