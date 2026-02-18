import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});
  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _load();
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getWarehouses(_token);
      if (!mounted) return;
      setState(() { _warehouses = data; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل المستودعات'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_warehouses);
    } else {
      _filtered = _warehouses.where((w) {
        final name = (w['name'] ?? '').toString().toLowerCase();
        final location = (w['location'] ?? '').toString().toLowerCase();
        final country = (w['country'] ?? '').toString().toLowerCase();
        return name.contains(q) || location.contains(q) || country.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستودعات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.warehousesPage),
      floatingActionButton: FloatingActionButton(backgroundColor: AppColors.primary, foregroundColor: Colors.white, onPressed: _showAddDialog, child: const Icon(Icons.add)),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _applyFilter()),
            decoration: InputDecoration(hintText: 'بحث...', prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
              filled: true, fillColor: AppColors.bgLight, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          ),
        ),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
          child: Text('${_filtered.length} مستودع', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        const Divider(height: 1),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
                  const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
              : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.warehouse_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد مستودعات', style: TextStyle(color: AppColors.textGray))]))
              : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length,
                  itemBuilder: (ctx, i) => _buildCard(_filtered[i]))),
        ),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> w) {
    final name = w['name'] ?? '';
    final location = w['location'] ?? w['address'] ?? '';
    final country = w['country'] ?? '';
    final capacity = w['capacity']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.warehouse, color: Color(0xFF7C3AED), size: 22)),
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (location.isNotEmpty) Text(location, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (country.isNotEmpty) Text(country, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        trailing: capacity.isNotEmpty && capacity != '0' ? Text('$capacity سيارة', style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w600)) : null,
        onTap: () => _showDetails(w),
        onLongPress: () => _showActions(w),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> w) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(w['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _detailRow('الموقع', (w['location'] ?? '-').toString()),
            _detailRow('البلد', (w['country'] ?? '-').toString()),
            _detailRow('السعة', (w['capacity'] ?? '-').toString()),
            _detailRow('الملاحظات', (w['notes'] ?? '-').toString()),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showEditDialog(w); },
                icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(width: 10),
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _confirmDelete(w['id']?.toString() ?? w['_id']?.toString() ?? '', w['name'] ?? ''); },
                icon: const Icon(Icons.delete, size: 18), label: const Text('حذف'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
          ]),
        )),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value == '-' || value == 'null' || value.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ]));
  }

  void _showActions(Map<String, dynamic> w) {
    final id = w['id']?.toString() ?? w['_id']?.toString();
    if (id == null) return;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'),
            onTap: () { Navigator.pop(context); _showEditDialog(w); }),
          ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)),
            onTap: () { Navigator.pop(context); _confirmDelete(id, w['name'] ?? ''); }),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  void _showAddDialog() {
    final nameC = TextEditingController();
    final locationC = TextEditingController();
    final countryC = TextEditingController();
    final capacityC = TextEditingController();
    final notesC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة مستودع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameC, decoration: InputDecoration(labelText: 'اسم المستودع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: locationC, decoration: InputDecoration(labelText: 'الموقع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
        const SizedBox(height: 12),
        TextFormField(controller: countryC, decoration: InputDecoration(labelText: 'البلد', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
        const SizedBox(height: 12),
        TextFormField(controller: capacityC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'السعة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
        const SizedBox(height: 12),
        TextFormField(controller: notesC, maxLines: 2, decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(ctx);
          try {
            await _ds.createWarehouse(_token, {
              'name': nameC.text.trim(),
              if (locationC.text.trim().isNotEmpty) 'location': locationC.text.trim(),
              if (countryC.text.trim().isNotEmpty) 'country': countryC.text.trim(),
              if (capacityC.text.trim().isNotEmpty) 'capacity': int.tryParse(capacityC.text.trim()) ?? 0,
              if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
            });
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإضافة'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الإضافة'), backgroundColor: AppColors.error));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  void _showEditDialog(Map<String, dynamic> w) {
    final id = w['id']?.toString() ?? w['_id']?.toString();
    if (id == null || id.isEmpty) return;
    final nameC = TextEditingController(text: w['name'] ?? '');
    final locationC = TextEditingController(text: w['location'] ?? '');
    final countryC = TextEditingController(text: w['country'] ?? '');
    final capacityC = TextEditingController(text: (w['capacity'] ?? '').toString());
    final notesC = TextEditingController(text: w['notes'] ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل المستودع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameC, decoration: InputDecoration(labelText: 'اسم المستودع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: locationC, decoration: InputDecoration(labelText: 'الموقع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
        const SizedBox(height: 12),
        TextFormField(controller: countryC, decoration: InputDecoration(labelText: 'البلد', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
        const SizedBox(height: 12),
        TextFormField(controller: capacityC, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'السعة', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
        const SizedBox(height: 12),
        TextFormField(controller: notesC, maxLines: 2, decoration: InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(ctx);
          try {
            await _ds.updateWarehouse(_token, id, {
              'name': nameC.text.trim(),
              if (locationC.text.trim().isNotEmpty) 'location': locationC.text.trim(),
              if (countryC.text.trim().isNotEmpty) 'country': countryC.text.trim(),
              if (capacityC.text.trim().isNotEmpty) 'capacity': int.tryParse(capacityC.text.trim()) ?? 0,
              if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
            });
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل التعديل'), backgroundColor: AppColors.error));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  void _confirmDelete(String id, String name) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف المستودع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('حذف "$name" نهائياً؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          try { await _ds.deleteWarehouse(_token, id); _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }
}
