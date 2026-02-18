import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'authToken';
  static const String _userKey = 'currentUser';
  static const String _tenantKey = 'tenantInfo';
  static const String _employeeKey = 'loggedInEmployee';
  static const String _loginTypeKey = 'loginType';
  static const String _adminTokenKey = 'adminToken';
  static const String _adminKey = 'adminInfo';
  static const String _customerTokenKey = 'customerToken';
  static const String _customerKey = 'customerInfo';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Token
  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  // User
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await _prefs;
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _prefs;
    final data = prefs.getString(_userKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Tenant
  Future<void> saveTenant(Map<String, dynamic> tenant) async {
    final prefs = await _prefs;
    await prefs.setString(_tenantKey, jsonEncode(tenant));
  }

  Future<Map<String, dynamic>?> getTenant() async {
    final prefs = await _prefs;
    final data = prefs.getString(_tenantKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  String? getTenantSync(SharedPreferences prefs) {
    return prefs.getString(_tenantKey);
  }

  // Employee
  Future<void> saveEmployee(Map<String, dynamic> employee) async {
    final prefs = await _prefs;
    await prefs.setString(_employeeKey, jsonEncode(employee));
  }

  Future<Map<String, dynamic>?> getEmployee() async {
    final prefs = await _prefs;
    final data = prefs.getString(_employeeKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Login type
  Future<void> saveLoginType(String type) async {
    final prefs = await _prefs;
    await prefs.setString(_loginTypeKey, type);
  }

  Future<String?> getLoginType() async {
    final prefs = await _prefs;
    return prefs.getString(_loginTypeKey);
  }

  // Admin token & info
  Future<void> saveAdminToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_adminTokenKey, token);
  }

  Future<String?> getAdminToken() async {
    final prefs = await _prefs;
    return prefs.getString(_adminTokenKey);
  }

  Future<void> saveAdmin(Map<String, dynamic> admin) async {
    final prefs = await _prefs;
    await prefs.setString(_adminKey, jsonEncode(admin));
  }

  Future<Map<String, dynamic>?> getAdmin() async {
    final prefs = await _prefs;
    final data = prefs.getString(_adminKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Customer token & info
  Future<void> saveCustomerToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_customerTokenKey, token);
  }

  Future<String?> getCustomerToken() async {
    final prefs = await _prefs;
    return prefs.getString(_customerTokenKey);
  }

  Future<void> saveCustomer(Map<String, dynamic> customer) async {
    final prefs = await _prefs;
    await prefs.setString(_customerKey, jsonEncode(customer));
  }

  Future<Map<String, dynamic>?> getCustomer() async {
    final prefs = await _prefs;
    final data = prefs.getString(_customerKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Clear all
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_tenantKey);
    await prefs.remove(_employeeKey);
    await prefs.remove(_loginTypeKey);
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_adminKey);
    await prefs.remove(_customerTokenKey);
    await prefs.remove(_customerKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
