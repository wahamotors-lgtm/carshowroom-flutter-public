import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
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
      return const Color(0xFF2563EB);
    case 'customs':
      return const Color(0xFFD97706);
    case 'transport':
      return const Color(0xFF7C3AED);
    case 'loading':
      return const Color(0xFF0891B2);
    case 'clearance':
      return const Color(0xFFDB2777);
    case 'port_fees':
      return const Color(0xFF0D9488);
    case 'government':
      return const Color(0xFFDC2626);
    case 'car_expense':
      return const Color(0xFFEA580C);
    case 'other':
    default:
      return const Color(0xFF64748B);
  }
}

String _categoryLabel(String? category) {
  if (category == null || category.isEmpty) return 'أخرى';
  return _categoryLabels[category] ?? category;
}

class ContainerExpensesScreen extends StatefulWidget {
  const ContainerExpensesScreen({super.key});
  @override
  State<ContainerExpensesScreen> createState() => _ContainerExpensesScreenState();
}

class _ContainerExpensesScreenState extends State<ContainerExpensesScreen> {
  late final DataService _dataService;
  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _containers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedContainerId;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataService = DataService(ApiService());
    _loadData();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _dataService.getExpenses(_token),
        _dataService.getContainers(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _allExpenses = results[0] as List<Map<String, dynamic>>;
        _containers = results[1] as List<Map<String, dynamic>>;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    _filtered = _allExpenses.where((exp) {
      // Filter by container
      if (_selectedContainerId != null) {
        final cId = exp['container_id']?.toString() ?? exp['containerId']?.toString();
        if (cId != _selectedContainerId) return false;
      }
      // Filter by search text
      if (q.isNotEmpty) {
        final desc = (exp['description'] ?? '').toString().toLowerCase();
        final notes = (exp['notes'] ?? '').toString().toLowerCase();
        final category = _categoryLabel(exp['category']?.toString()).toLowerCase();
        return desc.contains(q) || notes.contains(q) || category.contains(q);
      }
      return true;
    }).toList();
  }

  String _containerName(String? id) {
    if (id == null) return '-';
    final c = _containers.where((c) => (c['id']?.toString() ?? c['_id']?.toString()) == id).firstOrNull;
    if (c == null) return '-';
    return c['container_number']?.toString() ?? c['name']?.toString() ?? '-';
  }

  double _totalForSelected() {
    double total = 0;
    for (final exp in _filtered) {
      total += double.tryParse('${exp['amount'] ?? 0}') ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مصاريف الحاويات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.containerExpenses),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        // -- Container dropdown selector --
        Container(
          color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedContainerId,
            decoration: InputDecoration(
              labelText: 'اختر الحاوية',
              prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 22),
              filled: true, fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('جميع الحاويات', style: TextStyle(fontSize: 14))),
              ..._containers.map((c) {
                final cId = c['id']?.toString() ?? c['_id']?.toString() ?? '';
                final cName = c['container_number']?.toString() ?? c['name']?.toString() ?? cId;
                return DropdownMenuItem<String>(value: cId, child: Text(cName, style: const TextStyle(fontSize: 14)));
              }),
            ],
            onChanged: (v) => setState(() { _selectedContainerId = v; _applyFilter(); }),
          ),
        ),
        // -- Summary card --
        Container(
          width: double.infinity, color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _selectedContainerId != null ? 'إجمالي مصاريف الحاوية' : 'إجمالي جميع المصاريف',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_totalForSelected().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ]),
            ]),
          ),
        ),
        // -- Search bar --
        Container(
          color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _applyFilter()),
            decoration: InputDecoration(
              hintText: 'بحث في المصاريف...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
              filled: true, fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        // -- Count --
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
          child: Text('${_filtered.length} مصروف', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        const Divider(height: 1),
        // -- List --
        Expanded(
          child: _isLoading
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
                  : _filtered.isEmpty
                      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('لا توجد مصاريف', style: TextStyle(color: AppColors.textGray)),
                        ]))
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  // ── Expense Card ──

  Widget _buildCard(Map<String, dynamic> expense) {
    final amount = double.tryParse('${expense['amount'] ?? 0}') ?? 0;
    final currency = expense['currency'] ?? 'USD';
    final description = expense['description'] ?? '';
    final category = expense['category']?.toString();
    final date = expense['expense_date'] ?? expense['expenseDate'] ?? expense['date'] ?? '';
    final notes = expense['notes']?.toString() ?? '';
    final containerId = expense['container_id']?.toString() ?? expense['containerId']?.toString();
    final catColor = _categoryColor(category);
    final catLabel = _categoryLabel(category);

    return GestureDetector(
      onLongPress: () => _showActions(expense),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Row 1: Category badge + description + amount
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: catColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(catLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: catColor)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('${amount.toStringAsFixed(2)} $currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: catColor)),
            ]),
            const SizedBox(height: 8),
            // Row 2: Container info
            if (containerId != null) Row(children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('حاوية: ${_containerName(containerId)}', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
            ]),
            if (containerId != null) const SizedBox(height: 4),
            // Row 3: Date + notes
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                date.toString().length >= 10 ? date.toString().substring(0, 10) : date.toString(),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.notes_rounded, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(notes, style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Actions Bottom Sheet ──

  void _showActions(Map<String, dynamic> expense) {
    final id = expense['id']?.toString() ?? expense['_id']?.toString();
    if (id == null) return;
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.edit_outlined, color: AppColors.blue600),
        title: const Text('تعديل'),
        onTap: () { Navigator.pop(ctx); _showEditDialog(expense); },
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: AppColors.error),
        title: const Text('حذف', style: TextStyle(color: AppColors.error)),
        onTap: () { Navigator.pop(ctx); _confirmDelete(id, expense['description'] ?? ''); },
      ),
    ])));
  }

  // ── Add Expense Dialog ──

  void _showAddDialog() {
    final descC = TextEditingController();
    final amountC = TextEditingController();
    final notesC = TextEditingController();
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
          title: const Text('إضافة مصروف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              // 1. Description
              TextFormField(
                controller: descC,
                decoration: InputDecoration(labelText: 'وصف المصروف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              // 2. Amount + Currency
              Row(children: [
                Expanded(flex: 2, child: TextFormField(
                  controller: amountC, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  validator: (v) { if (v!.trim().isEmpty) return 'مطلوب'; if (double.tryParse(v) == null) return 'غير صحيح'; return null; },
                )),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(
                  value: currency,
                  decoration: InputDecoration(labelText: 'العملة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                  items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => currency = v!),
                )),
              ]),
              const SizedBox(height: 12),
              // 3. Category
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
              // 4. Date picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: expenseDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setDialogState(() => expenseDate = picked);
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
              // 5. Notes
              TextFormField(
                controller: notesC, maxLines: 3,
                decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
              ),
              // Show selected container info
              if (_selectedContainerId != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('حاوية: ${_containerName(_selectedContainerId)}', style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final dateStr = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}';
                try {
                  final body = <String, dynamic>{
                    'description': descC.text.trim(),
                    'amount': double.tryParse(amountC.text.trim()) ?? 0,
                    'currency': currency,
                    'category': category,
                    'expense_date': dateStr,
                    'notes': notesC.text.trim(),
                  };
                  if (_selectedContainerId != null) body['container_id'] = _selectedContainerId;
                  await _dataService.createExpense(_token, body);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المصروف بنجاح'), backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة المصروف'), backgroundColor: AppColors.error));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Expense Dialog ──

  void _showEditDialog(Map<String, dynamic> expense) {
    final id = expense['id']?.toString() ?? expense['_id']?.toString();
    if (id == null) return;

    final descC = TextEditingController(text: expense['description'] ?? '');
    final amountC = TextEditingController(text: (expense['amount'] ?? '').toString());
    final notesC = TextEditingController(text: expense['notes'] ?? '');
    String currency = expense['currency'] ?? 'USD';
    String category = expense['category'] ?? 'other';
    final rawDate = expense['expense_date'] ?? expense['expenseDate'] ?? expense['date'] ?? '';
    DateTime expenseDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
    final formKey = GlobalKey<FormState>();
    const currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تعديل المصروف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              // 1. Description
              TextFormField(
                controller: descC,
                decoration: InputDecoration(labelText: 'وصف المصروف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              // 2. Amount + Currency
              Row(children: [
                Expanded(flex: 2, child: TextFormField(
                  controller: amountC, keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'المبلغ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  validator: (v) { if (v!.trim().isEmpty) return 'مطلوب'; if (double.tryParse(v) == null) return 'غير صحيح'; return null; },
                )),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<String>(
                  value: currencies.contains(currency) ? currency : 'USD',
                  decoration: InputDecoration(labelText: 'العملة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14)),
                  items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setDialogState(() => currency = v!),
                )),
              ]),
              const SizedBox(height: 12),
              // 3. Category
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _categoryLabels.containsKey(category) ? category : 'other',
                decoration: InputDecoration(labelText: 'نوع المصروف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                items: _categoryLabels.entries.map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text('${e.value} (${e.key})', style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) => setDialogState(() => category = v!),
              ),
              const SizedBox(height: 12),
              // 4. Date picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: expenseDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setDialogState(() => expenseDate = picked);
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
              // 5. Notes
              TextFormField(
                controller: notesC, maxLines: 3,
                decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
              ),
            ])),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final dateStr = '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}-${expenseDate.day.toString().padLeft(2, '0')}';
                try {
                  final body = <String, dynamic>{
                    'description': descC.text.trim(),
                    'amount': double.tryParse(amountC.text.trim()) ?? 0,
                    'currency': currency,
                    'category': category,
                    'expense_date': dateStr,
                    'notes': notesC.text.trim(),
                  };
                  final cId = expense['container_id']?.toString() ?? expense['containerId']?.toString();
                  if (cId != null) body['container_id'] = cId;
                  await _dataService.updateExpense(_token, id, body);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل المصروف بنجاح'), backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تعديل المصروف'), backgroundColor: AppColors.error));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Confirmation ──

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
            try {
              await _dataService.deleteExpense(_token, id);
              _loadData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المصروف'), backgroundColor: AppColors.success));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف المصروف'), backgroundColor: AppColors.error));
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
