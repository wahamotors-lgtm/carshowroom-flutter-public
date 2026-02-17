import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  AuthState _state = AuthState.initial;
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _tenant;
  Map<String, dynamic>? _employee;
  String? _errorMessage;
  String _loginType = 'tenant';

  AuthProvider(this._authService, this._storageService);

  AuthState get state => _state;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get tenant => _tenant;
  Map<String, dynamic>? get employee => _employee;
  String? get errorMessage => _errorMessage;
  String get loginType => _loginType;
  bool get isAuthenticated => _state == AuthState.authenticated;

  /// Check for saved session on app start
  Future<bool> tryAutoLogin() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }

      final valid = await _authService.verifyToken();
      if (valid) {
        _token = token;
        _user = await _storageService.getUser();
        _tenant = await _storageService.getTenant();
        _employee = await _storageService.getEmployee();
        _loginType = await _storageService.getLoginType() ?? 'tenant';
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        await _storageService.clearAll();
        _state = AuthState.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (_) {
      // Network error - still try if token exists locally
      final token = await _storageService.getToken();
      if (token != null) {
        _token = token;
        _user = await _storageService.getUser();
        _tenant = await _storageService.getTenant();
        _employee = await _storageService.getEmployee();
        _loginType = await _storageService.getLoginType() ?? 'tenant';
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      }
      _state = AuthState.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Tenant login
  Future<Map<String, dynamic>> loginTenant(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.tenantLogin(email, password);

      if (response['success'] == true) {
        _token = response['token'];
        _user = response['user'];
        _tenant = response['tenant'];
        _loginType = 'tenant';
        _state = AuthState.authenticated;
        notifyListeners();
      } else {
        _errorMessage = response['message'] ?? 'فشل تسجيل الدخول';
        _state = AuthState.unauthenticated;
        notifyListeners();
      }

      return response;
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
      _state = AuthState.error;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Tenant register
  Future<Map<String, dynamic>> registerTenant({
    required String companyName,
    required String ownerName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.tenantRegister(
        companyName: companyName,
        ownerName: ownerName,
        email: email,
        password: password,
        phone: phone,
      );

      _state = AuthState.unauthenticated;
      if (response['success'] != true) {
        _errorMessage = response['message'] ?? 'فشل التسجيل';
      }
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
      _state = AuthState.error;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Tenant activate
  Future<Map<String, dynamic>> activateTenant(String tenantId, String code) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.tenantActivate(tenantId, code);

      if (response['success'] == true) {
        _token = response['token'];
        _tenant = response['tenant'];
        _loginType = 'tenant';
        _state = AuthState.authenticated;
      } else {
        _errorMessage = response['message'] ?? 'فشل التفعيل';
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
      _state = AuthState.error;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Employee login
  Future<Map<String, dynamic>> loginEmployee(
    String companyEmail,
    String employeeCode,
    String password,
  ) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.employeeLogin(
        companyEmail,
        employeeCode,
        password,
      );

      if (response['success'] == true && response['requiresOTP'] != true) {
        _token = response['token'];
        _employee = response['employee'];
        _loginType = 'employee';
        _state = AuthState.authenticated;
      } else if (response['success'] != true && response['requiresOTP'] != true) {
        _errorMessage = response['message'] ?? 'فشل تسجيل الدخول';
        _state = AuthState.unauthenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
      _state = AuthState.error;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Employee verify OTP
  Future<Map<String, dynamic>> verifyEmployeeOtp(String employeeId, String otp) async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final response = await _authService.employeeVerifyOtp(employeeId, otp);

      if (response['success'] == true) {
        _token = response['token'];
        _employee = response['employee'];
        _loginType = 'employee';
        _state = AuthState.authenticated;
      } else {
        _errorMessage = response['message'] ?? 'رمز التحقق غير صحيح';
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالسيرفر';
      _state = AuthState.error;
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Resend activation code
  Future<Map<String, dynamic>> resendActivationCode(String tenantId) async {
    try {
      return await _authService.resendCode(tenantId);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر'};
    }
  }

  /// Resend employee OTP
  Future<Map<String, dynamic>> resendEmployeeOtp(String employeeId) async {
    try {
      return await _authService.resendOtp(employeeId);
    } catch (e) {
      return {'success': false, 'message': 'خطأ في الاتصال بالسيرفر'};
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    _token = null;
    _user = null;
    _tenant = null;
    _employee = null;
    _loginType = 'tenant';
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
