import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../widgets/app_drawer.dart';

class AirFlightsScreen extends StatefulWidget {
  const AirFlightsScreen({super.key});
  @override
  State<AirFlightsScreen> createState() => _AirFlightsScreenState();
}

class _AirFlightsScreenState extends State<AirFlightsScreen> {
  late final ApiService _api;
  List<Map<String, dynamic>> _flights = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _api = ApiService(); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.getList(ApiConfig.airFlights, token: _token);
      if (!mounted) return;
      setState(() { _flights = data.cast<Map<String, dynamic>>(); _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل الرحلات الجوية'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرحلات الجوية', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.airFlightsPage),
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
          : _flights.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.flight_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12),
              Text('لا توجد رحلات جوية', style: TextStyle(color: AppColors.textGray)),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80), itemCount: _flights.length,
              itemBuilder: (ctx, i) => _buildCard(_flights[i]),
            )),
    );
  }

  Widget _buildCard(Map<String, dynamic> flight) {
    final flightNumber = flight['flight_number'] ?? flight['flightNumber'] ?? '';
    final airline = flight['airline'] ?? '';
    final origin = flight['origin'] ?? flight['from'] ?? '';
    final destination = flight['destination'] ?? flight['to'] ?? '';
    final date = flight['departure_date'] ?? flight['departureDate'] ?? flight['date'] ?? '';
    final status = flight['status'] ?? '';
    final carCount = flight['car_count'] ?? flight['carCount'] ?? flight['cars']?.length ?? 0;

    Color statusColor;
    String statusLabel;
    switch (status.toString().toLowerCase()) {
      case 'arrived': case 'delivered': statusColor = AppColors.success; statusLabel = 'وصلت'; break;
      case 'in_flight': case 'in_transit': statusColor = const Color(0xFF2563EB); statusLabel = 'في الجو'; break;
      case 'pending': case 'scheduled': statusColor = const Color(0xFFD97706); statusLabel = 'مجدولة'; break;
      case 'cancelled': statusColor = AppColors.error; statusLabel = 'ملغاة'; break;
      default: statusColor = AppColors.textMuted; statusLabel = status.toString().isNotEmpty ? status.toString() : '-';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(flight),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.flight, color: Color(0xFF2563EB), size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(flightNumber.isNotEmpty ? flightNumber : (airline.isNotEmpty ? airline : 'رحلة جوية'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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

  void _showDetails(Map<String, dynamic> f) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('تفاصيل الرحلة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _row('رقم الرحلة', '${f['flight_number'] ?? f['flightNumber'] ?? '-'}'),
            _row('الناقل', '${f['airline'] ?? '-'}'),
            _row('المصدر', '${f['origin'] ?? f['from'] ?? '-'}'),
            _row('الوجهة', '${f['destination'] ?? f['to'] ?? '-'}'),
            _row('تاريخ المغادرة', '${(f['departure_date'] ?? f['departureDate'] ?? '-').toString().split('T').first}'),
            _row('تاريخ الوصول', '${(f['arrival_date'] ?? f['arrivalDate'] ?? '-').toString().split('T').first}'),
            _row('الحالة', '${f['status'] ?? '-'}'),
            _row('التكلفة', '${f['cost'] ?? '-'}'),
            _row('ملاحظات', '${f['notes'] ?? '-'}'),
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
    final flightNumC = TextEditingController();
    final airlineC = TextEditingController();
    final originC = TextEditingController();
    final destC = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة رحلة جوية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(flightNumC, 'رقم الرحلة', Icons.confirmation_number),
        _input(airlineC, 'شركة الطيران', Icons.airlines),
        _input(originC, 'المصدر', Icons.flight_takeoff),
        _input(destC, 'الوجهة', Icons.flight_land),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await _api.post(ApiConfig.airFlights, {
                'flight_number': flightNumC.text.trim(),
                'airline': airlineC.text.trim(),
                'origin': originC.text.trim(),
                'destination': destC.text.trim(),
                'status': 'scheduled',
              }, token: _token);
              _load();
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة الرحلة'), backgroundColor: AppColors.error));
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
}
