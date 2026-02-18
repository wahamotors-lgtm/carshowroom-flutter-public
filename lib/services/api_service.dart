import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client = http.Client();

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _handleNetworkError(Object e) {
    if (e is SocketException) {
      return 'لا يوجد اتصال بالإنترنت';
    } else if (e is HttpException) {
      return 'خطأ في الاتصال بالسيرفر';
    } else if (e is FormatException) {
      return 'خطأ في تنسيق البيانات';
    } else if (e.toString().contains('HandshakeException') || e.toString().contains('CERTIFICATE')) {
      return 'خطأ في شهادة SSL';
    } else if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
      return 'انتهت مهلة الاتصال';
    }
    return 'خطأ غير متوقع: ${e.runtimeType}';
  }

  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      debugPrint('API POST: $url');
      final response = await _client.post(
        Uri.parse(url),
        headers: _headers(token: token),
        body: jsonEncode(body),
      );

      debugPrint('API POST $url -> ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          errorBody['message'] ?? errorBody['error'] ?? 'خطأ من السيرفر (${response.statusCode})',
          statusCode: response.statusCode,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('خطأ من السيرفر (${response.statusCode})', statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('API POST Error: $e');
      throw ApiException(_handleNetworkError(e));
    }
  }

  Future<Map<String, dynamic>> get(
    String url, {
    String? token,
  }) async {
    try {
      debugPrint('API GET: $url');
      final response = await _client.get(
        Uri.parse(url),
        headers: _headers(token: token),
      );

      debugPrint('API GET $url -> ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        // Handle endpoints that return an array (e.g. company-settings, store-settings)
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
        throw ApiException(
          errorBody['message'] ?? errorBody['error'] ?? 'خطأ من السيرفر (${response.statusCode})',
          statusCode: response.statusCode,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('خطأ من السيرفر (${response.statusCode})', statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('API GET Error: $e');
      throw ApiException(_handleNetworkError(e));
    }
  }

  /// GET request that returns a list (for endpoints like /api/accounts)
  Future<List<dynamic>> getList(
    String url, {
    String? token,
  }) async {
    try {
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
        if (decoded is Map) {
          if (decoded.containsKey('data')) return decoded['data'] as List;
          if (decoded.containsKey('items')) return decoded['items'] as List;
          if (decoded.containsKey('results')) return decoded['results'] as List;
        }
        debugPrint('API GET_LIST $url -> unexpected format: ${decoded.runtimeType}');
        return [];
      }

      if (response.statusCode == 401) {
        throw ApiException('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى', statusCode: 401);
      }
      if (response.statusCode == 403) {
        throw ApiException('ليس لديك صلاحية للوصول لهذه البيانات', statusCode: 403);
      }
      if (response.statusCode == 404) {
        throw ApiException('المسار غير موجود', statusCode: 404);
      }

      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map) {
          final msg = errorBody['message'] ?? errorBody['error'] ?? '';
          if (msg.toString().isNotEmpty) {
            throw ApiException(msg.toString(), statusCode: response.statusCode);
          }
        }
      } catch (e) {
        if (e is ApiException) rethrow;
      }

      throw ApiException('خطأ من السيرفر (${response.statusCode})', statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('API GET_LIST Error: $e');
      throw ApiException(_handleNetworkError(e));
    }
  }

  Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      debugPrint('API PUT: $url');
      final response = await _client.put(
        Uri.parse(url),
        headers: _headers(token: token),
        body: jsonEncode(body),
      );

      debugPrint('API PUT $url -> ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          errorBody['message'] ?? errorBody['error'] ?? 'خطأ من السيرفر (${response.statusCode})',
          statusCode: response.statusCode,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('خطأ من السيرفر (${response.statusCode})', statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('API PUT Error: $e');
      throw ApiException(_handleNetworkError(e));
    }
  }

  Future<Map<String, dynamic>> delete(
    String url, {
    String? token,
  }) async {
    try {
      debugPrint('API DELETE: $url');
      final response = await _client.delete(
        Uri.parse(url),
        headers: _headers(token: token),
      );

      debugPrint('API DELETE $url -> ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          return jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          return {'success': true};
        }
      }

      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          errorBody['message'] ?? errorBody['error'] ?? 'خطأ من السيرفر (${response.statusCode})',
          statusCode: response.statusCode,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('خطأ من السيرفر (${response.statusCode})', statusCode: response.statusCode);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('API DELETE Error: $e');
      throw ApiException(_handleNetworkError(e));
    }
  }
}
