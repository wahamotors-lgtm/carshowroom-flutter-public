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
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getSalesCommissions(_token);
      if (!mounted) return;
      setState(() { _commissions = data; _applyFilter(); _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل العمولات'; _isLoading = false; }); }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_commissions);
    } else {
      _filtered = _commissions.where((c) {
        final name = (c['employee_name'] ?? c['employeeName'] ?? c['salesman'] ?? '').toString().toLowerCase();
        final carMake = (c['car_make'] ?? c['make'] ?? '').toString().toLowerCase();
        final carModel = (c['car_model'] ?? c['model'] ?? '').toString().toLowerCase();
        return name.contains(q) || carMake.contains(q) || carModel.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العمولات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.commissionsPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        // Search bar
        Container(
          color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _applyFilter()),
            decoration: InputDecoration(
              hintText: 'بحث بالموظف أو السيارة...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
              filled: true, fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        // Count
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
          child: Text('${_filtered.length} عمولة', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        const Divider(height: 1),
        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
                      const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
                    ]))
                  : _filtered.isEmpty
                      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.monetization_on_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
                          Text('لا توجد عمولات', style: TextStyle(color: AppColors.textGray)),
                        ]))
                      : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
                        )),
        ),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> commission) {
    final employeeName = commission['employee_name'] ?? commission['employeeName'] ?? commission['salesman'] ?? '';
    final amount = commission['amount'] ?? commission['commission_amount'] ?? 0;
    final currency = commission['currency'] ?? 'USD';
    final carInfo = '${commission['car_make'] ?? commission['make'] ?? ''} ${commission['car_model'] ?? commission['model'] ?? ''}'.trim();
    final date = commission['date'] ?? commission['sale_date'] ?? commission['created_at'] ?? '';
    final status = commission['status'] ?? (commission['paid'] == true ? 'paid' : 'pending');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.monetization_on, color: Color(0xFFD97706), size: 22)),
        title: Text(employeeName.isNotEmpty ? employeeName.toString() : 'عمولة', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
        onLongPress: () => _showActions(commission),
      ),
    );
  }

  // ── Actions Bottom Sheet ──

  void _showActions(Map<String, dynamic> commission) {
    final id = commission['id']?.toString() ?? commission['_id']?.toString();
    if (id == null) return;
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(
        leading: const Icon(Icons.edit_outlined, color: AppColors.blue600),
        title: const Text('تعديل'),
        onTap: () { Navigator.pop(ctx); _showEditDialog(commission); },
      ),
      ListTile(
        leading: const Icon(Icons.delete_outline, color: AppColors.error),
        title: const Text('حذف', style: TextStyle(color: AppColors.error)),
        onTap: () { Navigator.pop(ctx); _confirmDelete(id, commission['employee_name'] ?? commission['employeeName'] ?? 'عمولة'); },
      ),
    ])));
  }

  // ── Add Commission Dialog ──

  void _showAddDialog() {
    final employeeNameC = TextEditingController();
    final amountC = TextEditingController();
    final carMakeC = TextEditingController();
    final carModelC = TextEditingController();
    final notesC = TextEditingController();
    String currency = 'USD';
    String status = 'pending';
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إضافة عمولة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: employeeNameC,
            decoration: InputDecoration(labelText: 'اسم الموظف / البائع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: amountC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'مبلغ العمولة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: currency,
            decoration: InputDecoration(labelText: 'العملة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: const [
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'AED', child: Text('AED')),
              DropdownMenuItem(value: 'KRW', child: Text('KRW')),
              DropdownMenuItem(value: 'SYP', child: Text('SYP')),
              DropdownMenuItem(value: 'SAR', child: Text('SAR')),
              DropdownMenuItem(value: 'CNY', child: Text('CNY')),
            ],
            onChanged: (v) => setDialogState(() => currency = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: carMakeC,
            decoration: InputDecoration(labelText: 'ماركة السيارة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: carModelC,
            decoration: InputDecoration(labelText: 'موديل السيارة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          // Date picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (picked != null) setDialogState(() => selectedDate = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(labelText: 'التاريخ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('الحالة:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('معلق'),
              selected: status == 'pending',
              selectedColor: const Color(0xFFD97706).withValues(alpha: 0.2),
              onSelected: (_) => setDialogState(() => status = 'pending'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('مدفوع'),
              selected: status == 'paid',
              selectedColor: AppColors.success.withValues(alpha: 0.2),
              onSelected: (_) => setDialogState(() => status = 'paid'),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesC,
            maxLines: 2,
            decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
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
                  'employee_name': employeeNameC.text.trim(),
                  'amount': num.tryParse(amountC.text.trim()) ?? 0,
                  'currency': currency,
                  'status': status,
                  'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  if (carMakeC.text.trim().isNotEmpty) 'car_make': carMakeC.text.trim(),
                  if (carModelC.text.trim().isNotEmpty) 'car_model': carModelC.text.trim(),
                  if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
                };
                await _ds.createSalesCommission(_token, body);
                _load();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة العمولة بنجاح'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة العمولة'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('إضافة'),
          ),
        ],
      ),
    ));
  }

  // ── Edit Commission Dialog ──

  void _showEditDialog(Map<String, dynamic> commission) {
    final id = commission['id']?.toString() ?? commission['_id']?.toString();
    if (id == null) return;

    final employeeNameC = TextEditingController(text: commission['employee_name'] ?? commission['employeeName'] ?? commission['salesman'] ?? '');
    final amountC = TextEditingController(text: (commission['amount'] ?? commission['commission_amount'] ?? '').toString());
    final carMakeC = TextEditingController(text: commission['car_make'] ?? commission['make'] ?? '');
    final carModelC = TextEditingController(text: commission['car_model'] ?? commission['model'] ?? '');
    final notesC = TextEditingController(text: commission['notes'] ?? '');
    String currency = commission['currency'] ?? 'USD';
    String status = commission['status'] ?? (commission['paid'] == true ? 'paid' : 'pending');
    DateTime selectedDate = DateTime.tryParse(commission['date']?.toString() ?? commission['sale_date']?.toString() ?? '') ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل العمولة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: employeeNameC,
            decoration: InputDecoration(labelText: 'اسم الموظف / البائع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: amountC,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'مبلغ العمولة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'].contains(currency) ? currency : 'USD',
            decoration: InputDecoration(labelText: 'العملة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: const [
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'AED', child: Text('AED')),
              DropdownMenuItem(value: 'KRW', child: Text('KRW')),
              DropdownMenuItem(value: 'SYP', child: Text('SYP')),
              DropdownMenuItem(value: 'SAR', child: Text('SAR')),
              DropdownMenuItem(value: 'CNY', child: Text('CNY')),
            ],
            onChanged: (v) => setDialogState(() => currency = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: carMakeC,
            decoration: InputDecoration(labelText: 'ماركة السيارة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: carModelC,
            decoration: InputDecoration(labelText: 'موديل السيارة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (picked != null) setDialogState(() => selectedDate = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(labelText: 'التاريخ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('الحالة:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('معلق'),
              selected: status == 'pending',
              selectedColor: const Color(0xFFD97706).withValues(alpha: 0.2),
              onSelected: (_) => setDialogState(() => status = 'pending'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('مدفوع'),
              selected: status == 'paid',
              selectedColor: AppColors.success.withValues(alpha: 0.2),
              onSelected: (_) => setDialogState(() => status = 'paid'),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: notesC,
            maxLines: 2,
            decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
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
                  'employee_name': employeeNameC.text.trim(),
                  'amount': num.tryParse(amountC.text.trim()) ?? 0,
                  'currency': currency,
                  'status': status,
                  'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  'car_make': carMakeC.text.trim(),
                  'car_model': carModelC.text.trim(),
                  'notes': notesC.text.trim(),
                };
                await _ds.updateSalesCommission(_token, id, body);
                _load();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل العمولة بنجاح'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تعديل العمولة'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('حفظ'),
          ),
        ],
      ),
    ));
  }

  // ── Delete Confirmation ──

  void _confirmDelete(String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف العمولة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('حذف عمولة "$name"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await _ds.deleteSalesCommission(_token, id);
              _load();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف العمولة'), backgroundColor: AppColors.success));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف العمولة'), backgroundColor: AppColors.error));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف'),
        ),
      ],
    ));
  }
}
