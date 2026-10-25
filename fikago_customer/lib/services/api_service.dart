// ============================================================
// FIKAGO - API SERVICE (HTTP Client)
// ============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _token;
  static String _languageCode = 'sw';

  static void setToken(String token) {
    _token = token;
  }

  static void setLanguage(String languageCode) {
    _languageCode = languageCode;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': _languageCode,
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Multipart requests must omit Content-Type so the HTTP client can add
  // the boundary, while still sending the signed-in user's token.
  static Map<String, String> get multipartHeaders => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // GET Request
  static Future<Map<String, dynamic>> get(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // POST Request
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // PUT Request
  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // DELETE Request
  static Future<Map<String, dynamic>> delete(String url) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Handle Response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic>
          ? data
          : {'success': false, 'message': 'Invalid response'};
    } catch (e) {
      return {'success': false, 'message': 'Parse error: $e'};
    }
  }
}
