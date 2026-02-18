import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});
  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _deliveries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getDeliveries(_token);
      if (!mounted) return;
      setState(() { _deliveries = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل التسليمات'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التسليمات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.deliveriesPage),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : _deliveries.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.delivery_dining_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد تسليمات', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20), itemCount: _deliveries.length,
              itemBuilder: (ctx, i) => _buildCard(_deliveries[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> delivery) {
    final customer = delivery['customer_name'] ?? delivery['customerName'] ?? delivery['buyer_name'] ?? '';
    final carInfo = '${delivery['car_make'] ?? delivery['make'] ?? ''} ${delivery['car_model'] ?? delivery['model'] ?? ''}'.trim();
    final date = delivery['delivery_date'] ?? delivery['deliveryDate'] ?? delivery['date'] ?? delivery['created_at'] ?? '';
    final status = delivery['status'] ?? '';
    final location = delivery['location'] ?? delivery['delivery_location'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status.toString().toLowerCase()) {
      case 'delivered': case 'completed': statusColor = AppColors.success; statusLabel = 'تم التسليم'; break;
      case 'pending': statusColor = const Color(0xFFD97706); statusLabel = 'قيد الانتظار'; break;
      case 'in_progress': case 'in_transit': statusColor = const Color(0xFF2563EB); statusLabel = 'في الطريق'; break;
      case 'cancelled': statusColor = AppColors.error; statusLabel = 'ملغى'; break;
      default: statusColor = AppColors.textMuted; statusLabel = status.toString().isNotEmpty ? status.toString() : '-';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(delivery),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delivery_dining, color: AppColors.success, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(customer.isNotEmpty ? customer : 'تسليم', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              if (carInfo.isNotEmpty) Text(carInfo, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (location.toString().isNotEmpty) Text(location.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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

  void _showDetails(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('تفاصيل التسليم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _row('العميل', '${d['customer_name'] ?? d['customerName'] ?? '-'}'),
            _row('السيارة', '${d['car_make'] ?? d['make'] ?? ''} ${d['car_model'] ?? d['model'] ?? ''}'.trim()),
            _row('تاريخ التسليم', '${(d['delivery_date'] ?? d['deliveryDate'] ?? d['date'] ?? '-').toString().split('T').first}'),
            _row('الموقع', '${d['location'] ?? d['delivery_location'] ?? '-'}'),
            _row('الحالة', '${d['status'] ?? '-'}'),
            _row('المستلم', '${d['received_by'] ?? d['receivedBy'] ?? '-'}'),
            _row('ملاحظات', '${d['notes'] ?? '-'}'),
          ]),
        )),
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value == '-' || value == 'null' || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }
}
