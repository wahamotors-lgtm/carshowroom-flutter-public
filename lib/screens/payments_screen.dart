import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
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
      final data = await _ds.getPayments(_token);
      if (!mounted) return;
      setState(() { _payments = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل المدفوعات'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المدفوعات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.paymentsPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : _payments.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.payment_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد مدفوعات', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), itemCount: _payments.length,
              itemBuilder: (ctx, i) => _buildCard(_payments[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> payment) {
    final description = payment['description'] ?? payment['reference'] ?? '';
    final amount = payment['amount'] ?? 0;
    final currency = payment['currency'] ?? 'USD';
    final date = payment['date'] ?? payment['payment_date'] ?? payment['created_at'] ?? '';
    final type = payment['type'] ?? payment['payment_type'] ?? '';
    final method = payment['method'] ?? payment['payment_method'] ?? '';

    Color typeColor;
    String typeLabel;
    switch (type.toString().toLowerCase()) {
      case 'income': case 'received': case 'in': typeColor = AppColors.success; typeLabel = 'وارد'; break;
      case 'expense': case 'paid': case 'out': typeColor = AppColors.error; typeLabel = 'صادر'; break;
      default: typeColor = AppColors.primary; typeLabel = type.toString().isNotEmpty ? type.toString() : 'دفعة';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(type.toString().toLowerCase().contains('in') || type.toString().toLowerCase().contains('income') || type.toString().toLowerCase().contains('received')
            ? Icons.arrow_downward : Icons.arrow_upward, color: typeColor, size: 22)),
        title: Text(description.isNotEmpty ? description : typeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (method.toString().isNotEmpty) Text(method.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$amount $currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: typeColor)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: typeColor)),
          ),
        ]),
      ),
    );
  }

  void _showAddDialog() {
    final descC = TextEditingController();
    final amountC = TextEditingController();
    String currency = 'USD';
    String type = 'out';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة دفعة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(descC, 'الوصف / المرجع', Icons.description_outlined),
        _input(amountC, 'المبلغ', Icons.attach_money, keyboard: TextInputType.number),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
          value: currency,
          items: ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setDialogState(() => currency = v!),
          decoration: InputDecoration(labelText: 'العملة', prefixIcon: const Icon(Icons.currency_exchange, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
        )),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
          value: type,
          items: const [DropdownMenuItem(value: 'out', child: Text('صادر (مصروف)')), DropdownMenuItem(value: 'in', child: Text('وارد (إيراد)'))],
          onChanged: (v) => setDialogState(() => type = v!),
          decoration: InputDecoration(labelText: 'النوع', prefixIcon: const Icon(Icons.swap_vert, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
        )),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (amountC.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            try {
              await _ds.createPayment(_token, {
                'description': descC.text.trim(),
                'amount': double.tryParse(amountC.text.trim()) ?? 0,
                'currency': currency,
                'type': type,
              });
              _load();
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة الدفعة'), backgroundColor: AppColors.error));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    )));
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    )),
  );
}
