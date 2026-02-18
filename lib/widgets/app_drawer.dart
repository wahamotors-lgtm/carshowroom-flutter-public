import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tenant = auth.tenant;
    final isEmployee = auth.loginType == 'employee';

    return Drawer(
      backgroundColor: AppColors.slate900,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant?['companyName'] ?? 'كارواتس',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEmployee ? 'موظف' : (tenant?['email'] ?? ''),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSection('الرئيسية'),
                  _buildItem(context, 'لوحة التحكم', Icons.dashboard_outlined, AppRoutes.dashboard),

                  _buildSection('المخزون والمستودعات'),
                  _buildItem(context, 'السيارات', Icons.directions_car_outlined, AppRoutes.cars),
                  _buildItem(context, 'سيارات الأمانة', Icons.car_rental_outlined, AppRoutes.consignmentCarsPage),
                  _buildItem(context, 'المستودعات', Icons.warehouse_outlined, AppRoutes.warehousesPage),
                  _buildItem(context, 'تسعير السيارات', Icons.price_change_outlined, AppRoutes.carPricing),

                  _buildSection('المبيعات والعملاء'),
                  _buildItem(context, 'المبيعات', Icons.point_of_sale_outlined, AppRoutes.salesPage),
                  _buildItem(context, 'معالج البيع', Icons.shopping_cart_checkout_outlined, AppRoutes.sellCarWizard),
                  _buildItem(context, 'العمولات', Icons.monetization_on_outlined, AppRoutes.commissionsPage),
                  _buildItem(context, 'العملاء', Icons.people_outline, AppRoutes.customersPage),
                  _buildItem(context, 'حسابات العملاء', Icons.account_balance_wallet_outlined, AppRoutes.customerAccountsPage),

                  _buildSection('المشتريات والشحن'),
                  _buildItem(context, 'الموردين', Icons.local_shipping_outlined, AppRoutes.suppliersPage),
                  _buildItem(context, 'الحاويات', Icons.inventory_2_outlined, AppRoutes.containersPage),
                  _buildItem(context, 'مصاريف الحاويات', Icons.receipt_outlined, AppRoutes.containerExpenses),
                  _buildItem(context, 'الشحنات', Icons.local_shipping, AppRoutes.shipmentsPage),
                  _buildItem(context, 'التسليمات', Icons.delivery_dining_outlined, AppRoutes.deliveriesPage),
                  _buildItem(context, 'الرحلات الجوية', Icons.flight_outlined, AppRoutes.airFlightsPage),

                  _buildSection('المالية والمحاسبة'),
                  _buildItem(context, 'الحسابات', Icons.account_balance_outlined, AppRoutes.accounts),
                  _buildItem(context, 'قيود محاسبية', Icons.receipt_long_outlined, AppRoutes.journalEntries),
                  _buildItem(context, 'تسجيل مصروف', Icons.add_card_outlined, AppRoutes.expenseRecord),
                  _buildItem(context, 'مصروف جماعي', Icons.playlist_add_outlined, AppRoutes.bulkExpense),
                  _buildItem(context, 'قيد متقدم', Icons.library_books_outlined, AppRoutes.advancedEntry),
                  _buildItem(context, 'المدفوعات', Icons.payment_outlined, AppRoutes.paymentsPage),
                  _buildItem(context, 'العملات', Icons.currency_exchange_outlined, AppRoutes.currenciesPage),
                  _buildItem(context, 'أسعار الصرف', Icons.trending_up_outlined, AppRoutes.exchangeRatesPage),
                  _buildItem(context, 'ميزان المراجعة', Icons.balance_outlined, AppRoutes.trialBalance),
                  _buildItem(context, 'مصاريف يتيمة', Icons.warning_amber_outlined, AppRoutes.orphanedExpenses),

                  _buildSection('التقارير'),
                  _buildItem(context, 'التقارير', Icons.assessment_outlined, AppRoutes.reportsPage),
                  _buildItem(context, 'الأرباح والخسائر', Icons.show_chart_outlined, AppRoutes.profitsPage),
                  _buildItem(context, 'الكشوف والجرود', Icons.summarize_outlined, AppRoutes.statementsPage),
                  _buildItem(context, 'أبحاث السوق', Icons.analytics_outlined, AppRoutes.marketResearch),

                  _buildSection('الموارد البشرية'),
                  _buildItem(context, 'الموظفين', Icons.badge_outlined, AppRoutes.employeesPage),
                  _buildItem(context, 'مدفوعات الرواتب', Icons.payments_outlined, AppRoutes.salaryPaymentsPage),
                  _buildItem(context, 'الإيجارات', Icons.home_outlined, AppRoutes.rentalsPage),
                  _buildItem(context, 'مدفوعات الإيجار', Icons.real_estate_agent_outlined, AppRoutes.rentalPaymentsPage),
                  _buildItem(context, 'الفواتير الشهرية', Icons.receipt_outlined, AppRoutes.billsPage),

                  _buildSection('بوابات الوصول'),
                  _buildItem(context, 'المعرض العام', Icons.storefront_outlined, AppRoutes.publicShowroom),
                  _buildItem(context, 'بوابة العملاء', Icons.person_pin_outlined, AppRoutes.customerLogin),

                  _buildSection('الإعدادات والنظام'),
                  _buildItem(context, 'معلومات الشركة', Icons.business_outlined, AppRoutes.companySettingsPage),
                  _buildItem(context, 'إعدادات المتجر', Icons.store_outlined, AppRoutes.storeSettingsPage),
                  _buildItem(context, 'المستخدمين', Icons.group_outlined, AppRoutes.usersPage),
                  _buildItem(context, 'سجل النشاط', Icons.history_outlined, AppRoutes.activityLogPage),
                  _buildItem(context, 'الملاحظات', Icons.note_outlined, AppRoutes.notesPage),
                  _buildItem(context, 'النسخ الاحتياطي', Icons.backup_outlined, AppRoutes.backupRestorePage),
                  _buildItem(context, 'ترحيل البيانات', Icons.import_export_outlined, AppRoutes.dataMigration),
                  _buildItem(context, 'حذف البيانات', Icons.delete_sweep_outlined, AppRoutes.dataDeletion),
                  _buildItem(context, 'تشخيص النظام', Icons.health_and_safety_outlined, AppRoutes.systemDiagnostics),
                  _buildItem(context, 'الاشتراك', Icons.card_membership_outlined, AppRoutes.subscriptionPage),
                  _buildItem(context, 'ماسح الباركود', Icons.qr_code_scanner_outlined, AppRoutes.barcodeScanner),
                  _buildItem(context, 'البحث الذكي', Icons.search_outlined, AppRoutes.smartSearchPage),
                  _buildItem(context, 'تجريبي', Icons.science_outlined, AppRoutes.demoPage),
                  _buildItem(context, 'الإعدادات', Icons.settings_outlined, AppRoutes.settingsPage),
                  _buildItem(context, 'سياسة الخصوصية', Icons.privacy_tip_outlined, AppRoutes.privacyPolicy),
                  _buildItem(context, 'شروط الاستخدام', Icons.gavel_outlined, AppRoutes.termsOfService),
                ],
              ),
            ),

            // Logout
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 22),
                title: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w600),
                ),
                onTap: () => _handleLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, IconData icon, String route) {
    final isSelected = currentRoute == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.6),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // close drawer
          if (currentRoute != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'هل تريد تسجيل الخروج من التطبيق؟',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لا', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, AppRoutes.tenantLogin);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('نعم، خروج', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
