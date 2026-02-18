import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ProfitsScreen extends StatefulWidget {
  const ProfitsScreen({super.key});
  @override
  State<ProfitsScreen> createState() => _ProfitsScreenState();
}

class _ProfitsScreenState extends State<ProfitsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadData();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _ds.getSales(_token),
        _ds.getExpenses(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _sales = results[0];
        _expenses = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  double _parseSaleAmount(Map<String, dynamic> sale) {
    final raw = sale['sale_price'] ?? sale['salePrice'] ?? sale['selling_price'] ?? sale['sellingPrice'] ?? sale['amount'] ?? sale['total'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  double _parseExpenseAmount(Map<String, dynamic> expense) {
    final raw = expense['amount'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  double get _totalRevenue => _sales.fold(0.0, (sum, s) => sum + _parseSaleAmount(s));

  double get _totalExpenses => _expenses.fold(0.0, (sum, e) => sum + _parseExpenseAmount(e));

  double get _netProfit => _totalRevenue - _totalExpenses;

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  List<Map<String, dynamic>> get _recentTransactions {
    final List<Map<String, dynamic>> all = [];
    for (final s in _sales) {
      all.add({
        'type': 'sale',
        'amount': _parseSaleAmount(s),
        'currency': s['currency'] ?? 'USD',
        'description': s['customer_name'] ?? s['customerName'] ?? s['buyer_name'] ?? 'بيع',
        'subtext': '${s['car_make'] ?? s['make'] ?? ''} ${s['car_model'] ?? s['model'] ?? ''}'.trim(),
        'date': s['date'] ?? s['sale_date'] ?? s['created_at'] ?? '',
      });
    }
    for (final e in _expenses) {
      all.add({
        'type': 'expense',
        'amount': _parseExpenseAmount(e),
        'currency': e['currency'] ?? 'USD',
        'description': e['description'] ?? e['category'] ?? 'مصروف',
        'subtext': e['category'] ?? '',
        'date': e['date'] ?? e['created_at'] ?? '',
      });
    }
    all.sort((a, b) {
      final da = a['date']?.toString() ?? '';
      final db = b['date']?.toString() ?? '';
      return db.compareTo(da);
    });
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرباح والخسائر', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.profitsPage),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      const Text('آخر العمليات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      const SizedBox(height: 12),
                      ..._buildTransactionsList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final profit = _netProfit;
    final isProfit = profit >= 0;

    return Column(
      children: [
        _buildSummaryCard(
          icon: Icons.trending_up,
          label: 'إجمالي المبيعات',
          value: _formatNumber(_totalRevenue),
          color: AppColors.success,
          count: '${_sales.length} عملية بيع',
        ),
        const SizedBox(height: 10),
        _buildSummaryCard(
          icon: Icons.trending_down,
          label: 'إجمالي المصروفات',
          value: _formatNumber(_totalExpenses),
          color: AppColors.error,
          count: '${_expenses.length} مصروف',
        ),
        const SizedBox(height: 10),
        _buildSummaryCard(
          icon: isProfit ? Icons.emoji_events : Icons.warning_amber,
          label: 'صافي الربح',
          value: '${isProfit ? '+' : ''}${_formatNumber(profit)}',
          color: isProfit ? AppColors.primary : AppColors.error,
          count: isProfit ? 'ربح' : 'خسارة',
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String count,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(count, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionsList() {
    final transactions = _recentTransactions;
    if (transactions.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('لا توجد عمليات', style: TextStyle(color: AppColors.textGray)),
              ],
            ),
          ),
        ),
      ];
    }
    return transactions.map((t) => _buildTransactionCard(t)).toList();
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isSale = transaction['type'] == 'sale';
    final amount = transaction['amount'] as double;
    final currency = transaction['currency'] ?? 'USD';
    final description = transaction['description']?.toString() ?? '';
    final subtext = transaction['subtext']?.toString() ?? '';
    final date = transaction['date']?.toString() ?? '';
    final color = isSale ? AppColors.success : AppColors.error;
    final icon = isSale ? Icons.arrow_downward : Icons.arrow_upward;
    final prefix = isSale ? '+' : '-';
    final typeLabel = isSale ? 'بيع' : 'مصروف';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          description.isNotEmpty ? description : typeLabel,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (subtext.isNotEmpty)
                    Text(subtext, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (date.isNotEmpty)
                    Text(date.split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$prefix${_formatNumber(amount)} $currency',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
