// ============================================================
// FIKAGO RIDER - REGISTRATION (Bolt Style)
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import 'rider_pending_screen.dart';

class RiderRegisterScreen extends StatefulWidget {
  const RiderRegisterScreen({super.key});

  @override
  State<RiderRegisterScreen> createState() => _RiderRegisterScreenState();
}

class _RiderRegisterScreenState extends State<RiderRegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _plateController = TextEditingController();
  String _vehicleType = 'motorcycle';

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final license = _licenseController.text.trim();
    final plate = _plateController.text.trim();
    if ([name, phone, password, license, plate].any((value) => value.isEmpty)) {
      _showMessage(context.localized(
          'Jaza sehemu zote muhimu.', 'Please complete all required fields.'));
      return;
    }
    if (password.length < 6) {
      _showMessage(context.localized(
          'Password iwe na herufi au tarakimu 6 au zaidi.',
          'Password must be at least 6 characters long.'));
      return;
    }

    setState(() => _isLoading = true);
    final response = await AuthService.register(
      fullName: name,
      phoneNumber: phone,
      password: password,
      role: 'rider',
      vehicleType: _vehicleType,
      licenseNumber: license,
      licensePlate: plate,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['success'] != true) {
      final serverMessage = response['message']?.toString() ?? '';
      final message = context.locale.languageCode == 'en'
          ? serverMessage.contains('imesajiliwa tayari')
              ? 'This account already exists. Please log in or use different details.'
              : serverMessage.contains('Namba ya simu si sahihi')
                  ? 'Enter a valid Tanzanian phone number.'
                  : serverMessage.contains('usajili wa rider')
                      ? 'Please complete all required rider details.'
                      : 'Registration failed. Please try again.'
          : serverMessage.isNotEmpty
              ? serverMessage
              : 'Usajili umeshindikana. Tafadhali jaribu tena.';
      _showMessage(message);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RiderPendingScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.white,
      appBar: AppBar(
        title: Text(context.localized('Jisajili kama Dereva', 'Rider sign up'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => context.setLocale(
                Locale(context.locale.languageCode == 'en' ? 'sw' : 'en')),
            icon: const Icon(Icons.language),
            label: Text(context.locale.languageCode == 'en' ? 'SW' : 'EN'),
          ),
        ],
        backgroundColor: Colors.transparent,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    context.localized(
                        'Karibu FikaGo Rider', 'Welcome to FikaGo Rider'),
                    style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: FikaGoColors.forestGreen)),
                const SizedBox(height: 8),
                Text(
                    context.localized(
                        'Jaza taarifa zako ili uanze kufanya kazi.',
                        'Enter your details to get started.'),
                    style: GoogleFonts.montserrat(color: FikaGoColors.grey)),
                const SizedBox(height: 32),

                _buildTextField(
                    _nameController,
                    context.localized('Jina Kamili', 'Full name'),
                    Icons.person),
                const SizedBox(height: 16),
                _buildTextField(
                    _phoneController,
                    context.localized('Namba ya Simu', 'Phone number'),
                    Icons.phone,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(_passwordController,
                    context.localized('Password', 'Password'), Icons.lock,
                    obscureText: true),
                const SizedBox(height: 16),

                // Dropdown ya Gari
                DropdownButtonFormField<String>(
                  value: _vehicleType,
                  decoration: InputDecoration(
                    labelText:
                        context.localized('Aina ya Gari', 'Vehicle type'),
                    prefixIcon: const Icon(Icons.directions_bike,
                        color: FikaGoColors.forestGreen),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['motorcycle', 'bicycle', 'car'].map((String val) {
                    final label = switch (val) {
                      'motorcycle' =>
                        context.localized('Pikipiki', 'Motorcycle'),
                      'bicycle' => context.localized('Baiskeli', 'Bicycle'),
                      _ => context.localized('Gari', 'Car'),
                    };
                    return DropdownMenuItem(value: val, child: Text(label));
                  }).toList(),
                  onChanged: (val) => setState(() => _vehicleType = val!),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                    _licenseController,
                    context.localized(
                        'Namba ya Leseni', 'Driver licence number'),
                    Icons.badge),
                const SizedBox(height: 16),
                _buildTextField(
                    _plateController,
                    context.localized(
                        'Namba ya Gari (Plate)', 'Vehicle plate number'),
                    Icons.pin),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FikaGoColors.forestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            context.localized(
                                'TUMA MAOMBI', 'SUBMIT APPLICATION'),
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, bool obscureText = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixText: keyboardType == TextInputType.phone ? '+255 ' : null,
        prefixIcon: Icon(icon, color: FikaGoColors.forestGreen),
        suffixIcon: identical(controller, _passwordController)
            ? IconButton(
                tooltip: _obscurePassword
                    ? context.localized('Onyesha password', 'Show password')
                    : context.localized('Ficha password', 'Hide password'),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      obscureText: identical(controller, _passwordController)
          ? _obscurePassword
          : obscureText,
    );
  }
}
