import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});
  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  late final ApiService _api;
  late final StorageService _storage;
  bool _isLoading = true;
  String? _error;

  // Customer info
  String _customerName = '';
  String _customerCode = '';

  // Data
  List<Map<String, dynamic>> _cars = [];
  double _balance = 0;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _storage = StorageService();
    _loadAll();
  }

  Future<String> get _token async {
    return await _storage.getCustomerToken() ?? '';
  }

  String _fmtCur(double v) => '\$${NumberFormat('#,###.##', 'en_US').format(v.abs())}';

  double _pd(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Load customer info
      final customer = await _storage.getCustomer();
      if (customer != null) {
        _customerName = customer['name'] ?? customer['customer_name'] ?? '';
        _customerCode = customer['customer_code'] ?? customer['code'] ?? '';
      }

      final token = await _token;

      // Load customer data
      final results = await Future.wait([
        _api.get(ApiConfig.customerCars, token: token).catchError((_) => <String, dynamic>{}),
        _api.get(ApiConfig.customerBalance, token: token).catchError((_) => <String, dynamic>{}),
        _api.get(ApiConfig.customerTransactions, token: token).catchError((_) => <String, dynamic>{}),
      ]);

      if (!mounted) return;

      // Parse cars
      final carsRaw = results[0];
      if (carsRaw is Map && carsRaw['data'] is List) {
        _cars = (carsRaw['data'] as List).cast<Map<String, dynamic>>();
      } else if (carsRaw is Map && carsRaw['cars'] is List) {
        _cars = (carsRaw['cars'] as List).cast<Map<String, dynamic>>();
      }

      // Parse balance
      final balanceRaw = results[1];
      if (balanceRaw is Map) {
        _balance = _pd(balanceRaw['balance'] ?? balanceRaw['total'] ?? 0);
      }

      // Parse transactions
      final txRaw = results[2];
      if (txRaw is Map && txRaw['data'] is List) {
        _transactions = (txRaw['data'] as List).cast<Map<String, dynamic>>();
      } else if (txRaw is Map && txRaw['transactions'] is List) {
        _transactions = (txRaw['transactions'] as List).cast<Map<String, dynamic>>();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تسجيل الخروج', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('هل تريد تسجيل الخروج؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لا', style: TextStyle(fontSize: 15))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _storage.clearAll();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.customerLogin);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('نعم، خروج', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة العميل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.logout, size: 22), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAll,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 14),
                      _buildBalanceCard(),
                      const SizedBox(height: 14),
                      _buildCarsSection(),
                      const SizedBox(height: 14),
                      _buildTransactionsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.person, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مرحباً، $_customerName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('رمز العميل: $_customerCode', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildBalanceCard() {
    final isPositive = _balance >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: (isPositive ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.account_balance_wallet, color: isPositive ? AppColors.success : AppColors.error, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('رصيد الحساب', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textGray)),
          const SizedBox(height: 4),
          Text(
            _fmtCur(_balance),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isPositive ? AppColors.success : AppColors.error),
          ),
        ])),
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? AppColors.success : AppColors.error,
          size: 28,
        ),
      ]),
    );
  }

  Widget _buildCarsSection() {
    return _cardWrapper(
      icon: Icons.directions_car,
      iconColor: const Color(0xFF3B82F6),
      title: 'سياراتي (${_cars.length})',
      child: _cars.isEmpty
          ? _emptyState(Icons.directions_car_outlined, 'لا توجد سيارات مسجلة')
          : Column(children: _cars.take(10).map((car) {
              final brand = car['brand'] ?? car['make'] ?? '';
              final model = car['model'] ?? '';
              final vin = car['vin'] ?? '';
              final status = car['status'] ?? '';
              final year = car['year'] ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.directions_car, color: Color(0xFF3B82F6), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$brand $model${year.toString().isNotEmpty ? ' ($year)' : ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    if (vin.toString().isNotEmpty) Text('VIN: $vin', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ])),
                  if (status.toString().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _statusColor(status.toString()).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(_statusLabel(status.toString()), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status.toString()))),
                    ),
                ]),
              );
            }).toList()),
    );
  }

  Widget _buildTransactionsSection() {
    return _cardWrapper(
      icon: Icons.receipt_long,
      iconColor: const Color(0xFF8B5CF6),
      title: 'آخر المعاملات',
      child: _transactions.isEmpty
          ? _emptyState(Icons.receipt_long_outlined, 'لا توجد معاملات')
          : Column(children: _transactions.take(10).map((tx) {
              final desc = tx['description'] ?? tx['details'] ?? tx['type'] ?? '';
              final amount = _pd(tx['amount'] ?? tx['total'] ?? 0);
              final date = tx['created_at'] ?? tx['date'] ?? '';
              final isCredit = (tx['type'] ?? '').toString().toLowerCase() == 'credit' || amount > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: (isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCredit ? AppColors.success : AppColors.error,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(desc.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ])),
                  Text(
                    '${isCredit ? '+' : '-'}${_fmtCur(amount)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isCredit ? AppColors.success : AppColors.error),
                  ),
                ]),
              );
            }).toList()),
    );
  }

  // ── Helpers ──

  Widget _cardWrapper({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _emptyState(IconData icon, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(icon, size: 36, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(msg, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_korea_warehouse': return const Color(0xFF3B82F6);
      case 'in_container': case 'shipped': return const Color(0xFFF59E0B);
      case 'arrived': case 'customs': return const Color(0xFF06B6D4);
      case 'in_showroom': case 'in_stock': return const Color(0xFF10B981);
      case 'sold': return const Color(0xFF6B7280);
      default: return AppColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_korea_warehouse': return 'في كوريا';
      case 'in_container': return 'في الحاوية';
      case 'shipped': return 'في الطريق';
      case 'arrived': return 'وصلت';
      case 'customs': return 'جمارك';
      case 'in_showroom': case 'in_stock': return 'في المعرض';
      case 'sold': return 'مباعة';
      default: return status;
    }
  }
}
