import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late final DataService _dataService;
  List<Map<String, dynamic>> _suppliers = [];
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
      final data = await _dataService.getSuppliers(_token);
      if (!mounted) return;
      setState(() { _suppliers = data; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل الموردين'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) { _filtered = List.from(_suppliers); } else {
      _filtered = _suppliers.where((s) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        final phone = (s['phone'] ?? '').toString().toLowerCase();
        return name.contains(q) || phone.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الموردين', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.suppliersPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddSupplierDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _applyFilter()),
            decoration: InputDecoration(
              hintText: 'بحث بالاسم أو الهاتف...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
              filled: true, fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
          child: Text('${_filtered.length} مورد', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        const Divider(height: 1),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16), ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
              : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا يوجد موردين', style: TextStyle(color: AppColors.textGray))]))
              : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData, child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length,
                  itemBuilder: (ctx, i) => _buildSupplierCard(_filtered[i]),
                )),
        ),
      ]),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> s) {
    final name = s['name'] ?? '';
    final phone = s['phone'] ?? '';
    final country = s['country'] ?? '';
    final email = s['email'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.local_shipping, color: Color(0xFFD97706), size: 22),
        ),
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (country.isNotEmpty) Text(country, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        onTap: () => _showSupplierDetails(s),
        onLongPress: () => _showSupplierActions(s),
      ),
    );
  }

  void _showSupplierDetails(Map<String, dynamic> s) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(s['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _detailRow('الهاتف', s['phone'] ?? '-'),
            _detailRow('البريد', s['email'] ?? '-'),
            _detailRow('الدولة', s['country'] ?? '-'),
            _detailRow('العنوان', s['address'] ?? '-'),
            _detailRow('ملاحظات', s['notes'] ?? '-'),
          ]),
        )),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value == '-' || value == 'null' || value.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }

  void _showSupplierActions(Map<String, dynamic> s) {
    final id = s['id']?.toString() ?? s['_id']?.toString();
    if (id == null) return;
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.edit_outlined, color: AppColors.blue600), title: const Text('تعديل'), onTap: () { Navigator.pop(ctx); _showEditSupplierDialog(s); }),
      ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () {
        Navigator.pop(ctx);
        _confirmDelete(id, s['name'] ?? '');
      }),
    ])));
  }

  void _showAddSupplierDialog() {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final emailC = TextEditingController();
    final countryC = TextEditingController();
    final addressC = TextEditingController();
    final notesC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة مورد', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameC, decoration: InputDecoration(labelText: 'اسم المورد', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phoneC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'البريد الإلكتروني (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: countryC, decoration: InputDecoration(labelText: 'الدولة (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: addressC, decoration: InputDecoration(labelText: 'العنوان (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: notesC, maxLines: 2, decoration: InputDecoration(labelText: 'ملاحظات (اختياري)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx);
            try {
              await _dataService.createSupplier(_token, {
                'name': nameC.text.trim(),
                if (phoneC.text.trim().isNotEmpty) 'phone': phoneC.text.trim(),
                if (emailC.text.trim().isNotEmpty) 'email': emailC.text.trim(),
                if (countryC.text.trim().isNotEmpty) 'country': countryC.text.trim(),
                if (addressC.text.trim().isNotEmpty) 'address': addressC.text.trim(),
                if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
              });
              _loadData();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المورد بنجاح'), backgroundColor: AppColors.success));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة المورد'), backgroundColor: AppColors.error));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة'),
        ),
      ],
    ));
  }

  void _showEditSupplierDialog(Map<String, dynamic> s) {
    final nameC = TextEditingController(text: s['name'] ?? '');
    final phoneC = TextEditingController(text: s['phone'] ?? '');
    final emailC = TextEditingController(text: s['email'] ?? '');
    final countryC = TextEditingController(text: s['country'] ?? '');
    final addressC = TextEditingController(text: s['address'] ?? '');
    final notesC = TextEditingController(text: s['notes'] ?? '');
    final id = s['id']?.toString() ?? s['_id']?.toString();
    if (id == null) return;
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل المورد', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameC, decoration: InputDecoration(labelText: 'اسم المورد', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: phoneC, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: countryC, decoration: InputDecoration(labelText: 'الدولة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: addressC, decoration: InputDecoration(labelText: 'العنوان', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        TextFormField(controller: notesC, maxLines: 2, decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx);
            try {
              await _dataService.updateSupplier(_token, id, {
                'name': nameC.text.trim(),
                'phone': phoneC.text.trim(),
                'email': emailC.text.trim(),
                'country': countryC.text.trim(),
                'address': addressC.text.trim(),
                'notes': notesC.text.trim(),
              });
              _loadData();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل المورد بنجاح'), backgroundColor: AppColors.success));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تعديل المورد'), backgroundColor: AppColors.error));
            }
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
      title: const Text('حذف المورد', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('هل تريد حذف "$name"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            await _dataService.deleteSupplier(_token, id);
            _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المورد'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف المورد'), backgroundColor: AppColors.error));
          }
        },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('حذف')),
      ],
    ));
  }
}
