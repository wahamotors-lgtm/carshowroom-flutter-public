import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/routes.dart';
import 'screens/splash_screen.dart';
import 'screens/tenant_login_screen.dart';
import 'screens/tenant_register_screen.dart';
import 'screens/activation_screen.dart';
import 'screens/employee_login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/accounts_screen.dart';
import 'screens/journal_entries_screen.dart';
import 'screens/expense_record_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/cars_screen.dart';
import 'screens/consignment_cars_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/commissions_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/customer_accounts_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/warehouses_screen.dart';
import 'screens/containers_screen.dart';
import 'screens/shipments_screen.dart';
import 'screens/deliveries_screen.dart';
import 'screens/air_flights_screen.dart';
import 'screens/employees_screen.dart';
import 'screens/salary_payments_screen.dart';
import 'screens/rentals_screen.dart';
import 'screens/bills_screen.dart';
import 'screens/company_settings_screen.dart';
import 'screens/store_settings_screen.dart';
import 'screens/activity_log_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/currencies_screen.dart';
import 'screens/exchange_rates_screen.dart';
import 'screens/trial_balance_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profits_screen.dart';
import 'screens/smart_search_screen.dart';
import 'screens/rental_payments_screen.dart';
import 'screens/users_screen.dart';
import 'screens/backup_restore_screen.dart';
import 'screens/customer_login_screen.dart';
import 'screens/super_admin_login_screen.dart';
import 'screens/customer_dashboard_screen.dart';
import 'screens/employee_dashboard_screen.dart';
import 'screens/super_admin_dashboard_screen.dart';
import 'screens/car_pricing_screen.dart';
import 'screens/car_photos_screen.dart';
import 'screens/sell_car_wizard_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/orphaned_expenses_screen.dart';
import 'screens/data_migration_screen.dart';
import 'screens/data_deletion_screen.dart';
import 'screens/system_diagnostics_screen.dart';
import 'screens/public_showroom_screen.dart';
import 'screens/market_research_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_of_service_screen.dart';
import 'screens/qr_login_screen.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/container_expenses_screen.dart';
import 'screens/bulk_expense_screen.dart';
import 'screens/advanced_entry_screen.dart';
import 'screens/statements_screen.dart';
import 'screens/demo_screen.dart';

class CarWhatsApp extends StatelessWidget {
  const CarWhatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كارواتس',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      locale: const Locale('ar'),
      theme: ThemeData(
        textTheme: GoogleFonts.tajawalTextTheme(),
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF059669),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        // Auth
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.tenantLogin: (_) => const TenantLoginScreen(),
        AppRoutes.tenantRegister: (_) => const TenantRegisterScreen(),
        AppRoutes.activation: (_) => const ActivationScreen(),
        AppRoutes.employeeLogin: (_) => const EmployeeLoginScreen(),

        // Dashboard
        AppRoutes.dashboard: (_) => const DashboardScreen(),

        // Finance & Accounting
        AppRoutes.accounts: (_) => const AccountsScreen(),
        AppRoutes.journalEntries: (_) => const JournalEntriesScreen(),
        AppRoutes.expenseRecord: (_) => const ExpenseRecordScreen(),
        AppRoutes.bulkExpense: (_) => const BulkExpenseScreen(),
        AppRoutes.advancedEntry: (_) => const AdvancedEntryScreen(),
        AppRoutes.paymentsPage: (_) => const PaymentsScreen(),

        // Inventory
        AppRoutes.cars: (_) => const CarsScreen(),
        AppRoutes.consignmentCarsPage: (_) => const ConsignmentCarsScreen(),
        AppRoutes.warehousesPage: (_) => const WarehousesScreen(),

        // Sales & Customers
        AppRoutes.salesPage: (_) => const SalesScreen(),
        AppRoutes.commissionsPage: (_) => const CommissionsScreen(),
        AppRoutes.customersPage: (_) => const CustomersScreen(),
        AppRoutes.customerAccountsPage: (_) => const CustomerAccountsScreen(),

        // Procurement & Shipping
        AppRoutes.suppliersPage: (_) => const SuppliersScreen(),
        AppRoutes.containersPage: (_) => const ContainersScreen(),
        AppRoutes.containerExpenses: (_) => const ContainerExpensesScreen(),
        AppRoutes.shipmentsPage: (_) => const ShipmentsScreen(),
        AppRoutes.deliveriesPage: (_) => const DeliveriesScreen(),
        AppRoutes.airFlightsPage: (_) => const AirFlightsScreen(),

        // HR
        AppRoutes.employeesPage: (_) => const EmployeesScreen(),
        AppRoutes.salaryPaymentsPage: (_) => const SalaryPaymentsScreen(),
        AppRoutes.rentalsPage: (_) => const RentalsScreen(),
        AppRoutes.billsPage: (_) => const BillsScreen(),

        // Finance (continued)
        AppRoutes.currenciesPage: (_) => const CurrenciesScreen(),
        AppRoutes.exchangeRatesPage: (_) => const ExchangeRatesScreen(),
        AppRoutes.trialBalance: (_) => const TrialBalanceScreen(),

        // Reports
        AppRoutes.reportsPage: (_) => const ReportsScreen(),
        AppRoutes.profitsPage: (_) => const ProfitsScreen(),
        AppRoutes.statementsPage: (_) => const StatementsScreen(),

        // Smart Search
        AppRoutes.smartSearchPage: (_) => const SmartSearchScreen(),

        // Rental Payments
        AppRoutes.rentalPaymentsPage: (_) => const RentalPaymentsScreen(),

        // Users
        AppRoutes.usersPage: (_) => const UsersScreen(),

        // Backup & Restore
        AppRoutes.backupRestorePage: (_) => const BackupRestoreScreen(),

        // Settings & System
        AppRoutes.companySettingsPage: (_) => const CompanySettingsScreen(),
        AppRoutes.storeSettingsPage: (_) => const StoreSettingsScreen(),
        AppRoutes.activityLogPage: (_) => const ActivityLogScreen(),
        AppRoutes.notesPage: (_) => const NotesScreen(),
        AppRoutes.settingsPage: (_) => const SettingsScreen(),

        // Customer Portal
        AppRoutes.customerLogin: (_) => const CustomerLoginScreen(),
        AppRoutes.customerDashboard: (_) => const CustomerDashboardScreen(),

        // Employee Portal
        AppRoutes.employeeDashboard: (_) => const EmployeeDashboardScreen(),

        // Admin Panel
        AppRoutes.superAdminLogin: (_) => const SuperAdminLoginScreen(),
        AppRoutes.superAdminDashboard: (_) => const SuperAdminDashboardScreen(),

        // Vehicle Management
        AppRoutes.carPricing: (_) => const CarPricingScreen(),
        AppRoutes.carPhotos: (_) => const CarPhotosScreen(),
        AppRoutes.sellCarWizard: (_) => const SellCarWizardScreen(),

        // Financial
        AppRoutes.subscriptionPage: (_) => const SubscriptionScreen(),
        AppRoutes.orphanedExpenses: (_) => const OrphanedExpensesScreen(),

        // Data Management
        AppRoutes.dataMigration: (_) => const DataMigrationScreen(),
        AppRoutes.dataDeletion: (_) => const DataDeletionScreen(),
        AppRoutes.systemDiagnostics: (_) => const SystemDiagnosticsScreen(),

        // Marketing
        AppRoutes.publicShowroom: (_) => const PublicShowroomScreen(),
        AppRoutes.marketResearch: (_) => const MarketResearchScreen(),

        // Information
        AppRoutes.privacyPolicy: (_) => const PrivacyPolicyScreen(),
        AppRoutes.termsOfService: (_) => const TermsOfServiceScreen(),

        // Utilities
        AppRoutes.qrLogin: (_) => const QrLoginScreen(),
        AppRoutes.barcodeScanner: (_) => const BarcodeScannerScreen(),

        // Demo
        AppRoutes.demoPage: (_) => const DemoScreen(),

        // Landing
        AppRoutes.landingPage: (_) => const LandingScreen(),
      },
    );
  }
}
