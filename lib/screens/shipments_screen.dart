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
    final id = shipment['_id'] ?? shipment['id'] ?? '';
    final trackingNumber = shipment['tracking_number'] ?? shipment['trackingNumber'] ?? '';
    final origin = shipment['origin'] ?? shipment['from'] ?? '';
    final destination = shipment['destination'] ?? shipment['to'] ?? '';
    final status = shipment['status'] ?? '';
    final date = shipment['shipping_date'] ?? shipment['shippingDate'] ?? shipment['date'] ?? shipment['created_at'] ?? '';
    final carCount = shipment['car_count'] ?? shipment['carCount'] ?? shipment['cars']?.length ?? 0;

    Color statusColor;
    String statusLabel;
    switch (status.toString().toLowerCase()) {
      case 'in_transit': case 'shipped': statusColor = const Color(0xFFD97706); statusLabel = 'في الطريق'; break;
      case 'delivered': case 'arrived': statusColor = AppColors.success; statusLabel = 'وصلت'; break;
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
        onLongPress: () => _confirmDelete(id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFEA580C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_shipping, color: Color(0xFFEA580C), size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trackingNumber.isNotEmpty ? trackingNumber : 'شحنة', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              if (origin.toString().isNotEmpty || destination.toString().isNotEmpty)
                Text('${origin.toString().isNotEmpty ? origin : '?'} → ${destination.toString().isNotEmpty ? destination : '?'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              if (carCount > 0) ...[const SizedBox(height: 4), Text('$carCount سيارات', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted))],
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> shipment) {
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
            _row('رقم التتبع', '${shipment['tracking_number'] ?? shipment['trackingNumber'] ?? '-'}'),
            _row('المصدر', '${shipment['origin'] ?? shipment['from'] ?? '-'}'),
            _row('الوجهة', '${shipment['destination'] ?? shipment['to'] ?? '-'}'),
            _row('الحالة', '${shipment['status'] ?? '-'}'),
            _row('تاريخ الشحن', '${(shipment['shipping_date'] ?? shipment['shippingDate'] ?? shipment['date'] ?? '-').toString().split('T').first}'),
            _row('تاريخ الوصول', '${(shipment['arrival_date'] ?? shipment['arrivalDate'] ?? '-').toString().split('T').first}'),
            _row('الناقل', '${shipment['carrier'] ?? shipment['shipping_line'] ?? '-'}'),
            _row('التكلفة', '${shipment['cost'] ?? shipment['shipping_cost'] ?? '-'}'),
            _row('ملاحظات', '${shipment['notes'] ?? '-'}'),
          ]),
        )),
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value == '-' || value == 'null') return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }

  void _showAddDialog() {
    final trackingC = TextEditingController();
    final originC = TextEditingController();
    final destC = TextEditingController();
    final carrierC = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة شحنة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(trackingC, 'رقم التتبع', Icons.qr_code),
        _input(originC, 'المصدر', Icons.flight_takeoff),
        _input(destC, 'الوجهة', Icons.flight_land),
        _input(carrierC, 'الناقل / خط الشحن', Icons.local_shipping_outlined),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await _ds.createShipment(_token, {
                'tracking_number': trackingC.text.trim(),
                'origin': originC.text.trim(),
                'destination': destC.text.trim(),
                'carrier': carrierC.text.trim(),
                'status': 'pending',
              });
              _load();
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة الشحنة'), backgroundColor: AppColors.error));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  Widget _input(TextEditingController c, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    )),
  );

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف الشحنة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذه الشحنة؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try { await _ds.deleteShipment(_token, id); _load(); }
            catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error)); }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}
