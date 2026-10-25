// ============================================================
// FIKAGO - AUTH PROVIDER
// ============================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;

  // Set token + user (baada ya login)
  Future<void> setAuth({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _token = token;
    _user = user;
    ApiService.setToken(token);

    // Save kwenye SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

    notifyListeners();
  }

  // Load token kutoka storage (wakati app inafunguka)
  Future<void> loadToken() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      ApiService.setToken(_token!);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    ApiService.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    notifyListeners();
  }
}
