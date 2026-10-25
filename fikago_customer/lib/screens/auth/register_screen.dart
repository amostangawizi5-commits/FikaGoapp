// ============================================================
// FIKAGO - REGISTER SCREEN (With Phone Number)
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
import '../customer/home/home_screen.dart';
import '../vendor/vendor_dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  final bool returnToCaller;

  const RegisterScreen({
    super.key,
    this.role = 'customer',
    this.returnToCaller = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _restaurantNameController = TextEditingController();
  final _restaurantLocationController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool get _isVendor => widget.role == 'vendor';

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _restaurantLocationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final restaurantName = _restaurantNameController.text.trim();
    final restaurantLocation = _restaurantLocationController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = normalizeTzPhone(_phoneController.text);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // ============================================
    // 1. VALIDATION
    // ============================================

    // Hakikisha namba ya simu ipo na inaanza na +255 au 0
    if (phone == null) {
      _showError(context.localized('Tafadhali ingiza namba yako ya simu',
          'Enter a valid phone number with 9 digits after +255'));
      return;
    }

    if ((_isVendor &&
            (restaurantName.isEmpty ||
                restaurantLocation.isEmpty ||
                email.isEmpty)) ||
        (!_isVendor && (firstName.isEmpty || lastName.isEmpty)) ||
        password.isEmpty) {
      _showError(_isVendor
          ? 'Jaza jina la mgahawa, email, eneo na password.'
          : context.localized(
              'Tafadhali jaza jina la kwanza, la mwisho na password',
              'Please enter your first name, last name, and password'));
      return;
    }

    if (password != confirmPassword) {
      _showError(context.localized(
          'Password hazifanani. Tafadhali rudia vizuri.',
          'Passwords do not match. Please try again.'));
      return;
    }

    if (password.length < 6) {
      _showError(context.localized('Password lazima iwe na herufi 6 au zaidi',
          'Password must be at least 6 characters'));
      return;
    }

    // ============================================
    // 2. ANZA KUTUMA KWA BACKEND
    // ============================================
    setState(() => _isLoading = true);

    final response = await AuthService.register(
      fullName: _isVendor ? restaurantName : '$firstName $lastName',
      phoneNumber: phone,
      email: email.isEmpty ? null : email,
      password: password,
      role: widget.role,
      restaurantName: _isVendor ? restaurantName : null,
      restaurantLocation: _isVendor ? restaurantLocation : null,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    // ============================================
    // 3. ANGALIA MAJIBU
    // ============================================
    if (response['success'] == true) {
      final data = response['data'];
      final token = data['token'];
      final user = data['user'];

      // Hifadhi token kwenye provider
      await context.read<AuthProvider>().setAuth(
            token: token,
            user: user,
          );

      if (!mounted) return;

      // Onyesha ujumbe wa mafanikio
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localized('Usajili umefanikiwa! Karibu FikaGo.',
              'Registration successful! Welcome to FikaGo.')),
          backgroundColor: FikaGoColors.forestGreen,
        ),
      );

      // Peleka vendor kwenye dashboard yake, na customer kwenye ukurasa wa mwanzo.
      if (widget.returnToCaller) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _isVendor ? const VendorDashboardScreen() : const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } else {
      _showError(response['message'] ?? 'Imeshindwa kusajili. Jaribu tena.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FikaGoColors.charcoal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.forestGreen,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 20,
              shadowColor: FikaGoColors.charcoal.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/fikaGO.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      _isVendor
                          ? context.localized(
                              'Sajili Mgahawa', 'Register a vendor')
                          : context.localized(
                              'Sajili Akaunti', 'Create Account'),
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: FikaGoColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isVendor
                          ? context.localized(
                              'Weka taarifa za mgahawa wako ili kufungua akaunti ya vendor.',
                              'Enter your restaurant details to create a vendor account.')
                          : context.localized(
                              'Jaza taarifa zako ili kuanza kuagiza',
                              'Enter your details to start ordering'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: FikaGoColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (_isVendor) ...[
                      TextField(
                        controller: _restaurantNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.store,
                              color: FikaGoColors.forestGreen),
                          labelText: context.localized(
                              'Jina la mgahawa', 'Restaurant name'),
                          hintText: context.localized(
                              'Mfano: Mama Ntilie', 'e.g. Mama Ntilie'),
                          labelStyle: GoogleFonts.montserrat(
                              color: FikaGoColors.forestGreen),
                          filled: true,
                          fillColor: FikaGoColors.lightGreen,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // 1. FIRST AND LAST NAME
                      TextField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person,
                              color: FikaGoColors.forestGreen),
                          hintText:
                              context.localized('Jina la kwanza', 'First name'),
                          labelText:
                              context.localized('Jina la kwanza', 'First name'),
                          labelStyle: GoogleFonts.montserrat(
                              color: FikaGoColors.forestGreen),
                          filled: true,
                          fillColor: FikaGoColors.lightGreen,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline,
                              color: FikaGoColors.forestGreen),
                          hintText:
                              context.localized('Jina la mwisho', 'Last name'),
                          labelText:
                              context.localized('Jina la mwisho', 'Last name'),
                          labelStyle: GoogleFonts.montserrat(
                              color: FikaGoColors.forestGreen),
                          filled: true,
                          fillColor: FikaGoColors.lightGreen,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. NAMBA YA SIMU (MUHIMU)
                    TextField(
                      controller: _phoneController,
                      keyboardType:
                          TextInputType.phone, // Inafungua keyboard ya namba
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixText: '+255 ',
                        prefixStyle: GoogleFonts.montserrat(
                          color: FikaGoColors.forestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                        hintText: '712 345 678',
                        labelText:
                            context.localized('Namba ya Simu', 'Phone Number'),
                        labelStyle: GoogleFonts.montserrat(
                            color: FikaGoColors.forestGreen),
                        filled: true,
                        fillColor: FikaGoColors.lightGreen,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vendor registration requires email; customer signup does not.
                    if (_isVendor) ...[
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email,
                              color: FikaGoColors.forestGreen),
                          hintText: context.localized(
                              'Mfano: ali@gmail.com', 'e.g. ali@gmail.com'),
                          labelText: context.localized(
                              'Anwani ya barua pepe', 'Email address'),
                          labelStyle: GoogleFonts.montserrat(
                              color: FikaGoColors.forestGreen),
                          filled: true,
                          fillColor: FikaGoColors.lightGreen,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_isVendor) ...[
                      TextField(
                        controller: _restaurantLocationController,
                        textCapitalization: TextCapitalization.words,
                        maxLines: 2,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on,
                              color: FikaGoColors.forestGreen),
                          labelText: context.localized(
                              'Eneo la mgahawa', 'Restaurant location'),
                          hintText: context.localized(
                              'Eneo / anwani ya mgahawa', 'Restaurant address'),
                          labelStyle: GoogleFonts.montserrat(
                              color: FikaGoColors.forestGreen),
                          filled: true,
                          fillColor: FikaGoColors.lightGreen,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 4. PASSWORD
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock,
                            color: FikaGoColors.forestGreen),
                        hintText: context.localized(
                            'Herufi 6 au zaidi', 'At least 6 characters'),
                        labelText: context.localized('Password', 'Password'),
                        labelStyle: GoogleFonts.montserrat(
                            color: FikaGoColors.forestGreen),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: FikaGoColors.charcoal,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: FikaGoColors.lightGreen,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. RUDIA PASSWORD
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: FikaGoColors.forestGreen),
                        hintText: context.localized(
                            'Rudia password yako', 'Re-enter your password'),
                        labelText: context.localized(
                            'Rudia Password', 'Confirm Password'),
                        labelStyle: GoogleFonts.montserrat(
                            color: FikaGoColors.forestGreen),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: FikaGoColors.charcoal,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                        filled: true,
                        fillColor: FikaGoColors.lightGreen,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // BUTTON YA KUSAJILI
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
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
                                    'SAJILI SASA', 'REGISTER NOW'),
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // LINK YA KUINGIA
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        context.localized('Nina akaunti tayari? Ingia',
                            'Already have an account? Log in'),
                        style: GoogleFonts.montserrat(
                          color: FikaGoColors.forestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
