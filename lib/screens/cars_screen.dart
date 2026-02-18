import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _cars = [];
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
      final cars = await _ds.getCars(_token);
      if (!mounted) return;
      setState(() { _cars = cars; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل السيارات'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) { _filtered = List.from(_cars); } else {
      _filtered = _cars.where((c) {
        final make = (c['make'] ?? c['brand'] ?? '').toString().toLowerCase();
        final model = (c['model'] ?? '').toString().toLowerCase();
        final year = (c['year'] ?? '').toString();
        final vin = (c['vin'] ?? '').toString().toLowerCase();
        return make.contains(q) || model.contains(q) || year.contains(q) || vin.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السيارات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.cars),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog, child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController, onChanged: (_) => setState(() => _applyFilter()),
              decoration: InputDecoration(
                hintText: 'بحث عن سيارة...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                filled: true, fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
            child: Text('${_filtered.length} سيارة', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          const Divider(height: 1),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
                : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد سيارات', style: TextStyle(color: AppColors.textGray))]))
                : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData,
                    child: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length, itemBuilder: (ctx, i) => _buildCarCard(_filtered[i]))),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final status = car['status'] ?? '';
    final price = car['price'] ?? car['selling_price'] ?? car['sellingPrice'];
    final color = car['color'] ?? '';
    final vin = car['vin'] ?? '';

    Color statusColor; String statusLabel;
    switch (status.toString().toLowerCase()) {
      case 'sold': statusColor = AppColors.error; statusLabel = 'مباع'; break;
      case 'in_showroom': case 'available': statusColor = AppColors.success; statusLabel = 'في المعرض'; break;
      case 'in_transit': case 'shipping': statusColor = const Color(0xFFD97706); statusLabel = 'في الشحن'; break;
      case 'in_korea': case 'purchased': statusColor = const Color(0xFF2563EB); statusLabel = 'في كوريا'; break;
      default: statusColor = AppColors.textMuted; statusLabel = status.toString();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCarDetails(car),
        onLongPress: () => _showActions(car),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.directions_car, color: AppColors.primary, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$make $model ${year != '' ? '($year)' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              if (color.toString().isNotEmpty) ...[const Icon(Icons.palette_outlined, size: 12, color: AppColors.textMuted), const SizedBox(width: 3), Text(color.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)), const SizedBox(width: 8)],
              if (vin.toString().isNotEmpty) Text('VIN: ${vin.toString().length > 8 ? '...${vin.toString().substring(vin.toString().length - 8)}' : vin}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
            if (price != null) ...[const SizedBox(height: 4), Text('\$$price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark))],
          ]),
        ])),
      ),
    );
  }

  void _showActions(Map<String, dynamic> car) {
    final id = car['_id'] ?? car['id'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showEditDialog(car); }),
        ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _confirmDelete(id); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  void _showAddDialog() {
    final makeC = TextEditingController(); final modelC = TextEditingController(); final yearC = TextEditingController();
    final colorC = TextEditingController(); final vinC = TextEditingController(); final priceC = TextEditingController();
    final purchaseC = TextEditingController(); String status = 'in_showroom';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة سيارة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(makeC, 'الشركة المصنعة', Icons.directions_car), _input(modelC, 'الموديل', Icons.model_training),
        _input(yearC, 'السنة', Icons.calendar_today, keyboard: TextInputType.number), _input(colorC, 'اللون', Icons.palette_outlined),
        _input(vinC, 'رقم الشاصي VIN', Icons.qr_code), _input(priceC, 'سعر البيع', Icons.attach_money, keyboard: TextInputType.number),
        _input(purchaseC, 'سعر الشراء', Icons.money_off, keyboard: TextInputType.number),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: const [DropdownMenuItem(value: 'in_showroom', child: Text('في المعرض')), DropdownMenuItem(value: 'in_korea', child: Text('في كوريا')),
            DropdownMenuItem(value: 'in_transit', child: Text('في الشحن')), DropdownMenuItem(value: 'sold', child: Text('مباع'))],
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (makeC.text.trim().isEmpty) return; Navigator.pop(ctx);
          try { await _ds.createCar(_token, {'make': makeC.text.trim(), 'model': modelC.text.trim(), 'year': yearC.text.trim(), 'color': colorC.text.trim(), 'vin': vinC.text.trim(), 'status': status,
            'selling_price': double.tryParse(priceC.text.trim()) ?? 0, 'purchase_price': double.tryParse(purchaseC.text.trim()) ?? 0}); _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة السيارة'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الإضافة'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _showEditDialog(Map<String, dynamic> car) {
    final id = car['_id'] ?? car['id'] ?? '';
    final makeC = TextEditingController(text: car['make'] ?? car['brand'] ?? ''); final modelC = TextEditingController(text: car['model'] ?? '');
    final yearC = TextEditingController(text: '${car['year'] ?? ''}'); final colorC = TextEditingController(text: car['color'] ?? '');
    final vinC = TextEditingController(text: car['vin'] ?? '');
    final priceC = TextEditingController(text: '${car['selling_price'] ?? car['sellingPrice'] ?? car['price'] ?? ''}');
    final purchaseC = TextEditingController(text: '${car['purchase_price'] ?? car['purchasePrice'] ?? ''}');
    String status = car['status'] ?? 'in_showroom';
    if (!['in_showroom', 'in_korea', 'in_transit', 'sold'].contains(status)) status = 'in_showroom';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل السيارة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(makeC, 'الشركة المصنعة', Icons.directions_car), _input(modelC, 'الموديل', Icons.model_training),
        _input(yearC, 'السنة', Icons.calendar_today, keyboard: TextInputType.number), _input(colorC, 'اللون', Icons.palette_outlined),
        _input(vinC, 'رقم الشاصي VIN', Icons.qr_code), _input(priceC, 'سعر البيع', Icons.attach_money, keyboard: TextInputType.number),
        _input(purchaseC, 'سعر الشراء', Icons.money_off, keyboard: TextInputType.number),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: const [DropdownMenuItem(value: 'in_showroom', child: Text('في المعرض')), DropdownMenuItem(value: 'in_korea', child: Text('في كوريا')),
            DropdownMenuItem(value: 'in_transit', child: Text('في الشحن')), DropdownMenuItem(value: 'sold', child: Text('مباع'))],
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _ds.updateCar(_token, id, {'make': makeC.text.trim(), 'model': modelC.text.trim(), 'year': yearC.text.trim(), 'color': colorC.text.trim(), 'vin': vinC.text.trim(), 'status': status,
            'selling_price': double.tryParse(priceC.text.trim()) ?? 0, 'purchase_price': double.tryParse(purchaseC.text.trim()) ?? 0}); _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل التعديل'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف السيارة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذه السيارة نهائياً؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _ds.deleteCar(_token, id); _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success)); }
          catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );

  void _showCarDetails(Map<String, dynamic> car) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('${car['make'] ?? ''} ${car['model'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ..._detailRows(car),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showEditDialog(car); }, icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(width: 10),
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _confirmDelete(car['_id'] ?? car['id'] ?? ''); }, icon: const Icon(Icons.delete, size: 18), label: const Text('حذف'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
          ]),
        )),
      ),
    );
  }

  List<Widget> _detailRows(Map<String, dynamic> car) {
    final fields = <MapEntry<String, String>>[
      MapEntry('السنة', '${car['year'] ?? '-'}'), MapEntry('اللون', '${car['color'] ?? '-'}'),
      MapEntry('VIN', '${car['vin'] ?? '-'}'), MapEntry('الحالة', '${car['status'] ?? '-'}'),
      MapEntry('سعر البيع', '${car['selling_price'] ?? car['sellingPrice'] ?? car['price'] ?? '-'}'),
      MapEntry('سعر الشراء', '${car['purchase_price'] ?? car['purchasePrice'] ?? '-'}'),
      MapEntry('الوقود', '${car['fuel_type'] ?? car['fuelType'] ?? '-'}'),
      MapEntry('ناقل الحركة', '${car['transmission'] ?? '-'}'), MapEntry('المسافة', '${car['mileage'] ?? '-'}'),
    ];
    return fields.where((f) => f.value != '-' && f.value != 'null').map((f) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 110, child: Text(f.key, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(f.value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ]),
    )).toList();
  }
}
