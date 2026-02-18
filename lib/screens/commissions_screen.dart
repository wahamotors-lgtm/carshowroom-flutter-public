import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key});
  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _commissions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getCommissions(_token);
      if (!mounted) return;
      setState(() { _commissions = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = 'فشل تحميل العمولات'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العمولات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.commissionsPage),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : _commissions.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.monetization_on_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد عمولات', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20), itemCount: _commissions.length,
              itemBuilder: (ctx, i) => _buildCard(_commissions[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> commission) {
    final employeeName = commission['employee_name'] ?? commission['employeeName'] ?? commission['salesman'] ?? '';
    final amount = commission['amount'] ?? commission['commission_amount'] ?? 0;
    final currency = commission['currency'] ?? 'USD';
    final carInfo = '${commission['car_make'] ?? commission['make'] ?? ''} ${commission['car_model'] ?? commission['model'] ?? ''}'.trim();
    final date = commission['date'] ?? commission['sale_date'] ?? commission['created_at'] ?? '';
    final status = commission['status'] ?? commission['paid'] == true ? 'paid' : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.monetization_on, color: Color(0xFFD97706), size: 22)),
        title: Text(employeeName.isNotEmpty ? employeeName : 'عمولة', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (carInfo.isNotEmpty) Text(carInfo, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$amount $currency', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          if (status.toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: status == 'paid' ? AppColors.success.withValues(alpha: 0.1) : const Color(0xFFD97706).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(status == 'paid' ? 'مدفوع' : 'معلق', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: status == 'paid' ? AppColors.success : const Color(0xFFD97706))),
            ),
          ],
        ]),
      ),
    );
  }
}
