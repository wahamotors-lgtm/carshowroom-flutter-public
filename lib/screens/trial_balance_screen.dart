import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      final accounts = await _ds.getAccounts(_token);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'فشل تحميل ميزان المراجعة';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_accounts);
    } else {
      _filtered = _accounts.where((a) {
        final name = (a['name'] ?? '').toString().toLowerCase();
        final nameAr = (a['name_ar'] ?? '').toString().toLowerCase();
        final code = (a['code'] ?? '').toString().toLowerCase();
        final type = (a['type'] ?? '').toString().toLowerCase();
        return name.contains(q) ||
            nameAr.contains(q) ||
            code.contains(q) ||
            type.contains(q);
      }).toList();
    }
  }

  bool _isDebitAccount(String type) {
    const debitTypes = [
      'assets',
      'expenses',
      'expense',
      'cash_box',
      'bank',
      'showroom',
      'customs',
      'purchases',
      'employee',
    ];
    return debitTypes.contains(type.toLowerCase());
  }

  double _getDebit(Map<String, dynamic> account) {
    final balance = (account['balance'] ?? 0).toDouble();
    final type = (account['type'] ?? '').toString();
    if (_isDebitAccount(type)) {
      return balance >= 0 ? balance : 0;
    } else {
      return balance < 0 ? balance.abs() : 0;
    }
  }

  double _getCredit(Map<String, dynamic> account) {
    final balance = (account['balance'] ?? 0).toDouble();
    final type = (account['type'] ?? '').toString();
    if (_isDebitAccount(type)) {
      return balance < 0 ? balance.abs() : 0;
    } else {
      return balance >= 0 ? balance : 0;
    }
  }

  double get _totalDebits {
    double total = 0;
    for (final a in _filtered) {
      total += _getDebit(a);
    }
    return total;
  }

  double get _totalCredits {
    double total = 0;
    for (final a in _filtered) {
      total += _getCredit(a);
    }
    return total;
  }

  double _sumByTypes(List<String> types) {
    double total = 0;
    for (final a in _accounts) {
      final type = (a['type'] ?? '').toString().toLowerCase();
      if (types.contains(type)) {
        total += (a['balance'] ?? 0).toDouble();
      }
    }
    return total;
  }

  double get _totalAssets =>
      _sumByTypes(['assets', 'cash_box', 'bank', 'showroom', 'customs']);

  double get _totalLiabilities =>
      _sumByTypes(['liabilities', 'supplier', 'shipping_company']);

  double get _totalEquity => _sumByTypes(['equity', 'capital']);

  double get _totalRevenue => _sumByTypes(['revenue']);

  double get _totalExpenses =>
      _sumByTypes(['expenses', 'expense', 'purchases', 'employee']);

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

  String _typeLabel(String type) {
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
    return labels[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ميزان المراجعة',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('سيتم إضافة خاصية الطباعة قريباً'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.trialBalance),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _applyFilter()),
              decoration: InputDecoration(
                hintText: 'بحث عن حساب...',
                hintStyle:
                    const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textMuted, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _applyFilter());
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgLight,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Account count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Text(
              '${_filtered.length} حساب',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _accounts.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadData,
                            child: ListView(
                              padding: const EdgeInsets.only(bottom: 24),
                              children: [
                                _buildSummaryCard(),
                                _buildTableHeader(),
                                ..._filtered
                                    .map((a) => _buildAccountRow(a)),
                                if (_filtered.isNotEmpty) _buildTotalsRow(),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(_error!,
              style:
                  const TextStyle(color: AppColors.textGray, fontSize: 14)),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_outlined,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text('لا توجد حسابات',
              style: TextStyle(color: AppColors.textGray, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('قم بإضافة حسابات لعرض ميزان المراجعة',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
                  label: 'الأصول',
                  value: _formatNumber(_totalAssets),
                  color: const Color(0xFF2563EB),
                  icon: Icons.account_balance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: 'الالتزامات',
                  value: _formatNumber(_totalLiabilities),
                  color: const Color(0xFFD97706),
                  icon: Icons.credit_card,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'حقوق الملكية',
                  value: _formatNumber(_totalEquity),
                  color: const Color(0xFF7C3AED),
                  icon: Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: 'الإيرادات',
                  value: _formatNumber(_totalRevenue),
                  color: AppColors.success,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'المصروفات',
                  value: _formatNumber(_totalExpenses),
                  color: AppColors.error,
                  icon: Icons.trending_down,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryItem(
                  label: 'الفرق',
                  value: _formatNumber(_totalDebits - _totalCredits),
                  color: (_totalDebits - _totalCredits).abs() < 0.01
                      ? AppColors.success
                      : AppColors.error,
                  icon: Icons.balance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'اسم الحساب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'مدين',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'دائن',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow(Map<String, dynamic> account) {
    final name = account['name_ar'] ?? account['name'] ?? '';
    final type = (account['type'] ?? '').toString();
    final debit = _getDebit(account);
    final credit = _getCredit(account);
    final code = account['code'] ?? '';
    final isActive = account['is_active'] ?? true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isActive == false
            ? Colors.grey.shade50
            : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => _showAccountDetail(account),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.toString(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive == false
                            ? AppColors.textMuted
                            : AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (code.toString().isNotEmpty) ...[
                          Text(
                            code.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _isDebitAccount(type)
                                ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                                : const Color(0xFFD97706).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _typeLabel(type),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _isDebitAccount(type)
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  debit > 0 ? _formatNumber(debit) : '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: debit > 0 ? FontWeight.w700 : FontWeight.w400,
                    color: debit > 0
                        ? AppColors.textDark
                        : AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  credit > 0 ? _formatNumber(credit) : '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: credit > 0 ? FontWeight.w700 : FontWeight.w400,
                    color: credit > 0
                        ? AppColors.textDark
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalsRow() {
    final isBalanced = (_totalDebits - _totalCredits).abs() < 0.01;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isBalanced
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          top: BorderSide(
            color: isBalanced ? AppColors.success : AppColors.error,
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Icon(
                      isBalanced ? Icons.check_circle : Icons.warning_amber,
                      size: 16,
                      color: isBalanced ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'الإجمالي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color:
                            isBalanced ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatNumber(_totalDebits),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatNumber(_totalCredits),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          if (!isBalanced) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'الفرق: ${_formatNumber((_totalDebits - _totalCredits).abs())} - الميزان غير متوازن',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          if (isBalanced) ...[
            const SizedBox(height: 6),
            const Text(
              'الميزان متوازن',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAccountDetail(Map<String, dynamic> account) {
    final name = account['name_ar'] ?? account['name'] ?? '';
    final nameEn = account['name'] ?? '';
    final type = (account['type'] ?? '').toString();
    final balance = (account['balance'] ?? 0).toDouble();
    final code = account['code'] ?? '';
    final currency = account['currency'] ?? '';
    final description = account['description'] ?? '';
    final debit = _getDebit(account);
    final credit = _getCredit(account);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  name.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                if (nameEn.toString().isNotEmpty &&
                    nameEn.toString() != name.toString()) ...[
                  const SizedBox(height: 4),
                  Text(
                    nameEn.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typeLabel(type),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _DetailInfoCard(
                        label: 'مدين',
                        value: _formatNumber(debit),
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DetailInfoCard(
                        label: 'دائن',
                        value: _formatNumber(credit),
                        color: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DetailInfoCard(
                        label: 'الرصيد',
                        value: _formatNumber(balance),
                        color:
                            balance >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (code.toString().isNotEmpty)
                  _detailRow('الكود', code.toString()),
                if (currency.toString().isNotEmpty)
                  _detailRow('العملة', currency.toString()),
                _detailRow('الطبيعة',
                    _isDebitAccount(type) ? 'مدين' : 'دائن'),
                if (description.toString().isNotEmpty)
                  _detailRow('الوصف', description.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _DetailInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailInfoCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
