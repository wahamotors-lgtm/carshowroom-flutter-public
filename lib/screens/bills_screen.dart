import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});
  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _bills = [];
  List<Map<String, dynamic>> _billTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _load();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _ds.getMonthlyBills(_token),
        _ds.getBillTypes(_token).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _bills = results[0];
        _billTypes = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل الفواتير'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير الشهرية', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.billsPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddBillDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _load,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]))
              : _bills.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.receipt_outlined, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('لا توجد فواتير', style: TextStyle(color: AppColors.textGray)),
                    ]))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _bills.length,
                        itemBuilder: (ctx, i) => _buildCard(_bills[i]),
                      ),
                    ),
    );
  }

  // ── Bill Card ──

  Widget _buildCard(Map<String, dynamic> b) {
    final ref = b['reference_number'] ?? b['referenceNumber'] ?? b['description'] ?? '';
    final amount = b['amount'] ?? 0;
    final currency = b['currency'] ?? 'USD';
    final dueDate = b['due_date'] ?? b['dueDate'] ?? '';
    final isPaid = b['is_paid'] ?? b['isPaid'] ?? b['status'] == 'paid';
    final billingPeriod = b['billing_period'] ?? b['billingPeriod'] ?? '';
    final type = b['type'] ?? b['bill_type'] ?? b['category'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: (isPaid ? AppColors.success : const Color(0xFFEA580C)).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.receipt_long,
            color: isPaid ? AppColors.success : const Color(0xFFEA580C),
            size: 22,
          ),
        ),
        title: Text(
          ref.toString().isNotEmpty ? ref.toString() : 'فاتورة',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (type.toString().isNotEmpty) Text('النوع: $type', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (billingPeriod.toString().isNotEmpty) Text('فترة: $billingPeriod', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (dueDate.toString().isNotEmpty) Text('استحقاق: ${dueDate.toString().split('T').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$amount $currency', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isPaid ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isPaid ? 'مدفوعة' : 'غير مدفوعة',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPaid ? AppColors.success : AppColors.error),
            ),
          ),
        ]),
        onLongPress: () => _showBillActions(b),
      ),
    );
  }

  // ── Actions Bottom Sheet (Pay / Edit / Delete) ──

  void _showBillActions(Map<String, dynamic> b) {
    final id = b['id']?.toString() ?? b['_id']?.toString();
    if (id == null) return;
    final isPaid = b['is_paid'] ?? b['isPaid'] ?? b['status'] == 'paid';
    final ref = b['reference_number'] ?? b['referenceNumber'] ?? b['description'] ?? 'فاتورة';

    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (isPaid != true)
        ListTile(
          leading: const Icon(Icons.payment, color: AppColors.success),
          title: const Text('دفع الفاتورة'),
          onTap: () { Navigator.pop(ctx); _confirmPay(id, ref.toString()); },
        ),
      ListTile(
        leading: const Icon(Icons.edit_outlined, color: AppColors.blue600),
        title: const Text('تعديل'),
        onTap: () { Navigator.pop(ctx); _showEditBillDialog(b); },
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: AppColors.error),
        title: const Text('حذف', style: TextStyle(color: AppColors.error)),
        onTap: () { Navigator.pop(ctx); _confirmDelete(id, ref.toString()); },
      ),
    ])));
  }

  // ── Add Bill Dialog ──

  void _showAddBillDialog() {
    final refC = TextEditingController();
    final amountC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String currency = 'USD';
    String billingPeriod = '';
    String? selectedType;

    // Generate current month/year as default billing period
    final now = DateTime.now();
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    int selectedMonth = now.month;
    int selectedYear = now.year;
    billingPeriod = '${months[selectedMonth - 1]} $selectedYear';

    final currencies = ['USD', 'AED', 'SAR', 'EUR', 'GBP', 'IQD', 'EGP', 'JOD', 'KWD', 'QAR', 'BHD', 'OMR'];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة فاتورة شهرية', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: refC,
            decoration: InputDecoration(labelText: 'الوصف / المرجع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: amountC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب';
              if (num.tryParse(v.trim()) == null) return 'أدخل رقم صحيح';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: currency,
            decoration: InputDecoration(labelText: 'العملة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setDialogState(() => currency = v!),
          ),
          const SizedBox(height: 12),
          // Billing period: month + year
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: InputDecoration(labelText: 'الشهر', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
              onChanged: (v) => setDialogState(() {
                selectedMonth = v!;
                billingPeriod = '${months[selectedMonth - 1]} $selectedYear';
              }),
            )),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: InputDecoration(labelText: 'السنة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: List.generate(6, (i) => now.year - 2 + i).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) => setDialogState(() {
                selectedYear = v!;
                billingPeriod = '${months[selectedMonth - 1]} $selectedYear';
              }),
            )),
          ]),
          const SizedBox(height: 12),
          // Bill type / category
          _billTypes.isNotEmpty
              ? DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: 'النوع / التصنيف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _billTypes.map((t) {
                    final name = t['name'] ?? t['label'] ?? t['title'] ?? '';
                    final id = t['id']?.toString() ?? t['_id']?.toString() ?? name.toString();
                    return DropdownMenuItem(value: id, child: Text(name.toString()));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v),
                )
              : TextFormField(
                  decoration: InputDecoration(labelText: 'النوع / التصنيف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  onChanged: (v) => selectedType = v.trim(),
                ),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                final body = <String, dynamic>{
                  'reference_number': refC.text.trim(),
                  'description': refC.text.trim(),
                  'amount': num.tryParse(amountC.text.trim()) ?? 0,
                  'currency': currency,
                  'billing_period': billingPeriod,
                  if (selectedType != null && selectedType!.isNotEmpty) 'type': selectedType,
                };
                await _ds.createMonthlyBill(_token, body);
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الفاتورة بنجاح'), backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة الفاتورة'), backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('إضافة'),
          ),
        ],
      ),
    ));
  }

  // ── Edit Bill Dialog ──

  void _showEditBillDialog(Map<String, dynamic> b) {
    final id = b['id']?.toString() ?? b['_id']?.toString();
    if (id == null) return;

    final refC = TextEditingController(text: b['reference_number'] ?? b['referenceNumber'] ?? b['description'] ?? '');
    final amountC = TextEditingController(text: (b['amount'] ?? '').toString());
    final formKey = GlobalKey<FormState>();
    String currency = (b['currency'] ?? 'USD').toString();
    String? selectedType = (b['type'] ?? b['bill_type'] ?? b['category'] ?? '').toString();
    if (selectedType.isEmpty) selectedType = null;

    final currencies = ['USD', 'AED', 'SAR', 'EUR', 'GBP', 'IQD', 'EGP', 'JOD', 'KWD', 'QAR', 'BHD', 'OMR'];
    if (!currencies.contains(currency)) currencies.add(currency);

    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final now = DateTime.now();

    // Parse existing billing period
    int selectedMonth = now.month;
    int selectedYear = now.year;
    final existingPeriod = (b['billing_period'] ?? b['billingPeriod'] ?? '').toString();
    if (existingPeriod.isNotEmpty) {
      for (int i = 0; i < months.length; i++) {
        if (existingPeriod.contains(months[i])) {
          selectedMonth = i + 1;
          break;
        }
      }
      final yearMatch = RegExp(r'\d{4}').firstMatch(existingPeriod);
      if (yearMatch != null) selectedYear = int.tryParse(yearMatch.group(0)!) ?? now.year;
    }
    String billingPeriod = '${months[selectedMonth - 1]} $selectedYear';

    // Ensure selectedType is valid for dropdown if billTypes are loaded
    if (_billTypes.isNotEmpty && selectedType != null) {
      final validIds = _billTypes.map((t) => t['id']?.toString() ?? t['_id']?.toString() ?? (t['name'] ?? '').toString()).toList();
      if (!validIds.contains(selectedType)) selectedType = null;
    }

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل الفاتورة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: refC,
            decoration: InputDecoration(labelText: 'الوصف / المرجع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: amountC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب';
              if (num.tryParse(v.trim()) == null) return 'أدخل رقم صحيح';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: currencies.contains(currency) ? currency : currencies.first,
            decoration: InputDecoration(labelText: 'العملة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setDialogState(() => currency = v!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: selectedMonth,
              decoration: InputDecoration(labelText: 'الشهر', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i]))),
              onChanged: (v) => setDialogState(() {
                selectedMonth = v!;
                billingPeriod = '${months[selectedMonth - 1]} $selectedYear';
              }),
            )),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<int>(
              value: selectedYear,
              decoration: InputDecoration(labelText: 'السنة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: List.generate(6, (i) => now.year - 2 + i).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) => setDialogState(() {
                selectedYear = v!;
                billingPeriod = '${months[selectedMonth - 1]} $selectedYear';
              }),
            )),
          ]),
          const SizedBox(height: 12),
          _billTypes.isNotEmpty
              ? DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: 'النوع / التصنيف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _billTypes.map((t) {
                    final name = t['name'] ?? t['label'] ?? t['title'] ?? '';
                    final tid = t['id']?.toString() ?? t['_id']?.toString() ?? name.toString();
                    return DropdownMenuItem(value: tid, child: Text(name.toString()));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v),
                )
              : TextFormField(
                  initialValue: selectedType ?? '',
                  decoration: InputDecoration(labelText: 'النوع / التصنيف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  onChanged: (v) => selectedType = v.trim(),
                ),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                final body = <String, dynamic>{
                  'reference_number': refC.text.trim(),
                  'description': refC.text.trim(),
                  'amount': num.tryParse(amountC.text.trim()) ?? 0,
                  'currency': currency,
                  'billing_period': billingPeriod,
                  if (selectedType != null && selectedType!.isNotEmpty) 'type': selectedType,
                };
                await _ds.updateMonthlyBill(_token, id, body);
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل الفاتورة بنجاح'), backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تعديل الفاتورة'), backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('حفظ'),
          ),
        ],
      ),
    ));
  }

  // ── Pay Bill Confirmation ──

  void _confirmPay(String id, String ref) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('دفع الفاتورة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('تأكيد دفع "$ref"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await _ds.payBill(_token, id);
              _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم دفع الفاتورة بنجاح'), backgroundColor: AppColors.success));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل دفع الفاتورة'), backgroundColor: AppColors.error));
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('تأكيد الدفع'),
        ),
      ],
    ));
  }

  // ── Delete Confirmation ──

  void _confirmDelete(String id, String ref) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف الفاتورة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('حذف "$ref"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await _ds.deleteBill(_token, id);
              _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الفاتورة'), backgroundColor: AppColors.success));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف الفاتورة'), backgroundColor: AppColors.error));
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف'),
        ),
      ],
    ));
  }
}
