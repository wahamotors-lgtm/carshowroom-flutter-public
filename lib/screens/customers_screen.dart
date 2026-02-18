import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final DataService _dataService;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
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
      final data = await _dataService.getCustomers(_token);
      if (!mounted) return;
      setState(() { _customers = data; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل العملاء'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) { _filtered = List.from(_customers); } else {
      _filtered = _customers.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final code = (c['customer_code'] ?? c['customerCode'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        return name.contains(q) || code.contains(q) || phone.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.customersPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddCustomerDialog,
        child: const Icon(Icons.person_add),
      ),
      body: Column(children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _applyFilter()),
            decoration: InputDecoration(
              hintText: 'بحث عن عميل...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
              filled: true, fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
          child: Text('${_filtered.length} عميل', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        const Divider(height: 1),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16), ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
              : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_outline, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا يوجد عملاء', style: TextStyle(color: AppColors.textGray))]))
              : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData, child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length,
                  itemBuilder: (ctx, i) => _buildCustomerCard(_filtered[i]),
                )),
        ),
      ]),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = customer['name'] ?? '';
    final code = customer['customer_code'] ?? customer['customerCode'] ?? '';
    final phone = customer['phone'] ?? '';
    final balance = (customer['balance'] ?? 0).toDouble();
    final debt = (customer['debt'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFF0891B2).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.person_outline, color: Color(0xFF0891B2), size: 22),
        ),
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (code.isNotEmpty) Text('كود: $code', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${balance.toStringAsFixed(0)} \$', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: balance >= 0 ? AppColors.success : AppColors.error)),
          if (debt > 0) Text('دين: ${debt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: AppColors.error)),
        ]),
        onTap: () => _showCustomerDetails(customer),
        onLongPress: () => _showCustomerActions(customer),
      ),
    );
  }

  void _showCustomerDetails(Map<String, dynamic> c) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(c['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _detailRow('الكود', c['customer_code'] ?? c['customerCode'] ?? '-'),
            _detailRow('الهاتف', c['phone'] ?? '-'),
            _detailRow('البريد', c['email'] ?? '-'),
            _detailRow('العنوان', c['address'] ?? '-'),
            _detailRow('الرصيد', '${(c['balance'] ?? 0).toDouble().toStringAsFixed(2)} \$'),
            _detailRow('الدين', '${(c['debt'] ?? 0).toDouble().toStringAsFixed(2)} \$'),
          ]),
        )),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value == '-' || value == 'null') return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }

  void _showCustomerActions(Map<String, dynamic> c) {
    final id = c['id']?.toString() ?? c['_id']?.toString();
    if (id == null) return;
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.edit_outlined, color: AppColors.blue600), title: const Text('تعديل'), onTap: () { Navigator.pop(ctx); _showEditCustomerDialog(c); }),
      ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () {
        Navigator.pop(ctx);
        _confirmDelete(id, c['name'] ?? '');
      }),
    ])));
  }

  void _showAddCustomerDialog() {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final emailC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة عميل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameC, decoration: InputDecoration(labelText: 'اسم العميل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phoneC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'البريد (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx);
            try {
              await _dataService.createCustomer(_token, { 'name': nameC.text.trim(), if (phoneC.text.trim().isNotEmpty) 'phone': phoneC.text.trim(), if (emailC.text.trim().isNotEmpty) 'email': emailC.text.trim() });
              _loadData();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة العميل'), backgroundColor: AppColors.success));
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة العميل'), backgroundColor: AppColors.error)); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة'),
        ),
      ],
    ));
  }

  void _showEditCustomerDialog(Map<String, dynamic> c) {
    final nameC = TextEditingController(text: c['name'] ?? '');
    final phoneC = TextEditingController(text: c['phone'] ?? '');
    final id = c['id']?.toString() ?? c['_id']?.toString();
    if (id == null) return;
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل العميل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameC, decoration: InputDecoration(labelText: 'الاسم', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phoneC, decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx);
            try {
              await _dataService.updateCustomer(_token, id, { 'name': nameC.text.trim(), 'phone': phoneC.text.trim() });
              _loadData();
            } catch (_) {}
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ'),
        ),
      ],
    ));
  }

  void _confirmDelete(String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف العميل', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('حذف "$name"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx); try { await _dataService.deleteCustomer(_token, id); _loadData(); } catch (_) {} },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('حذف')),
      ],
    ));
  }
}
