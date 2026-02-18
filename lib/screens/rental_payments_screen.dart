import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class RentalPaymentsScreen extends StatefulWidget {
  const RentalPaymentsScreen({super.key});

  @override
  State<RentalPaymentsScreen> createState() => _RentalPaymentsScreenState();
}

class _RentalPaymentsScreenState extends State<RentalPaymentsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _payments = [];
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
  void dispose() { _searchController.dispose(); super.dispose(); }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final payments = await _ds.getRentalPayments(_token);
      if (!mounted) return;
      setState(() { _payments = payments; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل دفعات الإيجار'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) { _filtered = List.from(_payments); } else {
      _filtered = _payments.where((p) {
        final rentalId = (p['rental_id'] ?? p['rentalId'] ?? '').toString().toLowerCase();
        final amount = (p['amount'] ?? '').toString();
        final paymentDate = (p['payment_date'] ?? p['paymentDate'] ?? '').toString().toLowerCase();
        final paymentMethod = (p['payment_method'] ?? p['paymentMethod'] ?? '').toString().toLowerCase();
        final notes = (p['notes'] ?? '').toString().toLowerCase();
        return rentalId.contains(q) || amount.contains(q) || paymentDate.contains(q) || paymentMethod.contains(q) || notes.contains(q);
      }).toList();
    }
  }

  double get _totalAmount {
    double total = 0;
    for (final p in _filtered) {
      final amount = double.tryParse('${p['amount'] ?? 0}') ?? 0;
      total += amount;
    }
    return total;
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash': return 'نقداً';
      case 'bank_transfer': return 'تحويل بنكي';
      case 'check': return 'شيك';
      default: return method;
    }
  }

  Color _paymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash': return AppColors.success;
      case 'bank_transfer': return const Color(0xFF2563EB);
      case 'check': return const Color(0xFFD97706);
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفعات الإيجار', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.rentalPaymentsPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog, child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('إجمالي الدفعات', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    Text('\$${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ]),
                ]),
              )),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.receipt_long, color: AppColors.textGray, size: 20),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('العدد', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                    Text('${_filtered.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  ]),
                ]),
              ),
            ]),
          ),
          Container(
            color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController, onChanged: (_) => setState(() => _applyFilter()),
              decoration: InputDecoration(
                hintText: 'بحث في دفعات الإيجار...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                filled: true, fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
            child: Text('${_filtered.length} دفعة', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          const Divider(height: 1),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
                : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.payment_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد دفعات إيجار', style: TextStyle(color: AppColors.textGray))]))
                : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData,
                    child: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length, itemBuilder: (ctx, i) => _buildPaymentCard(_filtered[i]))),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final rentalId = payment['rental_id'] ?? payment['rentalId'] ?? '';
    final amount = payment['amount'] ?? 0;
    final paymentDate = payment['payment_date'] ?? payment['paymentDate'] ?? '';
    final paymentMethod = (payment['payment_method'] ?? payment['paymentMethod'] ?? '').toString();
    final notes = payment['notes'] ?? '';

    final methodLabel = _formatPaymentMethod(paymentMethod);
    final methodColor = _paymentMethodColor(paymentMethod);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPaymentDetails(payment),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.payment, color: AppColors.primary, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('إيجار #$rentalId', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted), const SizedBox(width: 3),
              Text('$paymentDate', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (notes.toString().isNotEmpty) ...[const SizedBox(width: 8), const Icon(Icons.note_outlined, size: 12, color: AppColors.textMuted), const SizedBox(width: 3),
                Flexible(child: Text('$notes', style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis))],
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: methodColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(methodLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: methodColor))),
            const SizedBox(height: 4),
            Text('\$$amount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ]),
        ])),
      ),
    );
  }

  void _showAddDialog() {
    final rentalIdC = TextEditingController(); final amountC = TextEditingController();
    final notesC = TextEditingController();
    final paymentDateC = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    String paymentMethod = 'cash';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة دفعة إيجار', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(rentalIdC, 'رقم الإيجار', Icons.home_outlined, keyboard: TextInputType.number),
        _input(amountC, 'المبلغ', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(
          controller: paymentDateC, readOnly: true,
          onTap: () async {
            final date = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030),
              builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)), child: child!));
            if (date != null) paymentDateC.text = date.toString().split(' ')[0];
          },
          decoration: InputDecoration(labelText: 'تاريخ الدفع', prefixIcon: const Icon(Icons.calendar_today, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
        )),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: paymentMethod,
          items: const [DropdownMenuItem(value: 'cash', child: Text('نقداً')), DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل بنكي')),
            DropdownMenuItem(value: 'check', child: Text('شيك'))],
          onChanged: (v) => setS(() => paymentMethod = v!),
          decoration: InputDecoration(labelText: 'طريقة الدفع', prefixIcon: const Icon(Icons.payment_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        _input(notesC, 'ملاحظات', Icons.note_outlined),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (rentalIdC.text.trim().isEmpty || amountC.text.trim().isEmpty) return; Navigator.pop(ctx);
          try { await _ds.createRentalPayment(_token, {'rental_id': int.tryParse(rentalIdC.text.trim()) ?? 0, 'amount': double.tryParse(amountC.text.trim()) ?? 0,
            'payment_date': paymentDateC.text.trim(), 'payment_method': paymentMethod, 'notes': notesC.text.trim()}); _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الدفعة'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الإضافة'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('دفعة إيجار #${payment['rental_id'] ?? payment['rentalId'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ..._detailRows(payment),
            const SizedBox(height: 16),
          ]),
        )),
      ),
    );
  }

  List<Widget> _detailRows(Map<String, dynamic> payment) {
    final method = (payment['payment_method'] ?? payment['paymentMethod'] ?? '').toString();
    final fields = <MapEntry<String, String>>[
      MapEntry('رقم الإيجار', '${payment['rental_id'] ?? payment['rentalId'] ?? '-'}'),
      MapEntry('المبلغ', '\$${payment['amount'] ?? '-'}'),
      MapEntry('تاريخ الدفع', '${payment['payment_date'] ?? payment['paymentDate'] ?? '-'}'),
      MapEntry('طريقة الدفع', method.isNotEmpty ? _formatPaymentMethod(method) : '-'),
      MapEntry('ملاحظات', '${payment['notes'] ?? '-'}'),
    ];
    return fields.where((f) => f.value != '-' && f.value != 'null' && f.value != '\$-').map((f) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 110, child: Text(f.key, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(f.value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ]),
    )).toList();
  }
}
