import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    debugPrint('API GET: $url');
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );

    debugPrint('API GET $url -> ${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      // Handle endpoints that return an array (e.g. company-settings)
      if (decoded is List) {
        if (decoded.isNotEmpty && decoded.first is Map) {
          return Map<String, dynamic>.from(decoded.first);
        }
        return {'data': decoded};
      }
      return {'data': decoded};
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
    debugPrint('API GET_LIST: $url');
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );

    debugPrint('API GET_LIST $url -> ${response.statusCode}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        debugPrint('API GET_LIST $url -> List(${decoded.length} items)');
        return decoded;
      }
      if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'] as List;
        debugPrint('API GET_LIST $url -> Map.data(${data.length} items)');
        return data;
      }
      debugPrint('API GET_LIST $url -> unexpected format: ${decoded.runtimeType}');
      return [];
    }

    debugPrint('API GET_LIST $url -> error: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
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
