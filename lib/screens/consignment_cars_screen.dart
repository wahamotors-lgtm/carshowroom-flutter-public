import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ConsignmentCarsScreen extends StatefulWidget {
  const ConsignmentCarsScreen({super.key});
  @override
  State<ConsignmentCarsScreen> createState() => _ConsignmentCarsScreenState();
}

class _ConsignmentCarsScreenState extends State<ConsignmentCarsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _cars = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getConsignmentCars(_token);
      if (!mounted) return;
      setState(() { _cars = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = 'فشل تحميل سيارات الأمانة'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سيارات الأمانة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.consignmentCarsPage),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? _buildError()
          : _cars.isEmpty ? _buildEmpty()
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20), itemCount: _cars.length,
              itemBuilder: (ctx, i) => _buildCard(_cars[i]),
            )),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
    const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
  ]));

  Widget _buildEmpty() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.car_rental_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
    Text('لا توجد سيارات أمانة', style: TextStyle(color: AppColors.textGray)),
  ]));

  Widget _buildCard(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final ownerName = car['owner_name'] ?? car['ownerName'] ?? '';
    final status = car['status'] ?? '';
    final price = car['price'] ?? car['selling_price'] ?? car['sellingPrice'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(car),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.car_rental, color: Color(0xFF7C3AED), size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$make $model ${year != '' ? '($year)' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              if (ownerName.toString().isNotEmpty) Text('المالك: $ownerName', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (status.toString().isNotEmpty) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(status.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              if (price != null) ...[const SizedBox(height: 4), Text('\$$price', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark))],
            ]),
          ]),
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> car) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('${car['make'] ?? ''} ${car['model'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ..._detailRows(car),
          ]),
        )),
      ),
    );
  }

  List<Widget> _detailRows(Map<String, dynamic> car) {
    final fields = <MapEntry<String, String>>[
      MapEntry('السنة', '${car['year'] ?? '-'}'),
      MapEntry('اللون', '${car['color'] ?? '-'}'),
      MapEntry('المالك', '${car['owner_name'] ?? car['ownerName'] ?? '-'}'),
      MapEntry('هاتف المالك', '${car['owner_phone'] ?? car['ownerPhone'] ?? '-'}'),
      MapEntry('الحالة', '${car['status'] ?? '-'}'),
      MapEntry('السعر', '${car['price'] ?? car['selling_price'] ?? '-'}'),
      MapEntry('العمولة', '${car['commission'] ?? '-'}'),
      MapEntry('ملاحظات', '${car['notes'] ?? '-'}'),
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
