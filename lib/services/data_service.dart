import '../config/api_config.dart';
import 'api_service.dart';

/// General data service for all CRUD operations
class DataService {
  final ApiService _api;

  DataService(this._api);

  // ── Generic helpers ──

  Future<List<Map<String, dynamic>>> _getList(String url, String token) async {
    final data = await _api.getList(url, token: token);
    return data.cast<Map<String, dynamic>>();
  }

  // ── Cars ──

  Future<List<Map<String, dynamic>>> getCars(String token) =>
      _getList(ApiConfig.cars, token);

  Future<Map<String, dynamic>> createCar(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.cars, body, token: token);

  Future<Map<String, dynamic>> updateCar(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.cars}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteCar(String token, String id) =>
      _api.delete('${ApiConfig.cars}/$id', token: token);

  Future<List<Map<String, dynamic>>> getConsignmentCars(String token) =>
      _getList(ApiConfig.consignmentCars, token);

  Future<Map<String, dynamic>> createConsignmentCar(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.consignmentCars, body, token: token);

  Future<Map<String, dynamic>> updateConsignmentCar(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.consignmentCars}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteConsignmentCar(String token, String id) =>
      _api.delete('${ApiConfig.consignmentCars}/$id', token: token);

  // ── Customers ──

  Future<List<Map<String, dynamic>>> getCustomers(String token) =>
      _getList(ApiConfig.customers, token);

  Future<Map<String, dynamic>> createCustomer(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.customers, body, token: token);

  Future<Map<String, dynamic>> updateCustomer(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.customers}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteCustomer(String token, String id) =>
      _api.delete('${ApiConfig.customers}/$id', token: token);

  // ── Sales ──

  Future<List<Map<String, dynamic>>> getSales(String token) =>
      _getList(ApiConfig.sales, token);

  Future<Map<String, dynamic>> createSale(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.sales, body, token: token);

  Future<Map<String, dynamic>> updateSale(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.sales}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteSale(String token, String id) =>
      _api.delete('${ApiConfig.sales}/$id', token: token);

  Future<List<Map<String, dynamic>>> getCommissions(String token) =>
      _getList(ApiConfig.salesCommissions, token);

  // ── Suppliers ──

  Future<List<Map<String, dynamic>>> getSuppliers(String token) =>
      _getList(ApiConfig.suppliers, token);

  Future<Map<String, dynamic>> createSupplier(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.suppliers, body, token: token);

  Future<Map<String, dynamic>> updateSupplier(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.suppliers}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteSupplier(String token, String id) =>
      _api.delete('${ApiConfig.suppliers}/$id', token: token);

  // ── Employees ──

  Future<List<Map<String, dynamic>>> getEmployees(String token) =>
      _getList(ApiConfig.employees, token);

  Future<Map<String, dynamic>> createEmployee(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.employees, body, token: token);

  Future<Map<String, dynamic>> updateEmployee(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.employees}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteEmployee(String token, String id) =>
      _api.delete('${ApiConfig.employees}/$id', token: token);

  Future<List<Map<String, dynamic>>> getSalaryPayments(String token) =>
      _getList(ApiConfig.salaryPayments, token);

  Future<Map<String, dynamic>> createSalaryPayment(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.salaryPayments, body, token: token);

  // ── Expenses ──

  Future<List<Map<String, dynamic>>> getExpenses(String token) =>
      _getList(ApiConfig.expenses, token);

  Future<Map<String, dynamic>> createExpense(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.expenses, body, token: token);

  Future<Map<String, dynamic>> deleteExpense(String token, String id) =>
      _api.delete('${ApiConfig.expenses}/$id', token: token);

  // ── Shipments & Containers ──

  Future<List<Map<String, dynamic>>> getShipments(String token) =>
      _getList(ApiConfig.shipments, token);

  Future<Map<String, dynamic>> createShipment(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.shipments, body, token: token);

  Future<Map<String, dynamic>> updateShipment(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.shipments}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteShipment(String token, String id) =>
      _api.delete('${ApiConfig.shipments}/$id', token: token);

  Future<List<Map<String, dynamic>>> getContainers(String token) =>
      _getList(ApiConfig.containers, token);

  Future<Map<String, dynamic>> createContainer(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.containers, body, token: token);

  Future<Map<String, dynamic>> updateContainer(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.containers}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteContainer(String token, String id) =>
      _api.delete('${ApiConfig.containers}/$id', token: token);

  Future<List<Map<String, dynamic>>> getDeliveries(String token) =>
      _getList(ApiConfig.deliveries, token);

  Future<Map<String, dynamic>> createDelivery(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.deliveries, body, token: token);

  Future<Map<String, dynamic>> updateDelivery(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.deliveries}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteDelivery(String token, String id) =>
      _api.delete('${ApiConfig.deliveries}/$id', token: token);

  // ── Warehouses ──

  Future<List<Map<String, dynamic>>> getWarehouses(String token) =>
      _getList(ApiConfig.warehouses, token);

  Future<Map<String, dynamic>> createWarehouse(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.warehouses, body, token: token);

  Future<Map<String, dynamic>> updateWarehouse(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.warehouses}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteWarehouse(String token, String id) =>
      _api.delete('${ApiConfig.warehouses}/$id', token: token);

  // ── Rentals & Bills ──

  Future<List<Map<String, dynamic>>> getRentals(String token) =>
      _getList(ApiConfig.rentals, token);

  Future<Map<String, dynamic>> createRental(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.rentals, body, token: token);

  Future<Map<String, dynamic>> updateRental(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.rentals}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteRental(String token, String id) =>
      _api.delete('${ApiConfig.rentals}/$id', token: token);

  Future<List<Map<String, dynamic>>> getMonthlyBills(String token) =>
      _getList(ApiConfig.monthlyBills, token);

  Future<Map<String, dynamic>> createMonthlyBill(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.monthlyBills, body, token: token);

  Future<Map<String, dynamic>> updateMonthlyBill(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.monthlyBills}/$id', body, token: token);

  Future<Map<String, dynamic>> payBill(String token, String id) =>
      _api.post('${ApiConfig.monthlyBills}/$id/pay', {}, token: token);

  Future<Map<String, dynamic>> deleteBill(String token, String id) =>
      _api.delete('${ApiConfig.monthlyBills}/$id', token: token);

  Future<List<Map<String, dynamic>>> getBillTypes(String token) =>
      _getList(ApiConfig.billTypes, token);

  // ── Payments ──

  Future<List<Map<String, dynamic>>> getPayments(String token) =>
      _getList(ApiConfig.payments, token);

  Future<Map<String, dynamic>> createPayment(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.payments, body, token: token);

  // ── Company Settings ──

  Future<Map<String, dynamic>> getCompanySettings(String token) =>
      _api.get(ApiConfig.companySettings, token: token);

  Future<Map<String, dynamic>> updateCompanySettings(String token, Map<String, dynamic> body) =>
      _api.put(ApiConfig.companySettings, body, token: token);

  Future<Map<String, dynamic>> getStoreSettings(String token) =>
      _api.get(ApiConfig.storeSettings, token: token);

  Future<Map<String, dynamic>> updateStoreSettings(String token, Map<String, dynamic> body) =>
      _api.put(ApiConfig.storeSettings, body, token: token);

  // ── Activity Logs ──

  Future<List<Map<String, dynamic>>> getActivityLogs(String token) =>
      _getList(ApiConfig.activityLogs, token);

  // ── Accounts (for dropdowns) ──

  Future<List<Map<String, dynamic>>> getAccounts(String token) =>
      _getList(ApiConfig.accounts, token);

  // ── Notes ──

  Future<List<Map<String, dynamic>>> getNotes(String token) =>
      _getList(ApiConfig.notes, token);

  Future<Map<String, dynamic>> createNote(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.notes, body, token: token);

  Future<Map<String, dynamic>> updateNote(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.notes}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteNote(String token, String id) =>
      _api.delete('${ApiConfig.notes}/$id', token: token);

  // ── Currencies ──

  Future<List<Map<String, dynamic>>> getCurrencies(String token) =>
      _getList(ApiConfig.currencies, token);

  Future<Map<String, dynamic>> createCurrency(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.currencies, body, token: token);

  Future<Map<String, dynamic>> updateCurrency(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.currencies}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteCurrency(String token, String id) =>
      _api.delete('${ApiConfig.currencies}/$id', token: token);

  // ── Exchange Rates ──

  Future<List<Map<String, dynamic>>> getExchangeRateHistory(String token) =>
      _getList(ApiConfig.exchangeRateHistory, token);

  Future<Map<String, dynamic>> createExchangeRate(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.exchangeRateHistory, body, token: token);

  // ── Users ──

  Future<List<Map<String, dynamic>>> getUsers(String token) =>
      _getList(ApiConfig.users, token);

  Future<Map<String, dynamic>> createUser(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.users, body, token: token);

  Future<Map<String, dynamic>> updateUser(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.users}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteUser(String token, String id) =>
      _api.delete('${ApiConfig.users}/$id', token: token);

  // ── Rental Payments ──

  Future<List<Map<String, dynamic>>> getRentalPayments(String token) =>
      _getList(ApiConfig.rentalPayments, token);

  Future<Map<String, dynamic>> createRentalPayment(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.rentalPayments, body, token: token);

  // ── Backup & Restore ──

  Future<Map<String, dynamic>> getBackup(String token) =>
      _api.get(ApiConfig.backupFull, token: token);

  Future<Map<String, dynamic>> restoreBackup(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.restoreFull, body, token: token);

  // ── Dashboard Stats ──

  Future<Map<String, dynamic>> getDashboardStats(String token) =>
      _api.get(ApiConfig.dashboardStats, token: token);

  // ── Smart Search ──

  Future<Map<String, dynamic>> smartSearch(String token, String query) =>
      _api.get('${ApiConfig.smartSearch}?q=$query', token: token);

  // ── Customer Accounts ──

  Future<List<Map<String, dynamic>>> getCustomerAccounts(String token) =>
      _getList(ApiConfig.customerAccounts, token);

  // ── Consignment Sales ──

  Future<List<Map<String, dynamic>>> getConsignmentSales(String token) =>
      _getList(ApiConfig.consignmentSales, token);

  Future<Map<String, dynamic>> createConsignmentSale(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.consignmentSales, body, token: token);

  // ── Sales Commissions ──

  Future<List<Map<String, dynamic>>> getSalesCommissions(String token) =>
      _getList(ApiConfig.salesCommissions, token);

  Future<Map<String, dynamic>> createSalesCommission(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.salesCommissions, body, token: token);

  // ── Payments (update/delete) ──

  Future<Map<String, dynamic>> updatePayment(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.payments}/$id', body, token: token);

  Future<Map<String, dynamic>> deletePayment(String token, String id) =>
      _api.delete('${ApiConfig.payments}/$id', token: token);

  // ── Expenses (update) ──

  Future<Map<String, dynamic>> updateExpense(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.expenses}/$id', body, token: token);

  // ── Salary Payments (update/delete) ──

  Future<Map<String, dynamic>> updateSalaryPayment(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.salaryPayments}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteSalaryPayment(String token, String id) =>
      _api.delete('${ApiConfig.salaryPayments}/$id', token: token);

  // ── Rental Payments (update/delete) ──

  Future<Map<String, dynamic>> updateRentalPayment(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.rentalPayments}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteRentalPayment(String token, String id) =>
      _api.delete('${ApiConfig.rentalPayments}/$id', token: token);

  // ── Exchange Rates (update/delete) ──

  Future<Map<String, dynamic>> updateExchangeRate(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.exchangeRateHistory}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteExchangeRate(String token, String id) =>
      _api.delete('${ApiConfig.exchangeRateHistory}/$id', token: token);

  // ── Sales Commissions (update/delete) ──

  Future<Map<String, dynamic>> updateSalesCommission(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.salesCommissions}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteSalesCommission(String token, String id) =>
      _api.delete('${ApiConfig.salesCommissions}/$id', token: token);

  // ── Air Flights ──

  Future<List<Map<String, dynamic>>> getAirFlights(String token) =>
      _getList(ApiConfig.airFlights, token);

  Future<Map<String, dynamic>> createAirFlight(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.airFlights, body, token: token);

  Future<Map<String, dynamic>> updateAirFlight(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.airFlights}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteAirFlight(String token, String id) =>
      _api.delete('${ApiConfig.airFlights}/$id', token: token);

  // ── Admin Panel ──

  Future<Map<String, dynamic>> adminLogin(String email, String password) =>
      _api.post(ApiConfig.adminLogin, {'email': email, 'password': password});

  Future<Map<String, dynamic>> adminVerify(String token) =>
      _api.get(ApiConfig.adminVerify, token: token);

  Future<List<Map<String, dynamic>>> getAdminTenants(String token) =>
      _getList(ApiConfig.adminTenants, token);

  Future<Map<String, dynamic>> getAdminStats(String token) =>
      _api.get(ApiConfig.adminStats, token: token);

  Future<Map<String, dynamic>> getAdminTenant(String token, String id) =>
      _api.get('${ApiConfig.adminTenants}/$id', token: token);

  Future<Map<String, dynamic>> createAdminTenant(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.adminTenants, body, token: token);

  Future<Map<String, dynamic>> updateAdminTenant(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.adminTenants}/$id', body, token: token);

  Future<Map<String, dynamic>> toggleAdminTenant(String token, String id) =>
      _api.put('${ApiConfig.adminTenants}/$id/toggle', {}, token: token);

  Future<Map<String, dynamic>> deleteAdminTenant(String token, String id) =>
      _api.delete('${ApiConfig.adminTenants}/$id', token: token);

  Future<Map<String, dynamic>> fullEditAdminTenant(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.adminTenants}/$id/full-edit', body, token: token);

  // ── Subscription ──

  Future<Map<String, dynamic>> getSubscriptionStatus(String token) =>
      _api.get(ApiConfig.subscriptionStatus, token: token);

  Future<Map<String, dynamic>> createSubscriptionPayment(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.subscriptionPay, body, token: token);

  Future<Map<String, dynamic>> verifySubscription(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.subscriptionVerify, body, token: token);

  // ── Payment Links (Admin) ──

  Future<Map<String, dynamic>> createPaymentLink(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.paymentCreateLink, body, token: token);

  Future<Map<String, dynamic>> sendPaymentEmail(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.paymentSendEmail, body, token: token);

  // ── Sync ──

  Future<Map<String, dynamic>> syncAllData(String token) =>
      _api.get(ApiConfig.syncAll, token: token);

  Future<Map<String, dynamic>> syncEntity(String token, String entity, Map<String, dynamic> body) =>
      _api.post(ApiConfig.syncEntity(entity), body, token: token);

  Future<Map<String, dynamic>> syncDeleteEntity(String token, String entity, Map<String, dynamic> body) =>
      _api.post(ApiConfig.syncDelete(entity), body, token: token);

  // ── Database Operations ──

  Future<Map<String, dynamic>> databaseBackup(String token) =>
      _api.post(ApiConfig.databaseBackup, {}, token: token);

  Future<Map<String, dynamic>> databaseRestoreSql(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.databaseRestoreSql, body, token: token);

  // ── Car Brands ──

  Future<List<Map<String, dynamic>>> getCarBrands(String token) =>
      _getList(ApiConfig.carBrands, token);

  // ── Health Check ──

  Future<Map<String, dynamic>> healthCheck() =>
      _api.get(ApiConfig.health);

  // ── Employee Activity Logs ──

  Future<List<Map<String, dynamic>>> getEmployeeActivityLogs(String token) =>
      _getList(ApiConfig.employeeActivityLogs, token);

  Future<Map<String, dynamic>> createEmployeeActivityLog(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.employeeActivityLogs, body, token: token);

  // ── Tenant Auth ──

  Future<Map<String, dynamic>> tenantResendCode(Map<String, dynamic> body) =>
      _api.post(ApiConfig.tenantResendCode, body);

  Future<Map<String, dynamic>> tenantVerify(Map<String, dynamic> body) =>
      _api.post(ApiConfig.tenantVerify, body);

  // ── Employee OTP ──

  Future<Map<String, dynamic>> employeeVerifyOtp(Map<String, dynamic> body) =>
      _api.post(ApiConfig.employeeVerifyOtp, body);

  Future<Map<String, dynamic>> employeeResendOtp(Map<String, dynamic> body) =>
      _api.post(ApiConfig.employeeResendOtp, body);

  // ── Account Types ──

  Future<List<Map<String, dynamic>>> getAccountTypes(String token) =>
      _getList(ApiConfig.accountTypes, token);

  // ── Next Entry Number ──

  Future<Map<String, dynamic>> getNextEntryNumber(String token) =>
      _api.get(ApiConfig.nextEntryNumber, token: token);

  // ── Settings ──

  Future<Map<String, dynamic>> getSettings(String token) =>
      _api.get(ApiConfig.settings, token: token);

  Future<Map<String, dynamic>> updateSettings(String token, Map<String, dynamic> body) =>
      _api.put(ApiConfig.settings, body, token: token);

  // ── Admin Notifications ──

  Future<List<Map<String, dynamic>>> getAdminNotifications(String token) =>
      _getList(ApiConfig.adminNotifications, token);

  Future<Map<String, dynamic>> markNotificationRead(String token, String id) =>
      _api.put('${ApiConfig.adminNotifications}/$id/read', {}, token: token);

  // ── Customer Login ──

  Future<Map<String, dynamic>> customerLogin(Map<String, dynamic> body) =>
      _api.post(ApiConfig.customerLogin, body);

  // ── Database Backup History ──

  Future<List<Map<String, dynamic>>> getDatabaseBackupHistory(String token) =>
      _getList(ApiConfig.databaseBackupHistory, token);

  // ── Phone Lines ──

  Future<List<Map<String, dynamic>>> getPhoneLines(String token) =>
      _getList(ApiConfig.phoneLines, token);

  Future<Map<String, dynamic>> createPhoneLine(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.phoneLines, body, token: token);

  Future<Map<String, dynamic>> updatePhoneLine(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.phoneLines}/$id', body, token: token);

  Future<Map<String, dynamic>> deletePhoneLine(String token, String id) =>
      _api.delete('${ApiConfig.phoneLines}/$id', token: token);

  // ── Car Order Requests ──

  Future<List<Map<String, dynamic>>> getCarOrderRequests(String token) =>
      _getList(ApiConfig.carOrderRequests, token);

  Future<Map<String, dynamic>> createCarOrderRequest(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.carOrderRequests, body, token: token);

  Future<Map<String, dynamic>> updateCarOrderRequest(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.carOrderRequests}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteCarOrderRequest(String token, String id) =>
      _api.delete('${ApiConfig.carOrderRequests}/$id', token: token);

  // ── Advertisements ──

  Future<List<Map<String, dynamic>>> getAdvertisements(String token) =>
      _getList(ApiConfig.advertisements, token);

  Future<Map<String, dynamic>> createAdvertisement(String token, Map<String, dynamic> body) =>
      _api.post(ApiConfig.advertisements, body, token: token);

  Future<Map<String, dynamic>> updateAdvertisement(String token, String id, Map<String, dynamic> body) =>
      _api.put('${ApiConfig.advertisements}/$id', body, token: token);

  Future<Map<String, dynamic>> deleteAdvertisement(String token, String id) =>
      _api.delete('${ApiConfig.advertisements}/$id', token: token);

  // ── Auth (alternative) ──

  Future<Map<String, dynamic>> authLogin(Map<String, dynamic> body) =>
      _api.post(ApiConfig.authLogin, body);

  Future<Map<String, dynamic>> authRegister(Map<String, dynamic> body) =>
      _api.post(ApiConfig.authRegister, body);

  Future<Map<String, dynamic>> authVerify(Map<String, dynamic> body) =>
      _api.post(ApiConfig.authVerify, body);

  // ── Container Expenses (filtered) ──

  Future<List<Map<String, dynamic>>> getExpensesByContainer(String token, String containerId) async {
    final all = await getExpenses(token);
    return all.where((e) =>
      (e['container_id']?.toString() ?? e['containerId']?.toString()) == containerId
    ).toList();
  }

  // ── Bulk Expenses ──

  Future<List<Map<String, dynamic>>> createBulkExpenses(String token, List<Map<String, dynamic>> expenses) async {
    final results = <Map<String, dynamic>>[];
    for (final exp in expenses) {
      results.add(await createExpense(token, exp));
    }
    return results;
  }
}
