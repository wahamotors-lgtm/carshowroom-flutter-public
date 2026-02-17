import '../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api;
  final StorageService _storage;

  AuthService(this._api, this._storage);

  /// Tenant login
  Future<Map<String, dynamic>> tenantLogin(String email, String password) async {
    final response = await _api.post(ApiConfig.tenantLogin, {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    if (response['success'] == true && response['token'] != null) {
      await _storage.saveToken(response['token']);
      if (response['user'] != null) {
        await _storage.saveUser(response['user']);
      }
      if (response['tenant'] != null) {
        await _storage.saveTenant(response['tenant']);
      }
      await _storage.saveLoginType('tenant');
    }

    return response;
  }

  /// Tenant register
  Future<Map<String, dynamic>> tenantRegister({
    required String companyName,
    required String ownerName,
    required String email,
    required String password,
    String? phone,
  }) async {
    return await _api.post(ApiConfig.tenantRegister, {
      'companyName': companyName.trim(),
      'ownerName': ownerName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
    });
  }

  /// Tenant activate
  Future<Map<String, dynamic>> tenantActivate(String tenantId, String code) async {
    final response = await _api.post(ApiConfig.tenantActivate, {
      'tenantId': tenantId,
      'activationCode': code.trim(),
    });

    if (response['success'] == true && response['token'] != null) {
      await _storage.saveToken(response['token']);
      if (response['tenant'] != null) {
        await _storage.saveTenant(response['tenant']);
      }
      await _storage.saveLoginType('tenant');
    }

    return response;
  }

  /// Resend activation code
  Future<Map<String, dynamic>> resendCode(String tenantId) async {
    return await _api.post(ApiConfig.tenantResendCode, {
      'tenantId': tenantId,
    });
  }

  /// Employee login
  Future<Map<String, dynamic>> employeeLogin(
    String companyEmail,
    String employeeCode,
    String password,
  ) async {
    final response = await _api.post(ApiConfig.tenantEmployeeLogin, {
      'companyEmail': companyEmail.trim().toLowerCase(),
      'employeeCode': employeeCode.trim(),
      'password': password,
    });

    if (response['success'] == true && response['token'] != null) {
      await _storage.saveToken(response['token']);
      if (response['employee'] != null) {
        await _storage.saveEmployee(response['employee']);
      }
      await _storage.saveLoginType('employee');
    }

    return response;
  }

  /// Employee verify OTP
  Future<Map<String, dynamic>> employeeVerifyOtp(String employeeId, String otp) async {
    final response = await _api.post(ApiConfig.employeeVerifyOtp, {
      'employeeId': employeeId,
      'otp': otp.trim(),
    });

    if (response['success'] == true && response['token'] != null) {
      await _storage.saveToken(response['token']);
      if (response['employee'] != null) {
        await _storage.saveEmployee(response['employee']);
      }
      await _storage.saveLoginType('employee');
    }

    return response;
  }

  /// Resend employee OTP
  Future<Map<String, dynamic>> resendOtp(String employeeId) async {
    return await _api.post(ApiConfig.employeeResendOtp, {
      'employeeId': employeeId,
    });
  }

  /// Verify saved token
  Future<bool> verifyToken() async {
    final token = await _storage.getToken();
    if (token == null) return false;

    try {
      final response = await _api.get(ApiConfig.tenantVerify, token: token);
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _storage.clearAll();
  }
}
