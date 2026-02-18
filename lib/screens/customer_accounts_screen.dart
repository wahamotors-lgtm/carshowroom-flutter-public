import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../widgets/app_drawer.dart';

class CustomerAccountsScreen extends StatefulWidget {
  const CustomerAccountsScreen({super.key});
  @override
  State<CustomerAccountsScreen> createState() => _CustomerAccountsScreenState();
}

class _CustomerAccountsScreenState extends State<CustomerAccountsScreen> {
  late final ApiService _api;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _api = ApiService(); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.getList(ApiConfig.customerAccounts, token: _token);
      if (!mounted) return;
      setState(() { _accounts = data.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = 'فشل تحميل حسابات العملاء'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابات العملاء', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.customerAccountsPage),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : _accounts.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد حسابات عملاء', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20), itemCount: _accounts.length,
              itemBuilder: (ctx, i) => _buildCard(_accounts[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> account) {
    final name = account['customer_name'] ?? account['customerName'] ?? account['name'] ?? '';
    final balance = account['balance'] ?? 0;
    final currency = account['currency'] ?? 'USD';
    final code = account['code'] ?? account['customer_code'] ?? '';
    final isDebt = (balance is num) && balance < 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF0891B2).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.account_balance_wallet, color: Color(0xFF0891B2), size: 22)),
        title: Text(name.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: code.toString().isNotEmpty ? Text('كود: $code', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
        trailing: Text('$balance $currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDebt ? AppColors.error : AppColors.success)),
        onTap: () => _showDetails(account),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> account) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(account['customer_name'] ?? account['customerName'] ?? account['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _row('الكود', '${account['code'] ?? account['customer_code'] ?? '-'}'),
            _row('الرصيد', '${account['balance'] ?? 0} ${account['currency'] ?? 'USD'}'),
            _row('إجمالي المشتريات', '${account['total_purchases'] ?? account['totalPurchases'] ?? '-'}'),
            _row('إجمالي المدفوعات', '${account['total_payments'] ?? account['totalPayments'] ?? '-'}'),
            _row('ملاحظات', '${account['notes'] ?? '-'}'),
          ]),
        )),
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value == '-' || value == 'null') return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }
}
