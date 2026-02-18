import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../models/account_model.dart';
import '../providers/auth_provider.dart';
import '../services/account_service.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

// ── Category helpers ──

const Map<String, String> _categoryLabels = {
  'shipping': 'شحن',
  'customs': 'جمارك',
  'transport': 'نقل',
  'loading': 'تحميل',
  'clearance': 'تخليص',
  'port_fees': 'رسوم ميناء',
  'government': 'رسوم حكومية',
  'car_expense': 'مصروف سيارة',
  'other': 'أخرى',
};

Color _categoryColor(String? category) {
  switch (category) {
    case 'shipping':
      return const Color(0xFF2563EB); // blue
    case 'customs':
      return const Color(0xFFD97706); // amber
    case 'transport':
      return const Color(0xFF7C3AED); // violet
    case 'loading':
      return const Color(0xFF0891B2); // cyan
    case 'clearance':
      return const Color(0xFFDB2777); // pink
    case 'port_fees':
      return const Color(0xFF0D9488); // teal
    case 'government':
      return const Color(0xFFDC2626); // red
    case 'car_expense':
      return const Color(0xFFEA580C); // orange
    case 'other':
    default:
      return const Color(0xFF64748B); // slate
  }
}

String _categoryLabel(String? category) {
  if (category == null || category.isEmpty) return 'أخرى';
  return _categoryLabels[category] ?? category;
}

class ExpenseRecordScreen extends StatefulWidget {
  const ExpenseRecordScreen({super.key});

  @override
  State<ExpenseRecordScreen> createState() => _ExpenseRecordScreenState();
}

class _ExpenseRecordScreenState extends State<ExpenseRecordScreen> {
  late final DataService _dataService;
  late final AccountService _accountService;
  List<Map<String, dynamic>> _expenses = [];
  List<AccountModel> _accounts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final api = ApiService();
    _dataService = DataService(api);
    _accountService = AccountService(api);
    _loadData();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _dataService.getExpenses(_token),
        _accountService.getAccounts(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _expenses = results[0] as List<Map<String, dynamic>>;
        _accounts = (results[1] as List<AccountModel>);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  String _accountName(String? id) {
    if (id == null) return '-';
    return _accounts.where((a) => a.id == id).firstOrNull?.name ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل مصروف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.expenseRecord),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
                ]))
              : _expenses.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_card_outlined, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text('لا توجد مصاريف', style: TextStyle(color: AppColors.textGray)),
                    ]))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) => _buildExpenseCard(_expenses[index]),
                      ),
                    ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final amount = double.tryParse('${expense['amount'] ?? 0}') ?? 0;
    final currency = expense['currency'] ?? 'USD';
    final description = expense['description'] ?? '';
    final category = expense['category']?.toString();
    final date = expense['expense_date'] ?? expense['expenseDate'] ?? expense['date'] ?? '';
    final debitId = expense['debit_account_id']?.toString() ?? expense['debitAccountId']?.toString();
    final creditId = expense['credit_account_id']?.toString() ?? expense['creditAccountId']?.toString();
    final notes = expense['notes']?.toString() ?? '';
    final catColor = _categoryColor(category);
    final catLabel = _categoryLabel(category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Category badge + description + amount
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    catLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: catColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${amount.toStringAsFixed(2)} $currency',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: catColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row 2: Debit -> Credit accounts
            Row(
              children: [
                Icon(Icons.swap_horiz_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_accountName(debitId)}  -->  ${_accountName(creditId)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Row 3: Date + notes
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  date.toString().length >= 10 ? date.toString().substring(0, 10) : date.toString(),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.notes_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).let((card) => GestureDetector(
      onLongPress: () {
        final id = expense['id']?.toString() ?? expense['_id']?.toString();
        if (id != null) _confirmDelete(id, description);
      },
      child: card,
    ));
  }

  void _showAddExpenseDialog() {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب إضافة حسابات أولاً'), backgroundColor: AppColors.error));
      return;
    }
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String? debitAccountId;
    String? creditAccountId;
    String currency = 'USD';
    String category = 'other';
    DateTime expenseDate = DateTime.now();
    final formKey = GlobalKey<FormState>();
    const currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تسجيل مصروف جديد', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // 1. Description
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(labelText: 'وصف المصروف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                // 2. Amount + Currency row
                Row(children: [
                  Expanded(flex: 2, child: TextFormField(
                    controller: amountController, keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                    validator: (v) { if (v!.trim().isEmpty) return 'مطلوب'; if (double.tryParse(v) == null) return 'غير صحيح'; return null; },
                  )),
                  const SizedBox(width: 10),
                  // 3. Currency dropdown
                  Expanded(child: DropdownButtonFormField<String>(
                    value: currency,
                    decoration: InputDecoration(labelText: 'العملة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                    items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setDialogState(() => currency = v!),
                  )),
                ]),
                const SizedBox(height: 12),
                // 4. Category dropdown
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: category,
                  decoration: InputDecoration(labelText: 'نوع المصروف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  items: _categoryLabels.entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text('${e.value} (${e.key})', style: const TextStyle(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                const SizedBox(height: 12),
                // 5. Expense date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expenseDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(primary: AppColors.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setDialogState(() => expenseDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 6. Debit account
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(labelText: 'الحساب المدين', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  items: _accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setDialogState(() => debitAccountId = v),
                  validator: (v) => v == null ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                // 7. Credit account
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: InputDecoration(labelText: 'الحساب الدائن', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  items: _accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setDialogState(() => creditAccountId = v),
                  validator: (v) => v == null ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                // 8. Notes
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final dateStr = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}';
                try {
                  await _dataService.createExpense(_token, {
                    'description': descController.text.trim(),
                    'amount': double.tryParse(amountController.text.trim()) ?? 0,
                    'currency': currency,
                    'category': category,
                    'expense_date': dateStr,
                    'debit_account_id': debitAccountId,
                    'credit_account_id': creditAccountId,
                    'notes': notesController.text.trim(),
                  });
                  _loadData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل المصروف'), backgroundColor: AppColors.success));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تسجيل المصروف'), backgroundColor: AppColors.error));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('تسجيل', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String desc) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف المصروف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Text('حذف "$desc"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try { await _dataService.deleteExpense(_token, id); _loadData(); } catch (_) {}
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف'),
        ),
      ],
    ));
  }
}

/// Extension to allow inline transformations (used for wrapping widgets).
extension _LetExtension<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
