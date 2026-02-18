import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  // ══════════════════════════════════════════════════════════════════════
  //  بيانات تجريبية محلية
  // ══════════════════════════════════════════════════════════════════════

  final List<Map<String, dynamic>> _mockCars = [
    {'make': 'هيونداي', 'model': 'سوناتا', 'year': 2024, 'price': 25000, 'status': 'في المعرض', 'color': 'أبيض'},
    {'make': 'كيا', 'model': 'سبورتاج', 'year': 2023, 'price': 28000, 'status': 'في الطريق', 'color': 'أسود'},
    {'make': 'تويوتا', 'model': 'كامري', 'year': 2024, 'price': 32000, 'status': 'في المعرض', 'color': 'فضي'},
    {'make': 'شيفروليه', 'model': 'ماليبو', 'year': 2023, 'price': 22000, 'status': 'مباعة', 'color': 'رمادي'},
    {'make': 'نيسان', 'model': 'ألتيما', 'year': 2024, 'price': 27000, 'status': 'في الجمارك', 'color': 'أزرق'},
  ];

  final List<Map<String, dynamic>> _mockExpenses = [
    {'description': 'شحن حاوية رقم 45', 'amount': 3500, 'category': 'شحن', 'date': '2024-12-01'},
    {'description': 'رسوم جمركية - سوناتا', 'amount': 1200, 'category': 'جمارك', 'date': '2024-12-03'},
    {'description': 'صيانة مكيف - كامري', 'amount': 450, 'category': 'صيانة', 'date': '2024-12-05'},
    {'description': 'إيجار المعرض - ديسمبر', 'amount': 5000, 'category': 'إيجار', 'date': '2024-12-01'},
    {'description': 'تأمين سيارات المعرض', 'amount': 2800, 'category': 'تأمين', 'date': '2024-12-10'},
  ];

  final List<Map<String, dynamic>> _mockAccounts = [
    {'name': 'الصندوق الرئيسي', 'type': 'نقدي', 'balance': 125000, 'currency': 'USD'},
    {'name': 'حساب البنك الأهلي', 'type': 'بنكي', 'balance': 340000, 'currency': 'USD'},
    {'name': 'حساب الموردين', 'type': 'دائن', 'balance': -45000, 'currency': 'USD'},
    {'name': 'ذمم العملاء', 'type': 'مدين', 'balance': 67000, 'currency': 'USD'},
    {'name': 'صندوق المصاريف', 'type': 'نقدي', 'balance': 15000, 'currency': 'USD'},
  ];

  final List<Map<String, dynamic>> _mockSales = [
    {'car': 'هيونداي سوناتا 2024', 'customer': 'أحمد محمد', 'amount': 28000, 'date': '2024-12-15'},
    {'car': 'كيا سبورتاج 2023', 'customer': 'خالد عبدالله', 'amount': 31000, 'date': '2024-12-12'},
    {'car': 'تويوتا كامري 2024', 'customer': 'محمد علي', 'amount': 35000, 'date': '2024-12-10'},
    {'car': 'شيفروليه ماليبو 2023', 'customer': 'سعد ناصر', 'amount': 25000, 'date': '2024-12-08'},
    {'car': 'نيسان ألتيما 2024', 'customer': 'عمر حسن', 'amount': 30000, 'date': '2024-12-05'},
  ];

  final List<Map<String, dynamic>> _mockEmployees = [
    {'name': 'يوسف أحمد', 'role': 'مدير المبيعات', 'salary': 8000, 'status': 'نشط'},
    {'name': 'فاطمة خالد', 'role': 'محاسبة', 'salary': 6500, 'status': 'نشط'},
    {'name': 'عبدالرحمن سعيد', 'role': 'مندوب مبيعات', 'salary': 5000, 'status': 'نشط'},
    {'name': 'نورة محمد', 'role': 'سكرتيرة', 'salary': 4500, 'status': 'نشط'},
    {'name': 'حسن عمر', 'role': 'فني صيانة', 'salary': 5500, 'status': 'إجازة'},
  ];

  final Map<String, dynamic> _mockReports = {
    'totalCars': 47,
    'carsInShowroom': 12,
    'carsInTransit': 8,
    'carsSold': 27,
    'totalSales': 149000,
    'totalExpenses': 12950,
    'totalProfit': 42300,
    'employeesCount': 5,
    'customersCount': 23,
    'avgSalePrice': 29800,
  };

  // ══════════════════════════════════════════════════════════════════════
  //  تعريف الأقسام
  // ══════════════════════════════════════════════════════════════════════

  List<_DemoSection> get _sections => [
    _DemoSection(
      title: 'السيارات',
      icon: Icons.directions_car,
      color: const Color(0xFF2563EB),
      onTap: () => _showSectionSheet('السيارات', _buildCarsContent()),
    ),
    _DemoSection(
      title: 'المصاريف',
      icon: Icons.receipt_long,
      color: const Color(0xFFF59E0B),
      onTap: () => _showSectionSheet('المصاريف', _buildExpensesContent()),
    ),
    _DemoSection(
      title: 'الحسابات',
      icon: Icons.account_balance,
      color: const Color(0xFF22C55E),
      onTap: () => _showSectionSheet('الحسابات', _buildAccountsContent()),
    ),
    _DemoSection(
      title: 'المبيعات',
      icon: Icons.point_of_sale,
      color: const Color(0xFF8B5CF6),
      onTap: () => _showSectionSheet('المبيعات', _buildSalesContent()),
    ),
    _DemoSection(
      title: 'الموظفين',
      icon: Icons.badge,
      color: const Color(0xFF14B8A6),
      onTap: () => _showSectionSheet('الموظفين', _buildEmployeesContent()),
    ),
    _DemoSection(
      title: 'التقارير',
      icon: Icons.assessment,
      color: const Color(0xFFEF4444),
      onTap: () => _showSectionSheet('التقارير', _buildReportsContent()),
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════
  //  البناء الرئيسي
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الوضع التجريبي',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.demoPage),
      body: Column(
        children: [
          // ── شريط التحذير ──
          _buildWarningBanner(),
          // ── المحتوى ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGrid(),
                  const SizedBox(height: 24),
                  _buildBottomActions(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  شريط التحذير العلوي
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFFFEF3C7),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'هذا وضع تجريبي - البيانات ليست حقيقية',
              style: TextStyle(
                color: const Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  شبكة الأقسام
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildGrid() {
    final sections = _sections;
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: sections.map((s) => _buildSectionCard(s)).toList(),
    );
  }

  Widget _buildSectionCard(_DemoSection section) {
    return GestureDetector(
      onTap: section.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: section.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(section.icon, color: section.color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  أزرار الأسفل
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildBottomActions() {
    return Column(
      children: [
        // زر إعادة تعيين البيانات
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إعادة تعيين البيانات التجريبية'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تعيين البيانات', style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textGray,
              side: const BorderSide(color: AppColors.textMuted),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // زر بدء الاستخدام الفعلي
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.tenantLogin);
            },
            icon: const Icon(Icons.login),
            label: const Text('بدء الاستخدام الفعلي', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  صفحة القسم المنبثقة (Bottom Sheet)
  // ══════════════════════════════════════════════════════════════════════

  void _showSectionSheet(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // مقبض السحب
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // عنوان القسم
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    // زر إضافة تجريبي
                    TextButton.icon(
                      onPressed: () => _showDemoSnackBar(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // قائمة العناصر
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDemoSnackBar() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('هذا وضع تجريبي - لا يمكن إضافة بيانات حقيقية'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  بطاقة عنصر موحدة
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildItemCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailing,
    Color? trailingColor,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                ),
              ],
            ),
          ),
          if (trailing != null || badge != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (trailing != null)
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: trailingColor ?? AppColors.textDark,
                    ),
                  ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor ?? AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  بطاقة إحصائية
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  محتوى قسم السيارات
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildCarsContent() {
    return Column(
      children: _mockCars.map((car) {
        final statusColor = car['status'] == 'مباعة'
            ? AppColors.error
            : car['status'] == 'في المعرض'
                ? AppColors.success
                : const Color(0xFFF59E0B);
        return _buildItemCard(
          icon: Icons.directions_car,
          iconColor: const Color(0xFF2563EB),
          title: '${car['make']} ${car['model']}',
          subtitle: '${car['year']} - ${car['color']}',
          trailing: '\$${_formatNumber(car['price'])}',
          trailingColor: AppColors.primary,
          badge: car['status'],
          badgeColor: statusColor,
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  محتوى قسم المصاريف
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildExpensesContent() {
    return Column(
      children: _mockExpenses.map((exp) {
        return _buildItemCard(
          icon: Icons.receipt_long,
          iconColor: const Color(0xFFF59E0B),
          title: exp['description'],
          subtitle: '${exp['category']} - ${exp['date']}',
          trailing: '\$${_formatNumber(exp['amount'])}',
          trailingColor: AppColors.error,
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  محتوى قسم الحسابات
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildAccountsContent() {
    return Column(
      children: _mockAccounts.map((acc) {
        final balance = acc['balance'] as int;
        final balanceColor = balance >= 0 ? AppColors.success : AppColors.error;
        return _buildItemCard(
          icon: Icons.account_balance,
          iconColor: const Color(0xFF22C55E),
          title: acc['name'],
          subtitle: '${acc['type']} - ${acc['currency']}',
          trailing: '\$${_formatNumber(balance.abs())}',
          trailingColor: balanceColor,
          badge: acc['type'],
          badgeColor: const Color(0xFF22C55E),
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  محتوى قسم المبيعات
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSalesContent() {
    return Column(
      children: _mockSales.map((sale) {
        return _buildItemCard(
          icon: Icons.point_of_sale,
          iconColor: const Color(0xFF8B5CF6),
          title: sale['car'],
          subtitle: '${sale['customer']} - ${sale['date']}',
          trailing: '\$${_formatNumber(sale['amount'])}',
          trailingColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  محتوى قسم الموظفين
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildEmployeesContent() {
    return Column(
      children: _mockEmployees.map((emp) {
        final statusColor = emp['status'] == 'نشط' ? AppColors.success : const Color(0xFFF59E0B);
        return _buildItemCard(
          icon: Icons.badge,
          iconColor: const Color(0xFF14B8A6),
          title: emp['name'],
          subtitle: emp['role'],
          trailing: '\$${_formatNumber(emp['salary'])}',
          trailingColor: AppColors.textDark,
          badge: emp['status'],
          badgeColor: statusColor,
        );
      }).toList(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  محتوى قسم التقارير
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildReportsContent() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'إجمالي السيارات',
              '${_mockReports['totalCars']}',
              Icons.directions_car,
              const Color(0xFF2563EB),
            ),
            _buildStatCard(
              'في المعرض',
              '${_mockReports['carsInShowroom']}',
              Icons.store,
              AppColors.success,
            ),
            _buildStatCard(
              'في الطريق',
              '${_mockReports['carsInTransit']}',
              Icons.local_shipping,
              const Color(0xFFF59E0B),
            ),
            _buildStatCard(
              'مباعة',
              '${_mockReports['carsSold']}',
              Icons.sell,
              AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildItemCard(
          icon: Icons.attach_money,
          iconColor: AppColors.primary,
          title: 'إجمالي المبيعات',
          subtitle: 'مجموع كل عمليات البيع',
          trailing: '\$${_formatNumber(_mockReports['totalSales'])}',
          trailingColor: AppColors.primary,
        ),
        _buildItemCard(
          icon: Icons.receipt_long,
          iconColor: const Color(0xFFF59E0B),
          title: 'إجمالي المصاريف',
          subtitle: 'مجموع كل المصاريف',
          trailing: '\$${_formatNumber(_mockReports['totalExpenses'])}',
          trailingColor: AppColors.error,
        ),
        _buildItemCard(
          icon: Icons.trending_up,
          iconColor: AppColors.success,
          title: 'صافي الأرباح',
          subtitle: 'الأرباح بعد خصم المصاريف',
          trailing: '\$${_formatNumber(_mockReports['totalProfit'])}',
          trailingColor: AppColors.success,
        ),
        _buildItemCard(
          icon: Icons.people,
          iconColor: const Color(0xFF14B8A6),
          title: 'عدد الموظفين',
          subtitle: 'الموظفين النشطين',
          trailing: '${_mockReports['employeesCount']}',
        ),
        _buildItemCard(
          icon: Icons.person,
          iconColor: const Color(0xFF8B5CF6),
          title: 'عدد العملاء',
          subtitle: 'إجمالي العملاء المسجلين',
          trailing: '${_mockReports['customersCount']}',
        ),
        _buildItemCard(
          icon: Icons.price_check,
          iconColor: AppColors.blue600,
          title: 'متوسط سعر البيع',
          subtitle: 'معدل أسعار البيع',
          trailing: '\$${_formatNumber(_mockReports['avgSalePrice'])}',
          trailingColor: AppColors.blue600,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  أدوات مساعدة
  // ══════════════════════════════════════════════════════════════════════

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final num n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    if (n >= 1000) {
      return n.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return n.toStringAsFixed(0);
  }
}

// ══════════════════════════════════════════════════════════════════════
//  نموذج بيانات القسم
// ══════════════════════════════════════════════════════════════════════

class _DemoSection {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DemoSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
