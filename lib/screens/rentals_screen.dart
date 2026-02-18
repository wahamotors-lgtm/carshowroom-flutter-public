import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});
  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _rentals = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> _currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getRentals(_token);
      if (!mounted) return;
      setState(() { _rentals = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل الإيجارات'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإيجارات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.rentalsPage),
      floatingActionButton: FloatingActionButton(backgroundColor: AppColors.primary, foregroundColor: Colors.white, onPressed: _showAddDialog, child: const Icon(Icons.add)),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
          : _rentals.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.home_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد إيجارات', style: TextStyle(color: AppColors.textGray))]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), itemCount: _rentals.length,
              itemBuilder: (ctx, i) => _buildCard(_rentals[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final name = r['name'] ?? r['property_name'] ?? '';
    final amount = r['amount'] ?? r['monthly_rent'] ?? 0;
    final currency = r['currency'] ?? 'USD';
    final dueDate = r['due_date'] ?? r['next_payment_date'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF9333EA).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.home, color: Color(0xFF9333EA), size: 22)),
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: dueDate.toString().isNotEmpty ? Text('استحقاق: ${dueDate.toString().split('T').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)) : null,
        trailing: Text('$amount $currency', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        onTap: () => _showDetails(r),
        onLongPress: () => _showActions(r),
      ),
    );
  }

  // ── Input helper ──

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );

  // ── Detail bottom sheet ──

  void _showDetails(Map<String, dynamic> r) {
    final name = r['name'] ?? r['property_name'] ?? '';
    final amount = r['amount'] ?? r['monthly_rent'] ?? 0;
    final currency = r['currency'] ?? 'USD';
    final dueDate = r['due_date'] ?? r['next_payment_date'] ?? '';
    final notes = r['notes'] ?? '';

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _detailRow('المبلغ', '$amount $currency'),
            _detailRow('تاريخ الاستحقاق', dueDate.toString().isNotEmpty ? dueDate.toString().split('T').first : '-'),
            _detailRow('ملاحظات', notes.toString().isNotEmpty ? notes.toString() : '-'),
          ]),
        )),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value == '-' || value == 'null' || value.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }

  // ── Long-press actions (edit / delete) ──

  void _showActions(Map<String, dynamic> r) {
    final id = r['id']?.toString() ?? r['_id']?.toString();
    if (id == null) return;
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.edit_outlined, color: AppColors.blue600), title: const Text('تعديل'), onTap: () { Navigator.pop(ctx); _showEditDialog(r); }),
      ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () {
        Navigator.pop(ctx);
        _confirmDelete(id, r['name'] ?? r['property_name'] ?? '');
      }),
    ])));
  }

  // ── Add rental dialog ──

  void _showAddDialog() {
    final nameC = TextEditingController();
    final amountC = TextEditingController();
    final notesC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedCurrency = 'USD';
    DateTime? selectedDate;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة إيجار', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(nameC, 'اسم الإيجار', Icons.home_outlined),
        _input(amountC, 'المبلغ', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        // Currency dropdown
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
          value: selectedCurrency,
          decoration: InputDecoration(labelText: 'العملة', prefixIcon: const Icon(Icons.currency_exchange, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setDialogState(() => selectedCurrency = v ?? 'USD'),
        )),
        // Date picker
        Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: ctx, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100),
              builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: AppColors.primary)), child: child!));
            if (picked != null) setDialogState(() => selectedDate = picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(labelText: 'تاريخ الاستحقاق', prefixIcon: const Icon(Icons.calendar_today, size: 20), filled: true, fillColor: AppColors.bgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            child: Text(selectedDate != null ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}' : '',
              style: const TextStyle(fontSize: 14)),
          ),
        )),
        _input(notesC, 'ملاحظات (اختياري)', Icons.notes),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameC.text.trim().isEmpty || amountC.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تعبئة الاسم والمبلغ'), backgroundColor: AppColors.error));
              return;
            }
            Navigator.pop(ctx);
            try {
              await _ds.createRental(_token, {
                'name': nameC.text.trim(),
                'amount': num.tryParse(amountC.text.trim()) ?? 0,
                'currency': selectedCurrency,
                if (selectedDate != null) 'due_date': '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
              });
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الإيجار بنجاح'), backgroundColor: AppColors.success));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة الإيجار'), backgroundColor: AppColors.error));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة'),
        ),
      ],
    )));
  }

  // ── Edit rental dialog ──

  void _showEditDialog(Map<String, dynamic> r) {
    final id = r['id']?.toString() ?? r['_id']?.toString();
    if (id == null) return;

    final nameC = TextEditingController(text: r['name'] ?? r['property_name'] ?? '');
    final amountC = TextEditingController(text: (r['amount'] ?? r['monthly_rent'] ?? '').toString());
    final notesC = TextEditingController(text: r['notes'] ?? '');
    String selectedCurrency = r['currency'] ?? 'USD';
    if (!_currencies.contains(selectedCurrency)) selectedCurrency = 'USD';

    final rawDate = r['due_date'] ?? r['next_payment_date'] ?? '';
    DateTime? selectedDate;
    if (rawDate.toString().isNotEmpty) {
      try { selectedDate = DateTime.parse(rawDate.toString()); } catch (_) {}
    }

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل الإيجار', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(nameC, 'اسم الإيجار', Icons.home_outlined),
        _input(amountC, 'المبلغ', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        // Currency dropdown
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
          value: selectedCurrency,
          decoration: InputDecoration(labelText: 'العملة', prefixIcon: const Icon(Icons.currency_exchange, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setDialogState(() => selectedCurrency = v ?? 'USD'),
        )),
        // Date picker
        Padding(padding: const EdgeInsets.only(bottom: 10), child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(context: ctx, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100),
              builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: Theme.of(c).colorScheme.copyWith(primary: AppColors.primary)), child: child!));
            if (picked != null) setDialogState(() => selectedDate = picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(labelText: 'تاريخ الاستحقاق', prefixIcon: const Icon(Icons.calendar_today, size: 20), filled: true, fillColor: AppColors.bgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            child: Text(selectedDate != null ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}' : '',
              style: const TextStyle(fontSize: 14)),
          ),
        )),
        _input(notesC, 'ملاحظات', Icons.notes),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (nameC.text.trim().isEmpty || amountC.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تعبئة الاسم والمبلغ'), backgroundColor: AppColors.error));
              return;
            }
            Navigator.pop(ctx);
            try {
              await _ds.updateRental(_token, id, {
                'name': nameC.text.trim(),
                'amount': num.tryParse(amountC.text.trim()) ?? 0,
                'currency': selectedCurrency,
                'due_date': selectedDate != null ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}' : '',
                'notes': notesC.text.trim(),
              });
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل الإيجار بنجاح'), backgroundColor: AppColors.success));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تعديل الإيجار'), backgroundColor: AppColors.error));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ'),
        ),
      ],
    )));
  }

  // ── Delete confirmation ──

  void _confirmDelete(String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف الإيجار', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('هل تريد حذف "$name"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            await _ds.deleteRental(_token, id);
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الإيجار'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف الإيجار'), backgroundColor: AppColors.error));
          }
        },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('حذف')),
      ],
    ));
  }
}
