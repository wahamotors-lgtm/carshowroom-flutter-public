import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Try to parse error response
    try {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      return errorBody;
    } catch (_) {
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالسيرفر (${response.statusCode})',
      };
    }
  }

  Future<Map<String, dynamic>> get(
    String url, {
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    try {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      return errorBody;
    } catch (_) {
      return {
        'success': false,
        'message': 'خطأ في الاتصال بالسيرفر (${response.statusCode})',
      };
    }
  }
}
