class ApiConfig {
  static const String baseUrl = 'https://carwhats.group';
  static const String apiBase = '$baseUrl/api';

  // Tenant auth
  static const String tenantLogin = '$apiBase/tenant/login';
  static const String tenantRegister = '$apiBase/tenant/register';
  static const String tenantActivate = '$apiBase/tenant/activate';
  static const String tenantResendCode = '$apiBase/tenant/resend-code';
  static const String tenantVerify = '$apiBase/tenant/verify';

  // Employee auth
  static const String tenantEmployeeLogin = '$apiBase/tenant-employee/login';
  static const String employeeVerifyOtp = '$apiBase/employee/verify-otp';
  static const String employeeResendOtp = '$apiBase/employee/resend-otp';

  // WebView
  static const String webAppUrl = '$baseUrl/app/';
  static const String webAppDashboard = '$baseUrl/app/#/dashboard';
  static const String webAppEmployeeDashboard = '$baseUrl/app/#/employee-dashboard';
}
