// ============================================================
// FIKAGO - API CONFIGURATION
// ============================================================
import 'package:flutter/foundation.dart';

class ApiConfig {
  // ============================================================
  // BASE URL
  // ============================================================
  // - Physical device on the current Wi-Fi: http://172.25.52.113:5000
  // - Android Emulator: override with http://10.0.2.2:5000
  // - iOS Simulator: http://localhost:5000
  // - Physical Device: pass your computer's Wi-Fi IP with
  //   --dart-define=API_BASE_URL_DEVICE=http://192.168.1.10:5000
  // - Chrome/Web: defaults to http://localhost:5000
  // ============================================================
  // Optional shared override for cases where one URL should be used on every
  // platform. Prefer the platform-specific values below for web + device.
  static const String _sharedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _webBaseUrl = String.fromEnvironment(
    'API_BASE_URL_WEB',
    defaultValue: 'http://localhost:5000',
  );
  static const String _deviceBaseUrl = String.fromEnvironment(
    'API_BASE_URL_DEVICE',
    defaultValue: 'http://172.25.52.113:5000',
  );

  static String get baseUrl {
    if (_sharedBaseUrl.isNotEmpty) return _sharedBaseUrl;
    return kIsWeb ? _webBaseUrl : _deviceBaseUrl;
  }

  // ============================================================
  // AUTH ENDPOINTS
  // ============================================================
  static String get sendOtp => '$baseUrl/api/auth/send-otp';
  static String get verifyOtp => '$baseUrl/api/auth/verify-otp';
  static String get register => '$baseUrl/api/auth/register';
  static String get login => '$baseUrl/api/auth/login';
  static String get profile => '$baseUrl/api/auth/profile';

  // ============================================================
  // RESTAURANT ENDPOINTS
  // ============================================================
  static String get restaurants => '$baseUrl/api/restaurants';
  static String get searchMenu => '$baseUrl/api/restaurants/search/menu';
  static String get featuredMenu => '$baseUrl/api/restaurants/featured/menu';
  static String get reverseGeocode => '$baseUrl/api/location/reverse-geocode';
  static String get locationSearch => '$baseUrl/api/location/search';

  // ============================================================
  // CART ENDPOINTS
  // ============================================================
  static String get cart => '$baseUrl/api/cart';
  static String get addToCart => '$baseUrl/api/cart/add';
  static String get applyPromo => '$baseUrl/api/cart/promo';

  // ============================================================
  // ORDER ENDPOINTS
  // ============================================================
  static String get orders => '$baseUrl/api/orders';

  // ============================================================
  // WALLET ENDPOINTS
  // ============================================================
  static String get wallet => '$baseUrl/api/wallet';
  static String get walletTransactions => '$baseUrl/api/wallet/transactions';

  // Vendor menu endpoints
  static String get vendorMenu => '$baseUrl/api/vendor/menu';
  static String get vendorMenuItems => '$vendorMenu/items';
  static String get vendorOrders => '$baseUrl/api/vendor/orders';
  static String get vendorProfile => '$baseUrl/api/vendor/profile';
  static String get vendorReviews => '$baseUrl/api/vendor/reviews';
  static String get admin => '$baseUrl/api/admin';

  // ============================================================
  // PAYMENT ENDPOINTS
  // ============================================================
  static String get initiatePayment => '$baseUrl/api/payments/initiate';
}
