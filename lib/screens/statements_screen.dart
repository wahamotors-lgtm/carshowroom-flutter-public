import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class StatementsScreen extends StatefulWidget {
  const StatementsScreen({super.key});

  @override
  State<StatementsScreen> createState() => _StatementsScreenState();
}

class _StatementsScreenState extends State<StatementsScreen>
    with SingleTickerProviderStateMixin {
  late final DataService _ds;
  late final TabController _tabController;

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _ds.getAccounts(_token),
        _ds.getExpenses(_token),
        _ds.getCars(_token),
        _ds.getSales(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _accounts = results[0];
        _expenses = results[1];
        _cars = results[2];
        _sales = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'فشل تحميل البيانات';
        _isLoading = false;
      });
    }
  }

  // ── Number formatting ──

  String _formatNumber(double value) {
    if (value == 0) return '0.00';
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      buffer.write(intPart[i]);
      count++;
      if (count % 3 == 0 && i > 0) buffer.write(',');
    }
    return '$sign${buffer.toString().split('').reversed.join()}.$decPart';
  }

  double _parseDouble(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  // ── Account helpers ──

  String _accountTypeLabel(String type) {
    const labels = {
      'cash_box': 'صندوق نقدي',
      'bank': 'بنك',
      'customer': 'عميل',
      'supplier': 'مورد',
      'revenue': 'إيراد',
      'expense': 'مصروف',
      'expenses': 'مصروفات',
      'showroom': 'معرض',
      'customs': 'جمارك',
      'employee': 'موظف',
      'purchases': 'مشتريات',
      'capital': 'رأس مال',
      'shipping_company': 'شركة شحن',
      'assets': 'أصول',
      'liabilities': 'التزامات',
      'equity': 'حقوق ملكية',
      'other': 'أخرى',
    };
    return labels[type.toLowerCase()] ?? type;
  }

  bool _isAssetType(String type) {
    const assetTypes = [
      'assets',
      'cash_box',
      'bank',
      'showroom',
      'customs',
      'purchases',
      'employee',
      'expenses',
      'expense',
    ];
    return assetTypes.contains(type.toLowerCase());
  }

  double _sumAccountsByTypes(List<String> types) {
    double total = 0;
    for (final a in _accounts) {
      final type = (a['type'] ?? '').toString().toLowerCase();
      if (types.contains(type)) {
        total += _parseDouble(a['balance']);
      }
    }
    return total;
  }

  double get _totalAssets =>
      _sumAccountsByTypes(['assets', 'cash_box', 'bank', 'showroom', 'customs']);

  double get _totalLiabilities =>
      _sumAccountsByTypes(['liabilities', 'supplier', 'shipping_company']);

  double get _netBalance => _totalAssets - _totalLiabilities.abs();

  // ── Expense helpers ──

  String _expenseCategoryLabel(String category) {
    const labels = {
      'shipping': 'شحن',
      'customs': 'جمارك',
      'transport': 'نقل',
      'loading': 'تحميل',
      'clearance': 'تخليص',
      'port_fees': 'رسوم ميناء',
      'government': 'رسوم حكومية',
      'car_expense': 'مصاريف سيارة',
      'other': 'أخرى',
    };
    return labels[category.toLowerCase()] ?? category;
  }

  IconData _expenseCategoryIcon(String category) {
    const icons = {
      'shipping': Icons.local_shipping_outlined,
      'customs': Icons.gavel_outlined,
      'transport': Icons.directions_car_outlined,
      'loading': Icons.upload_outlined,
      'clearance': Icons.assignment_turned_in_outlined,
      'port_fees': Icons.anchor_outlined,
      'government': Icons.account_balance_outlined,
      'car_expense': Icons.build_outlined,
      'other': Icons.more_horiz_outlined,
    };
    return icons[category.toLowerCase()] ?? Icons.receipt_long_outlined;
  }

  Color _expenseCategoryColor(String category) {
    const colors = {
      'shipping': Color(0xFF2563EB),
      'customs': Color(0xFFD97706),
      'transport': Color(0xFF7C3AED),
      'loading': Color(0xFF0891B2),
      'clearance': Color(0xFF059669),
      'port_fees': Color(0xFF0284C7),
      'government': Color(0xFFDC2626),
      'car_expense': Color(0xFFEA580C),
      'other': Color(0xFF64748B),
    };
    return colors[category.toLowerCase()] ?? const Color(0xFF64748B);
  }

  Map<String, List<Map<String, dynamic>>> get _expensesByCategory {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in _expenses) {
      final cat = (e['category'] ?? e['type'] ?? 'other').toString().toLowerCase();
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add(e);
    }
    return grouped;
  }

  double get _totalExpensesAmount {
    double total = 0;
    for (final e in _expenses) {
      total += _parseDouble(e['amount']);
    }
    return total;
  }

  // ── Inventory helpers ──

  String _carStatusLabel(String status) {
    const labels = {
      'in_korea': 'في كوريا',
      'in_transit': 'قيد الشحن',
      'in_showroom': 'في المعرض',
      'sold': 'مباعة',
      'available': 'في المعرض',
      'shipped': 'قيد الشحن',
      'reserved': 'محجوزة',
    };
    return labels[status.toLowerCase()] ?? status;
  }

  IconData _carStatusIcon(String status) {
    const icons = {
      'in_korea': Icons.flag_outlined,
      'in_transit': Icons.directions_boat_outlined,
      'in_showroom': Icons.storefront_outlined,
      'sold': Icons.sell_outlined,
      'available': Icons.storefront_outlined,
      'shipped': Icons.directions_boat_outlined,
      'reserved': Icons.bookmark_outlined,
    };
    return icons[status.toLowerCase()] ?? Icons.directions_car_outlined;
  }

  Color _carStatusColor(String status) {
    const colors = {
      'in_korea': Color(0xFF2563EB),
      'in_transit': Color(0xFFD97706),
      'in_showroom': Color(0xFF059669),
      'sold': Color(0xFF7C3AED),
      'available': Color(0xFF059669),
      'shipped': Color(0xFFD97706),
      'reserved': Color(0xFF0891B2),
    };
    return colors[status.toLowerCase()] ?? const Color(0xFF64748B);
  }

  Map<String, List<Map<String, dynamic>>> get _carsByStatus {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final c in _cars) {
      final status = (c['status'] ?? 'other').toString().toLowerCase();
      grouped.putIfAbsent(status, () => []);
      grouped[status]!.add(c);
    }
    return grouped;
  }

  double _carValue(Map<String, dynamic> car) {
    return _parseDouble(car['purchase_price'] ??
        car['purchasePrice'] ??
        car['price'] ??
        car['cost'] ??
        0);
  }

  double get _totalInventoryValue {
    double total = 0;
    for (final c in _cars) {
      final status = (c['status'] ?? '').toString().toLowerCase();
      if (status != 'sold') {
        total += _carValue(c);
      }
    }
    return total;
  }

  int get _totalCarsCount => _cars.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        return status != 'sold';
      }).length;

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الكشوف والجرود',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'كشف الحسابات'),
            Tab(text: 'ملخص المصاريف'),
            Tab(text: 'جرد المخزون'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.statementsPage),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAccountsTab(),
                    _buildExpensesTab(),
                    _buildInventoryTab(),
                  ],
                ),
    );
  }

  // ── Error / Empty states ──

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(color: AppColors.textGray, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: AppColors.textGray, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Tab 1: كشف الحسابات (Account Statement)
  // ══════════════════════════════════════════════

  Widget _buildAccountsTab() {
    if (_accounts.isEmpty) {
      return _buildEmptyState(
        Icons.account_balance_outlined,
        'لا توجد حسابات',
        'قم بإضافة حسابات لعرض كشف الحسابات',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildAccountsSummary(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.list_alt_outlined,
                    size: 18, color: AppColors.textGray),
                const SizedBox(width: 6),
                Text(
                  'جميع الحسابات (${_accounts.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._accounts.map((a) => _buildAccountCard(a)),
        ],
      ),
    );
  }

  Widget _buildAccountsSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'ملخص الأرصدة',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'إجمالي الأصول',
                  value: _formatNumber(_totalAssets),
                  color: AppColors.blue600,
                  icon: Icons.account_balance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: 'إجمالي الالتزامات',
                  value: _formatNumber(_totalLiabilities.abs()),
                  color: const Color(0xFFD97706),
                  icon: Icons.credit_card,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SummaryItem(
            label: 'صافي الأرصدة',
            value: _formatNumber(_netBalance),
            color: _netBalance >= 0 ? AppColors.success : AppColors.error,
            icon: Icons.balance,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final name = (account['name_ar'] ?? account['name'] ?? '').toString();
    final type = (account['type'] ?? '').toString();
    final balance = _parseDouble(account['balance']);
    final currency = (account['currency'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (_isAssetType(type)
                        ? AppColors.blue600
                        : const Color(0xFFD97706))
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isAssetType(type)
                    ? Icons.account_balance_outlined
                    : Icons.credit_card_outlined,
                color: _isAssetType(type)
                    ? AppColors.blue600
                    : const Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _accountTypeLabel(type),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (currency.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          currency,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(balance.abs()),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: balance >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balance >= 0 ? 'رصيد دائن' : 'رصيد مدين',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: balance >= 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Tab 2: ملخص المصاريف (Expense Summary)
  // ══════════════════════════════════════════════

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return _buildEmptyState(
        Icons.receipt_long_outlined,
        'لا توجد مصاريف',
        'لم يتم تسجيل أي مصاريف بعد',
      );
    }

    final grouped = _expensesByCategory;
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final totalA =
            grouped[a]!.fold<double>(0, (s, e) => s + _parseDouble(e['amount']));
        final totalB =
            grouped[b]!.fold<double>(0, (s, e) => s + _parseDouble(e['amount']));
        return totalB.compareTo(totalA);
      });

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildExpensesSummary(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 18, color: AppColors.textGray),
                const SizedBox(width: 6),
                Text(
                  'التصنيفات (${sortedKeys.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...sortedKeys.map((cat) => _buildExpenseCategoryCard(
                cat,
                grouped[cat]!,
              )),
        ],
      ),
    );
  }

  Widget _buildExpensesSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'إجمالي المصاريف',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'إجمالي المصاريف',
                  value: _formatNumber(_totalExpensesAmount),
                  color: AppColors.error,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: 'عدد العمليات',
                  value: '${_expenses.length}',
                  color: AppColors.blue600,
                  icon: Icons.format_list_numbered,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoryCard(
      String category, List<Map<String, dynamic>> items) {
    final total =
        items.fold<double>(0, (sum, e) => sum + _parseDouble(e['amount']));
    final color = _expenseCategoryColor(category);
    final icon = _expenseCategoryIcon(category);
    final label = _expenseCategoryLabel(category);
    final percentage = _totalExpensesAmount > 0
        ? (total / _totalExpensesAmount * 100)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${items.length} عملية',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatNumber(total),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Tab 3: جرد المخزون (Inventory)
  // ══════════════════════════════════════════════

  Widget _buildInventoryTab() {
    if (_cars.isEmpty) {
      return _buildEmptyState(
        Icons.directions_car_outlined,
        'لا توجد سيارات',
        'لم يتم إضافة أي سيارات بعد',
      );
    }

    final grouped = _carsByStatus;
    final statusOrder = [
      'in_korea',
      'in_transit',
      'shipped',
      'in_showroom',
      'available',
      'reserved',
      'sold',
    ];
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ia = statusOrder.indexOf(a);
        final ib = statusOrder.indexOf(b);
        final oa = ia >= 0 ? ia : statusOrder.length;
        final ob = ib >= 0 ? ib : statusOrder.length;
        return oa.compareTo(ob);
      });

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _buildInventorySummary(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 18, color: AppColors.textGray),
                const SizedBox(width: 6),
                Text(
                  'حسب الحالة (${sortedKeys.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...sortedKeys.map((status) => _buildInventoryStatusCard(
                status,
                grouped[status]!,
              )),
        ],
      ),
    );
  }

  Widget _buildInventorySummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'ملخص المخزون',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'إجمالي السيارات',
                  value: '$_totalCarsCount',
                  color: AppColors.blue600,
                  icon: Icons.directions_car,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: 'قيمة المخزون',
                  value: _formatNumber(_totalInventoryValue),
                  color: AppColors.primary,
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'المباعة',
                  value:
                      '${_cars.where((c) => (c['status'] ?? '').toString().toLowerCase() == 'sold').length}',
                  color: const Color(0xFF7C3AED),
                  icon: Icons.sell_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: 'إجمالي المبيعات',
                  value: _formatNumber(_sales.fold<double>(
                    0,
                    (sum, s) => sum + _parseDouble(
                        s['sale_price'] ??
                            s['salePrice'] ??
                            s['selling_price'] ??
                            s['sellingPrice'] ??
                            s['amount'] ??
                            s['total'] ??
                            0),
                  )),
                  color: AppColors.success,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatusCard(
      String status, List<Map<String, dynamic>> cars) {
    final color = _carStatusColor(status);
    final icon = _carStatusIcon(status);
    final label = _carStatusLabel(status);
    final isSold = status.toLowerCase() == 'sold';
    final totalValue =
        cars.fold<double>(0, (sum, c) => sum + _carValue(c));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${cars.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${isSold ? 'قيمة المبيعات' : 'القيمة'}: ${_formatNumber(totalValue)}',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            const Divider(height: 1),
            ...cars.map((car) => _buildCarListItem(car, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCarListItem(Map<String, dynamic> car, Color statusColor) {
    final make = (car['make'] ?? car['car_make'] ?? '').toString();
    final model = (car['model'] ?? car['car_model'] ?? '').toString();
    final year = (car['year'] ?? car['car_year'] ?? '').toString();
    final value = _carValue(car);
    final vin = (car['vin'] ?? car['chassis'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_car_outlined,
                size: 16, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$make $model${year.isNotEmpty ? ' ($year)' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (vin.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    vin,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Summary Item Widget ──

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
