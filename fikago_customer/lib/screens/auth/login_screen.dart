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
import '../../utils/phone_number.dart';
import '../customer/home/home_screen.dart'; // Home ya Mteja
import '../vendor/vendor_dashboard_screen.dart'; // Dashboard ya Mgahawa (Vendor)
import '../admin/admin_dashboard_screen.dart';
import '../rider/rider_dashboard_screen.dart';
import '../rider/rider_register_screen.dart';
import 'register_screen.dart';
import 'otp_screen.dart';
import 'customer_auth_layout.dart';

class LoginScreen extends StatefulWidget {
  final String role; // Inatoka kwenye Role Selection
  final ValueChanged<int>? onNavigateToTab;

  const LoginScreen({
    super.key,
    this.role = 'customer',
    this.onNavigateToTab,
  });

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
    if (widget.role == 'customer') return _buildCustomerLogin(context);

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
                      if (widget.role == 'rider') ...[
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: FikaGoColors.lightGreen,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(Icons.arrow_back, size: 19),
                              label: Text(
                                context.localized(
                                  'Rudi kwenye uchaguzi wa akaunti',
                                  'Back to role selection',
                                ),
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
                                      : widget.role == 'admin'
                                          ? context.localized(
                                              'Ingia kama Msimamizi',
                                              'Administrator sign in')
                                          : context.localized('Karibu FikaGo',
                                              'Welcome to FikaGo'),
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
                                      : widget.role == 'admin'
                                          ? context.localized(
                                              'Ingia kwa akaunti ya msimamizi iliyoidhinishwa.',
                                              'Sign in with an authorized administrator account.',
                                            )
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

  Widget _buildCustomerLogin(BuildContext context) => CustomerAuthLayout(
        onNavigateToTab: widget.onNavigateToTab,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Text(
              context.localized('Ingia kwenye Akaunti', 'Log In'),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: FikaGoColors.charcoal),
            ),
            const SizedBox(height: 5),
            Text(
              context.localized('Karibu tena FikaGo', 'Welcome back to FikaGo'),
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: FikaGoColors.grey),
            ),
            const SizedBox(height: 22),
            _customerLoginField(
              context,
              label: context.localized('Namba ya Simu', 'Phone Number'),
              hint: '711 123 456',
              controller: _phoneController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [TanzaniaPhoneInputFormatter()],
              prefixText: '+255  ',
            ),
            const SizedBox(height: 12),
            _customerLoginField(
              context,
              label: context.localized('Nenosiri', 'Password'),
              hint: context.localized(
                  'Ingiza nenosiri lako', 'Enter your password'),
              controller: _passwordController,
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffix: IconButton(
                tooltip: context.localized('Onyesha nenosiri', 'Show password'),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 49,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginWithPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FikaGoColors.sunYellow,
                  foregroundColor: FikaGoColors.charcoal,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: FikaGoColors.charcoal),
                      )
                    : Text(context.localized('Ingia Sasa', 'Log In Now'),
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: Text(
                    context.localized('Ingia kwa OTP', 'Log in with OTP'),
                    style: GoogleFonts.montserrat(
                        color: FikaGoColors.forestGreen, fontSize: 11)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                    context.localized(
                        'Huna akaunti? ', "Don't have an account? "),
                    style: GoogleFonts.montserrat(
                        fontSize: 11, color: FikaGoColors.grey)),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterScreen(
                        onNavigateToTab: widget.onNavigateToTab,
                      ),
                    ),
                  ),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 3)),
                  child: Text(context.localized('Jisajili sasa', 'Sign up'),
                      style: GoogleFonts.montserrat(
                          color: FikaGoColors.forestGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _customerLoginField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    String? prefixText,
    Widget? suffix,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 11, color: FikaGoColors.charcoal)),
          const SizedBox(height: 3),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 9,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              obscureText: obscureText,
              style: GoogleFonts.montserrat(fontSize: 12),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: FikaGoColors.grey, size: 20),
                prefixText: prefixText,
                prefixStyle: GoogleFonts.montserrat(
                    color: FikaGoColors.charcoal, fontSize: 12),
                hintText: hint,
                hintStyle: GoogleFonts.montserrat(
                    color: FikaGoColors.grey, fontSize: 12),
                suffixIcon: suffix,
                filled: true,
                fillColor: const Color(0xFFF0F1F0),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                        color: FikaGoColors.forestGreen, width: 1.2)),
              ),
            ),
          ),
        ],
      );
}
