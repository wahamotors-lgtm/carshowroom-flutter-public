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

  // Accounts
  static const String accounts = '$apiBase/accounts';
  static const String accountTypes = '$apiBase/account-types';

  // Journal entries
  static const String journalEntries = '$apiBase/journal-entries';
  static const String nextEntryNumber = '$apiBase/next-entry-number';

  // Expenses
  static const String expenses = '$apiBase/expenses';

  // Cars
  static const String cars = '$apiBase/cars';
  static const String consignmentCars = '$apiBase/consignment-cars';

  // Customers
  static const String customers = '$apiBase/customers';
  static const String customerAccounts = '$apiBase/customer-accounts';

  // Sales
  static const String sales = '$apiBase/sales';
  static const String consignmentSales = '$apiBase/consignment-sales';
  static const String salesCommissions = '$apiBase/sales-commissions';

  // Suppliers
  static const String suppliers = '$apiBase/suppliers';

  // Shipments & Containers
  static const String shipments = '$apiBase/shipments';
  static const String containers = '$apiBase/containers';
  static const String deliveries = '$apiBase/deliveries';
  static const String airFlights = '$apiBase/air-flights';

  // Warehouses
  static const String warehouses = '$apiBase/warehouses';

  // Employees
  static const String employees = '$apiBase/employees';
  static const String salaryPayments = '$apiBase/salary-payments';

  // Rentals & Bills
  static const String rentals = '$apiBase/rentals';
  static const String rentalPayments = '$apiBase/rental-payments';
  static const String billTypes = '$apiBase/bill-types';
  static const String monthlyBills = '$apiBase/monthly-bills';

  // Payments
  static const String payments = '$apiBase/payments';

  // Settings
  static const String settings = '$apiBase/settings';
  static const String companySettings = '$apiBase/company-settings';
  static const String storeSettings = '$apiBase/store-settings';

  // Activity & Notifications
  static const String activityLogs = '$apiBase/activity-logs';
  static const String adminNotifications = '$apiBase/admin-notifications';

  // Notes
  static const String notes = '$apiBase/notes';

  // Smart Search
  static const String smartSearch = '$apiBase/smart-search';

  // Currencies & Exchange Rates
  static const String currencies = '$apiBase/currencies';
  static const String exchangeRateHistory = '$apiBase/exchange-rate-history';

  // Users
  static const String users = '$apiBase/users';

  // Backup & Restore
  static const String backupFull = '$apiBase/backup/full';
  static const String restoreFull = '$apiBase/restore/full';

  // Dashboard Stats
  static const String dashboardStats = '$apiBase/dashboard/stats';

  // Car Brands
  static const String carBrands = '$apiBase/car-brands';

  // Employee Activity Logs
  static const String employeeActivityLogs = '$apiBase/employee-activity-logs';

  // WebView (legacy)
  static const String webAppUrl = '$baseUrl/app/';
  static const String webAppDashboard = '$baseUrl/app/#/dashboard';
  static const String webAppEmployeeDashboard = '$baseUrl/app/#/employee-dashboard';
}
