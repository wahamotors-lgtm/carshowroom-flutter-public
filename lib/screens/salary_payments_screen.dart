import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class SalaryPaymentsScreen extends StatefulWidget {
  const SalaryPaymentsScreen({super.key});
  @override
  State<SalaryPaymentsScreen> createState() => _SalaryPaymentsScreenState();
}

class _SalaryPaymentsScreenState extends State<SalaryPaymentsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getSalaryPayments(_token);
      if (!mounted) return;
      setState(() { _payments = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل مدفوعات الرواتب'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدفوعات الرواتب', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.salaryPaymentsPage),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : _payments.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.payments_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد مدفوعات رواتب', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20), itemCount: _payments.length,
              itemBuilder: (ctx, i) => _buildCard(_payments[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> payment) {
    final employeeName = payment['employee_name'] ?? payment['employeeName'] ?? '';
    final amount = payment['amount'] ?? payment['salary'] ?? 0;
    final currency = payment['currency'] ?? 'USD';
    final date = payment['date'] ?? payment['payment_date'] ?? payment['created_at'] ?? '';
    final month = payment['month'] ?? payment['period'] ?? '';
    final status = payment['status'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.payments, color: Color(0xFF2563EB), size: 22)),
        title: Text(employeeName.isNotEmpty ? employeeName : 'دفعة راتب', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (month.toString().isNotEmpty) Text('الفترة: $month', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$amount $currency', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          if (status.toString().isNotEmpty) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: status.toString().toLowerCase() == 'paid' ? AppColors.success.withValues(alpha: 0.1) : const Color(0xFFD97706).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(status.toString().toLowerCase() == 'paid' ? 'مدفوع' : status.toString(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: status.toString().toLowerCase() == 'paid' ? AppColors.success : const Color(0xFFD97706))),
          ),
        ]),
      ),
    );
  }
}
