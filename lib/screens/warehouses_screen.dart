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
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getWarehouses(_token);
      if (!mounted) return;
      setState(() { _warehouses = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = 'فشل تحميل المستودعات'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المستودعات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.warehousesPage),
      floatingActionButton: FloatingActionButton(backgroundColor: AppColors.primary, foregroundColor: Colors.white, onPressed: _showAddDialog, child: const Icon(Icons.add)),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
          : _warehouses.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.warehouse_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد مستودعات', style: TextStyle(color: AppColors.textGray))]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), itemCount: _warehouses.length,
              itemBuilder: (ctx, i) => _buildCard(_warehouses[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> w) {
    final name = w['name'] ?? '';
    final location = w['location'] ?? w['address'] ?? '';
    final country = w['country'] ?? '';

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
        onLongPress: () {
          final id = w['id']?.toString() ?? w['_id']?.toString();
          if (id != null) _confirmDelete(id, name);
        },
      ),
    );
  }

  void _showAddDialog() {
    final nameC = TextEditingController();
    final locationC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة مستودع', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(controller: nameC, decoration: InputDecoration(labelText: 'اسم المستودع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        const SizedBox(height: 12),
        TextFormField(controller: locationC, decoration: InputDecoration(labelText: 'الموقع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (!formKey.currentState!.validate()) return;
          Navigator.pop(ctx);
          try { await _ds.createWarehouse(_token, {'name': nameC.text.trim(), if (locationC.text.trim().isNotEmpty) 'location': locationC.text.trim()}); _load(); } catch (_) {}
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('إضافة')),
      ],
    ));
  }

  void _confirmDelete(String id, String name) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف المستودع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('حذف "$name"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx); try { await _ds.deleteWarehouse(_token, id); _load(); } catch (_) {} },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('حذف')),
      ],
    ));
  }
}
