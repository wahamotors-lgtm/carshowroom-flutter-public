import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ContainersScreen extends StatefulWidget {
  const ContainersScreen({super.key});
  @override
  State<ContainersScreen> createState() => _ContainersScreenState();
}

class _ContainersScreenState extends State<ContainersScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _containers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getContainers(_token);
      if (!mounted) return;
      setState(() { _containers = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل الحاويات'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحاويات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.containersPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog, child: const Icon(Icons.add),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
          : _containers.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد حاويات', style: TextStyle(color: AppColors.textGray))]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), itemCount: _containers.length,
              itemBuilder: (ctx, i) => _buildCard(_containers[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final number = c['container_number'] ?? c['containerNumber'] ?? c['number'] ?? '';
    final status = c['status'] ?? '';
    final shippingLine = c['shipping_line'] ?? c['shippingLine'] ?? '';
    final origin = c['origin'] ?? '';
    final destination = c['destination'] ?? '';
    final departure = c['departure_date'] ?? c['departureDate'] ?? '';
    final arrival = c['arrival_date'] ?? c['arrivalDate'] ?? c['estimated_arrival'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status.toString().toLowerCase()) {
      case 'delivered': statusColor = AppColors.success; statusLabel = 'تم التسليم'; break;
      case 'arrived': statusColor = const Color(0xFF059669); statusLabel = 'وصلت'; break;
      case 'in_transit': case 'shipping': statusColor = const Color(0xFFD97706); statusLabel = 'في الطريق'; break;
      case 'pending': statusColor = AppColors.blue600; statusLabel = 'قيد الانتظار'; break;
      case 'loading': statusColor = AppColors.blue600; statusLabel = 'جاري التحميل'; break;
      default: statusColor = AppColors.textMuted; statusLabel = status.toString().isNotEmpty ? status.toString() : '-';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: () => _showActions(c),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2, color: Color(0xFF0284C7), size: 22)),
          title: Text(number.isNotEmpty ? number : 'حاوية', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (shippingLine.toString().isNotEmpty) Text(shippingLine.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (origin.toString().isNotEmpty || destination.toString().isNotEmpty) Text('${origin.toString().isNotEmpty ? origin : '—'} → ${destination.toString().isNotEmpty ? destination : '—'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (departure.toString().isNotEmpty) Text('مغادرة: ${departure.toString().split('T').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (arrival.toString().isNotEmpty) Text('وصول: ${arrival.toString().split('T').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ),
      ),
    );
  }

  // ── Actions bottom sheet (edit / delete) ──

  void _showActions(Map<String, dynamic> c) {
    final id = c['_id'] ?? c['id'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showEditDialog(c); }),
        ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _confirmDelete(id); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  // ── Add dialog ──

  void _showAddDialog() {
    final numberC = TextEditingController();
    final shippingLineC = TextEditingController();
    final originC = TextEditingController();
    final destinationC = TextEditingController();
    final departureC = TextEditingController();
    final arrivalC = TextEditingController();
    String status = 'pending';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة حاوية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(numberC, 'رقم الحاوية', Icons.tag),
        _input(shippingLineC, 'خط الشحن', Icons.directions_boat),
        _input(originC, 'المصدر', Icons.flight_takeoff),
        _input(destinationC, 'الوجهة', Icons.flight_land),
        _dateInput(departureC, 'تاريخ المغادرة', Icons.calendar_today, ctx),
        _dateInput(arrivalC, 'تاريخ الوصول', Icons.event_available, ctx),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
            DropdownMenuItem(value: 'in_transit', child: Text('في الطريق')),
            DropdownMenuItem(value: 'arrived', child: Text('وصلت')),
            DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
          ],
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (numberC.text.trim().isEmpty) return; Navigator.pop(ctx);
          try {
            await _ds.createContainer(_token, {
              'container_number': numberC.text.trim(),
              'shipping_line': shippingLineC.text.trim(),
              'origin': originC.text.trim(),
              'destination': destinationC.text.trim(),
              'departure_date': departureC.text.trim(),
              'arrival_date': arrivalC.text.trim(),
              'status': status,
            });
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الحاوية'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الإضافة'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ── Edit dialog (pre-filled) ──

  void _showEditDialog(Map<String, dynamic> c) {
    final id = c['_id'] ?? c['id'] ?? '';
    final numberC = TextEditingController(text: c['container_number'] ?? c['containerNumber'] ?? c['number'] ?? '');
    final shippingLineC = TextEditingController(text: c['shipping_line'] ?? c['shippingLine'] ?? '');
    final originC = TextEditingController(text: c['origin'] ?? '');
    final destinationC = TextEditingController(text: c['destination'] ?? '');
    final departureC = TextEditingController(text: _formatDate(c['departure_date'] ?? c['departureDate'] ?? ''));
    final arrivalC = TextEditingController(text: _formatDate(c['arrival_date'] ?? c['arrivalDate'] ?? c['estimated_arrival'] ?? ''));
    String status = c['status'] ?? 'pending';
    if (!['pending', 'in_transit', 'arrived', 'delivered'].contains(status)) status = 'pending';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل الحاوية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(numberC, 'رقم الحاوية', Icons.tag),
        _input(shippingLineC, 'خط الشحن', Icons.directions_boat),
        _input(originC, 'المصدر', Icons.flight_takeoff),
        _input(destinationC, 'الوجهة', Icons.flight_land),
        _dateInput(departureC, 'تاريخ المغادرة', Icons.calendar_today, ctx),
        _dateInput(arrivalC, 'تاريخ الوصول', Icons.event_available, ctx),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
            DropdownMenuItem(value: 'in_transit', child: Text('في الطريق')),
            DropdownMenuItem(value: 'arrived', child: Text('وصلت')),
            DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
          ],
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try {
            await _ds.updateContainer(_token, id, {
              'container_number': numberC.text.trim(),
              'shipping_line': shippingLineC.text.trim(),
              'origin': originC.text.trim(),
              'destination': destinationC.text.trim(),
              'departure_date': departureC.text.trim(),
              'arrival_date': arrivalC.text.trim(),
              'status': status,
            });
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل التعديل'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ── Delete confirmation ──

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف الحاوية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذه الحاوية نهائياً؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _ds.deleteContainer(_token, id); _load(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success)); }
          catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  // ── Helpers ──

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );

  Widget _dateInput(TextEditingController c, String label, IconData icon, BuildContext dialogContext) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c, readOnly: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        suffixIcon: c.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { c.clear(); (dialogContext as Element).markNeedsBuild(); }) : null),
      onTap: () async {
        final picked = await showDatePicker(
          context: dialogContext, initialDate: _parseDate(c.text) ?? DateTime.now(),
          firstDate: DateTime(2020), lastDate: DateTime(2040),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)), child: child!),
        );
        if (picked != null) {
          c.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          (dialogContext as Element).markNeedsBuild();
        }
      },
    ),
  );

  String _formatDate(dynamic date) {
    if (date == null) return '';
    final s = date.toString();
    if (s.isEmpty) return '';
    return s.split('T').first;
  }

  DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;
    try { return DateTime.parse(text); } catch (_) { return null; }
  }
}
