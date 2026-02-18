import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final http.Client _client = http.Client();

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(body),
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

  Future<Map<String, dynamic>> get(
    String url, {
    String? token,
  }) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(token: token),
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

  /// GET request that returns a list (for endpoints like /api/accounts)
  Future<List<dynamic>> getList(
    String url, {
    String? token,
  }) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded.containsKey('data')) {
        return decoded['data'] as List;
      }
      return [];
    }

    return [];
  }

  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client.put(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(body),
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

  Future<Map<String, dynamic>> delete(
    String url, {
    String? token,
  }) async {
    final response = await _client.delete(
      Uri.parse(url),
      headers: _headers(token: token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return {'success': true};
      }
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
