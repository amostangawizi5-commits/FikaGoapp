// ============================================================
// FIKAGO - AUTH SERVICE
// ============================================================
import '../config/api_config.dart';
import '../utils/phone_number.dart';
import 'api_service.dart';

class AuthService {
  // Register with phone number and password
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    String? email,
    required String password,
    String role = 'customer',
    String? restaurantName,
    String? restaurantLocation,
    String? vehicleType,
    String? licenseNumber,
    String? licensePlate,
  }) async {
    return await ApiService.post(
      ApiConfig.register,
      {
        'full_name': fullName,
        'phone_number': normalizeTzPhone(phoneNumber) ?? phoneNumber.trim(),
        if (email != null) 'email': email,
        'password': password,
        'role': role,
        if (restaurantName != null) 'restaurant_name': restaurantName,
        if (restaurantLocation != null)
          'restaurant_location': restaurantLocation,
        if (vehicleType != null) 'vehicle_type': vehicleType,
        if (licenseNumber != null) 'license_number': licenseNumber,
        if (licensePlate != null) 'license_plate': licensePlate,
      },
    );
  }

  // Login with phone number and password
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
    String? role,
  }) async {
    return await ApiService.post(
      ApiConfig.login,
      {
        'phone_number': normalizeTzPhone(phoneNumber) ?? phoneNumber.trim(),
        'password': password,
        if (role != null) 'role': role,
      },
    );
  }

  // Send OTP
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    return await ApiService.post(
      ApiConfig.sendOtp,
      {'phone_number': normalizeTzPhone(phoneNumber) ?? phoneNumber.trim()},
    );
  }

  // Verify OTP + Login
  static Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    String? fullName,
    String? email,
  }) async {
    return await ApiService.post(
      ApiConfig.verifyOtp,
      {
        'phone_number': normalizeTzPhone(phoneNumber) ?? phoneNumber.trim(),
        'otp_code': otpCode,
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
      },
    );
  }

  // Get Profile
  static Future<Map<String, dynamic>> getProfile() async {
    return await ApiService.get(ApiConfig.profile);
  }

  // Update Profile
  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? languagePref,
  }) async {
    return await ApiService.put(
      ApiConfig.profile,
      {
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (languagePref != null) 'language_pref': languagePref,
      },
    );
  }
}
