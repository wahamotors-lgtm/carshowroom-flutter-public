import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key});
  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _shipments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getShipments(_token);
      if (!mounted) return;
      setState(() { _shipments = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل الشحنات'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشحنات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.shipmentsPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : _shipments.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.local_shipping_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد شحنات', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), itemCount: _shipments.length,
              itemBuilder: (ctx, i) => _buildCard(_shipments[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> shipment) {
    final shipmentNumber = shipment['shipment_number'] ?? shipment['shipmentNumber'] ?? shipment['tracking_number'] ?? '';
    final origin = shipment['origin'] ?? '';
    final destination = shipment['destination'] ?? '';
    final status = shipment['status'] ?? '';
    final shippingDate = shipment['shipping_date'] ?? shipment['shippingDate'] ?? shipment['date'] ?? shipment['created_at'] ?? '';
    final totalCost = shipment['total_cost'] ?? shipment['totalCost'] ?? shipment['cost'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status.toString().toLowerCase()) {
      case 'in_transit': case 'shipped': statusColor = const Color(0xFFD97706); statusLabel = 'في الطريق'; break;
      case 'arrived': statusColor = const Color(0xFF059669); statusLabel = 'وصلت'; break;
      case 'delivered': statusColor = AppColors.success; statusLabel = 'تم التسليم'; break;
      case 'pending': statusColor = const Color(0xFF2563EB); statusLabel = 'قيد الانتظار'; break;
      case 'cancelled': statusColor = AppColors.error; statusLabel = 'ملغاة'; break;
      default: statusColor = AppColors.textMuted; statusLabel = status.toString().isNotEmpty ? status.toString() : '-';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(shipment),
        onLongPress: () => _showActions(shipment),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFEA580C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_shipping, color: Color(0xFFEA580C), size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shipmentNumber.toString().isNotEmpty ? shipmentNumber.toString() : 'شحنة', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              if (origin.toString().isNotEmpty || destination.toString().isNotEmpty)
                Text('${origin.toString().isNotEmpty ? origin : '?'} → ${destination.toString().isNotEmpty ? destination : '?'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (shippingDate.toString().isNotEmpty) Text(shippingDate.toString().split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (totalCost.toString().isNotEmpty && totalCost.toString() != '0' && totalCost.toString() != '0.00')
                Text('\$ ${totalCost.toString()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Details bottom sheet ──

  void _showDetails(Map<String, dynamic> shipment) {
    final id = shipment['_id'] ?? shipment['id'] ?? '';
    final status = shipment['status'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status.toString().toLowerCase()) {
      case 'in_transit': case 'shipped': statusColor = const Color(0xFFD97706); statusLabel = 'في الطريق'; break;
      case 'arrived': statusColor = const Color(0xFF059669); statusLabel = 'وصلت'; break;
      case 'delivered': statusColor = AppColors.success; statusLabel = 'تم التسليم'; break;
      case 'pending': statusColor = const Color(0xFF2563EB); statusLabel = 'قيد الانتظار'; break;
      case 'cancelled': statusColor = AppColors.error; statusLabel = 'ملغاة'; break;
      default: statusColor = AppColors.textMuted; statusLabel = status.toString().isNotEmpty ? status.toString() : '-';
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('تفاصيل الشحنة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _row('رقم الشحنة', '${shipment['shipment_number'] ?? shipment['shipmentNumber'] ?? shipment['tracking_number'] ?? '-'}'),
            _row('المصدر', '${shipment['origin'] ?? '-'}'),
            _row('الوجهة', '${shipment['destination'] ?? '-'}'),
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
              const SizedBox(width: 110, child: Text('الحالة', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ])),
            _row('تاريخ الشحن', '${_formatDate(shipment['shipping_date'] ?? shipment['shippingDate'] ?? '')}'),
            _row('تاريخ التسليم المتوقع', '${_formatDate(shipment['delivery_date'] ?? shipment['deliveryDate'] ?? '')}'),
            _row('التكلفة الإجمالية', _formatCost(shipment['total_cost'] ?? shipment['totalCost'] ?? shipment['cost'] ?? '')),
            _row('ملاحظات', '${shipment['notes'] ?? '-'}'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(context); _showEditDialog(shipment); },
                icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(context); _confirmDelete(id.toString()); },
                icon: const Icon(Icons.delete, size: 18), label: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
              )),
            ]),
          ]),
        )),
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value == '-' || value == 'null' || value.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }

  // ── Actions bottom sheet (edit / delete) ──

  void _showActions(Map<String, dynamic> shipment) {
    final id = shipment['_id'] ?? shipment['id'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showEditDialog(shipment); }),
        ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _confirmDelete(id.toString()); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  // ── Add dialog ──

  void _showAddDialog() {
    final shipmentNumberC = TextEditingController();
    final originC = TextEditingController();
    final destC = TextEditingController();
    final shippingDateC = TextEditingController();
    final deliveryDateC = TextEditingController();
    final totalCostC = TextEditingController();
    final notesC = TextEditingController();
    String status = 'pending';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة شحنة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(shipmentNumberC, 'رقم الشحنة', Icons.qr_code),
        _input(originC, 'المصدر', Icons.flight_takeoff),
        _input(destC, 'الوجهة', Icons.flight_land),
        _dateInput(shippingDateC, 'تاريخ الشحن', Icons.calendar_today, ctx),
        _dateInput(deliveryDateC, 'تاريخ التسليم المتوقع', Icons.event_available, ctx),
        _input(totalCostC, 'التكلفة الإجمالية', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
            DropdownMenuItem(value: 'in_transit', child: Text('في الطريق')),
            DropdownMenuItem(value: 'arrived', child: Text('وصلت')),
            DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
            DropdownMenuItem(value: 'cancelled', child: Text('ملغاة')),
          ],
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        _input(notesC, 'ملاحظات', Icons.notes),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            await _ds.createShipment(_token, {
              'shipment_number': shipmentNumberC.text.trim(),
              'origin': originC.text.trim(),
              'destination': destC.text.trim(),
              'shipping_date': shippingDateC.text.trim(),
              'delivery_date': deliveryDateC.text.trim(),
              'total_cost': totalCostC.text.trim().isNotEmpty ? double.tryParse(totalCostC.text.trim()) ?? 0 : 0,
              'status': status,
              'notes': notesC.text.trim(),
            });
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الشحنة'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة الشحنة'), backgroundColor: AppColors.error));
          }
        },
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ── Edit dialog (pre-filled) ──

  void _showEditDialog(Map<String, dynamic> shipment) {
    final id = shipment['_id'] ?? shipment['id'] ?? '';
    final shipmentNumberC = TextEditingController(text: shipment['shipment_number'] ?? shipment['shipmentNumber'] ?? shipment['tracking_number'] ?? '');
    final originC = TextEditingController(text: shipment['origin'] ?? '');
    final destC = TextEditingController(text: shipment['destination'] ?? '');
    final shippingDateC = TextEditingController(text: _formatDate(shipment['shipping_date'] ?? shipment['shippingDate'] ?? ''));
    final deliveryDateC = TextEditingController(text: _formatDate(shipment['delivery_date'] ?? shipment['deliveryDate'] ?? ''));
    final totalCostC = TextEditingController(text: _formatCostRaw(shipment['total_cost'] ?? shipment['totalCost'] ?? shipment['cost'] ?? ''));
    final notesC = TextEditingController(text: shipment['notes'] ?? '');
    String status = shipment['status'] ?? 'pending';
    if (!['pending', 'in_transit', 'arrived', 'delivered', 'cancelled'].contains(status)) status = 'pending';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل الشحنة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(shipmentNumberC, 'رقم الشحنة', Icons.qr_code),
        _input(originC, 'المصدر', Icons.flight_takeoff),
        _input(destC, 'الوجهة', Icons.flight_land),
        _dateInput(shippingDateC, 'تاريخ الشحن', Icons.calendar_today, ctx),
        _dateInput(deliveryDateC, 'تاريخ التسليم المتوقع', Icons.event_available, ctx),
        _input(totalCostC, 'التكلفة الإجمالية', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
            DropdownMenuItem(value: 'in_transit', child: Text('في الطريق')),
            DropdownMenuItem(value: 'arrived', child: Text('وصلت')),
            DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
            DropdownMenuItem(value: 'cancelled', child: Text('ملغاة')),
          ],
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        _input(notesC, 'ملاحظات', Icons.notes),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try {
            await _ds.updateShipment(_token, id.toString(), {
              'shipment_number': shipmentNumberC.text.trim(),
              'origin': originC.text.trim(),
              'destination': destC.text.trim(),
              'shipping_date': shippingDateC.text.trim(),
              'delivery_date': deliveryDateC.text.trim(),
              'total_cost': totalCostC.text.trim().isNotEmpty ? double.tryParse(totalCostC.text.trim()) ?? 0 : 0,
              'status': status,
              'notes': notesC.text.trim(),
            });
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل الشحنة'), backgroundColor: AppColors.success));
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
      title: const Text('حذف الشحنة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذه الشحنة نهائياً؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async { Navigator.pop(ctx);
            try { await _ds.deleteShipment(_token, id); _load(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الشحنة'), backgroundColor: AppColors.success)); }
            catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error)); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
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

  String _formatCost(dynamic cost) {
    if (cost == null) return '-';
    final s = cost.toString();
    if (s.isEmpty || s == '0' || s == '0.00') return '-';
    return '\$ $s';
  }

  String _formatCostRaw(dynamic cost) {
    if (cost == null) return '';
    final s = cost.toString();
    if (s.isEmpty || s == '0' || s == '0.00') return '';
    return s;
  }

  DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;
    try { return DateTime.parse(text); } catch (_) { return null; }
  }
}
