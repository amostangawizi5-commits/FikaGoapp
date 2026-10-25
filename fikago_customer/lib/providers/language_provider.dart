import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LanguageProvider extends ChangeNotifier {
  static const _preferenceKey = 'language_code';
  String _languageCode = 'sw';

  String get languageCode => _languageCode;
  bool get isEnglish => _languageCode == 'en';

  Future<void> loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    _languageCode = preferences.getString(_preferenceKey) ?? 'sw';
    ApiService.setLanguage(_languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'sw') {
      throw ArgumentError.value(languageCode, 'languageCode', 'Expected en or sw');
    }
    if (_languageCode == languageCode) return;

    _languageCode = languageCode;
    ApiService.setLanguage(languageCode);
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, languageCode);
  }
}
