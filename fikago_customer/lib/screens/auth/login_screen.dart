// ============================================================
// FIKAGO - LOGIN SCREEN (Password & OTP Options)
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../customer/home/home_screen.dart'; // Home ya Mteja
import '../vendor/vendor_dashboard_screen.dart'; // Dashboard ya Mgahawa (Vendor)
import '../admin/admin_dashboard_screen.dart';
import '../rider/rider_dashboard_screen.dart';
import '../rider/rider_register_screen.dart';
import 'register_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role; // Inatoka kwenye Role Selection

  const LoginScreen({super.key, this.role = 'customer'});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // KAZI YA KUPEPELEKA MTU SEHEMU SAHIHI (Routing)
  // ============================================================
  void _navigateToDashboard(String userRoleFromBackend) {
    if (userRoleFromBackend == 'admin') {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false);
      return;
    }
    if (userRoleFromBackend == 'vendor') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
        (route) => false,
      );
      return;
    }
    if (userRoleFromBackend == 'rider') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RiderDashboardScreen()),
        (route) => false,
      );
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // LOGIN KWA PASSWORD
  // ============================================================
  Future<void> _loginWithPassword() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.localized('Tafadhali ingiza namba na password',
                'Please enter your phone number and password'),
          ),
        ),
      );
      return;
    }
    if (phone.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localized(
            'Ingiza tarakimu 9 za namba yako baada ya +255.',
            'Enter the 9 phone digits after +255.',
          )),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final response = await AuthService.login(
      phoneNumber: phone,
      password: password,
      role: widget.role,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'];
      final user = data['user'];

      // Hifadhi taarifa kwenye Provider
      await context.read<AuthProvider>().setAuth(
            token: data['token'],
            user: user,
          );

      if (!mounted) return;

      // Pata role halisi kutoka kwenye database (backend)
      final actualRole = user['role'] ?? 'customer';

      // Peleka mtumiaji sehemu sahihi
      _navigateToDashboard(actualRole);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ??
              context.localized('Imeshindwa kuingia', 'Could not log in')),
          backgroundColor: FikaGoColors.charcoal,
        ),
      );
    }
  }

  // ============================================================
  // LOGIN KWA OTP
  // ============================================================
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.localized('Tafadhali ingiza namba ya simu',
                'Please enter your phone number'))),
      );
      return;
    }
    if (phone.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localized(
            'Ingiza tarakimu 9 za namba yako baada ya +255.',
            'Enter the 9 phone digits after +255.',
          )),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await AuthService.sendOtp(phone);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['success'] == true) {
      final devOtp = response['data']?['dev_otp'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: phone,
            devOtp: devOtp,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(response['message'] ??
                context.localized(
                    'Imeshindwa kutuma OTP', 'Could not send OTP'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.forestGreen,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactLayout = constraints.maxWidth < 400;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compactLayout ? 12 : 24,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: widget.role == 'admin' || widget.role == 'vendor'
                      ? constraints.maxHeight
                      : 0,
                ),
                child: Align(
                  alignment: switch (widget.role) {
                    'admin' => const Alignment(0, 0.14),
                    'vendor' => const Alignment(0, 0.18),
                    _ => Alignment.center,
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // CARD YA LOGIN
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Card(
                          elevation: 20,
                          shadowColor:
                              FikaGoColors.charcoal.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Padding(
                            padding:
                                EdgeInsets.all(compactLayout ? 16.0 : 32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1. LOGO YA FIKAGO
                                Image.asset(
                                  'assets/images/fikaGO.png',
                                  height: 110,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 16),

                                // 2. MAELEZO
                                Text(
                                  widget.role == 'vendor'
                                      ? context.localized(
                                          'Ingia kama Mgahawa', 'Vendor login')
                                      : context.localized(
                                          'Karibu FikaGo', 'Welcome to FikaGo'),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: FikaGoColors.forestGreen,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.role == 'vendor'
                                      ? 'Tumia namba ya simu ya mgahawa na password.'
                                      : context.localized(
                                          'Ingia kwa namba yako na password',
                                          'Log in with your phone number and password',
                                        ),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: FikaGoColors.charcoal,
                                  ),
                                ),
                                SizedBox(height: compactLayout ? 20 : 32),

                                // 3. INPUT YA NAMBA YA SIMU
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    TanzaniaPhoneInputFormatter()
                                  ],
                                  style: GoogleFonts.montserrat(fontSize: 16),
                                  decoration: InputDecoration(
                                    prefixText: '+255 ',
                                    prefixIcon: const Icon(
                                      Icons.phone_android,
                                      color: FikaGoColors.forestGreen,
                                    ),
                                    hintText: '712 345 678',
                                    labelText: widget.role == 'vendor'
                                        ? context.localized(
                                            'Namba ya Simu ya Mgahawa',
                                            'Vendor phone number')
                                        : context.localized(
                                            'Namba ya Simu', 'Phone Number'),
                                    labelStyle: GoogleFonts.montserrat(
                                      color: FikaGoColors.forestGreen,
                                    ),
                                    filled: true,
                                    fillColor: FikaGoColors.lightGreen,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: FikaGoColors.forestGreen,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: FikaGoColors.forestGreen,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: FikaGoColors.forestGreen,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // 4. INPUT YA PASSWORD
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.montserrat(fontSize: 16),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: FikaGoColors.forestGreen,
                                    ),
                                    hintText: context.localized(
                                        'Password yako', 'Your password'),
                                    labelText: context.localized(
                                        'Password', 'Password'),
                                    labelStyle: GoogleFonts.montserrat(
                                      color: FikaGoColors.forestGreen,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: FikaGoColors.charcoal,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: FikaGoColors.lightGreen,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: FikaGoColors.forestGreen,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: FikaGoColors.forestGreen,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: FikaGoColors.forestGreen,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // 5. BUTTON YA KUNGIA (PASSWORD)
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _loginWithPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FikaGoColors.sunYellow,
                                      foregroundColor: FikaGoColors.charcoal,
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: FikaGoColors.charcoal,
                                            ),
                                          )
                                        : Text(
                                            context.localized(
                                                'INGIA', 'LOG IN'),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),

                                if (widget.role != 'vendor' &&
                                    widget.role != 'admin') ...[
                                  const SizedBox(height: 16),

                                  // 6. DIVIDER
                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          context.localized('AU', 'OR'),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 12,
                                            color: FikaGoColors.charcoal,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // 7. BUTTON YA OTP
                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: OutlinedButton(
                                      onPressed: _isLoading ? null : _sendOtp,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            FikaGoColors.forestGreen,
                                        side: const BorderSide(
                                          color: FikaGoColors.forestGreen,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        context.localized(
                                            'INGIA KWA OTP', 'LOG IN WITH OTP'),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),
                                ],

                                // Admin accounts are provisioned by IT; only other
                                // roles can register from the app.
                                if (widget.role == 'admin')
                                  Text(
                                    context.localized(
                                      'Ili kupata akaunti ya admin, wasiliana na timu ya IT.',
                                      'To request an admin account, contact the IT team.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      color: FikaGoColors.charcoal,
                                    ),
                                  )
                                else
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.role == 'vendor'
                                            ? context.localized(
                                                'Huna akaunti ya mgahawa?',
                                                'Do not have a vendor account? ')
                                            : context.localized('Huna akaunti?',
                                                "Don't have an account? "),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 13,
                                          color: FikaGoColors.charcoal,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => widget.role ==
                                                      'rider'
                                                  ? const RiderRegisterScreen()
                                                  : RegisterScreen(
                                                      role: widget.role),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          widget.role == 'vendor'
                                              ? context.localized(
                                                  'Sajili Mgahawa',
                                                  'Register a vendor')
                                              : context.localized('Sajili Hapa',
                                                  'Register here'),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: FikaGoColors.forestGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 9. FOOTER TEXT
                      Text(
                        context.localized(
                          'Kwa kuendelea, unakubali Masharti na Sera yetu',
                          'By continuing, you agree to our Terms and Privacy Policy',
                        ),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: FikaGoColors.lightGreen.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TanzaniaPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 9) digits = digits.substring(0, 9);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
