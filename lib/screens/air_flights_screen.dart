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

  // ── Status helpers ──

  static const List<String> _statusValues = ['loading', 'shipped', 'arrived', 'customs', 'unloaded_syria', 'delivered'];

  static const Map<String, String> _statusLabels = {
    'loading': 'جاري التحميل',
    'shipped': 'في الطريق',
    'arrived': 'وصل المطار',
    'customs': 'في الجمارك',
    'unloaded_syria': 'تم التفريغ',
    'delivered': 'تم التسليم',
  };

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'loading': return const Color(0xFF2563EB);
      case 'shipped': return const Color(0xFFD97706);
      case 'arrived': return const Color(0xFF059669);
      case 'customs': return const Color(0xFF7C3AED);
      case 'unloaded_syria': return const Color(0xFF0891B2);
      case 'delivered': return AppColors.success;
      default: return AppColors.textMuted;
    }
  }

  static String _statusLabel(String status) {
    return _statusLabels[status.toLowerCase()] ?? (status.isNotEmpty ? status : '-');
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
    final status = (flight['status'] ?? '').toString();
    final totalCost = flight['total_cost'] ?? flight['totalCost'] ?? flight['cost'] ?? '';

    final sColor = _statusColor(status);
    final sLabel = _statusLabel(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(flight),
        onLongPress: () => _showActions(flight),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.flight, color: Color(0xFF2563EB), size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(flightNumber.toString().isNotEmpty ? flightNumber.toString() : (airline.toString().isNotEmpty ? airline.toString() : 'رحلة جوية'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              if (airline.toString().isNotEmpty && flightNumber.toString().isNotEmpty)
                Text(airline.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (origin.toString().isNotEmpty || destination.toString().isNotEmpty)
                Text('${origin.toString().isNotEmpty ? origin : '?'} → ${destination.toString().isNotEmpty ? destination : '?'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(sLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sColor)),
              ),
              if (totalCost.toString().isNotEmpty && totalCost.toString() != '0' && totalCost.toString() != '0.00')
                ...[const SizedBox(height: 4), Text('\$${totalCost}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted))],
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Details bottom sheet (ALL fields) ──

  void _showDetails(Map<String, dynamic> f) {
    final status = (f['status'] ?? '').toString();
    final sColor = _statusColor(status);
    final sLabel = _statusLabel(status);

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
            _row('شركة الطيران', '${f['airline'] ?? '-'}'),
            _row('مطار المغادرة', '${f['origin'] ?? f['from'] ?? '-'}'),
            _row('مطار الوصول', '${f['destination'] ?? f['to'] ?? '-'}'),
            _row('تاريخ المغادرة', '${(f['departure_date'] ?? f['departureDate'] ?? '-').toString().split('T').first}'),
            _row('تاريخ الوصول', '${(f['arrival_date'] ?? f['arrivalDate'] ?? '-').toString().split('T').first}'),
            _statusRow('الحالة', sLabel, sColor),
            _row('التكلفة الإجمالية', _formatCost(f['total_cost'] ?? f['totalCost'] ?? f['cost'])),
            _row('ملاحظات', '${f['notes'] ?? '-'}'),
            _row('تاريخ الإنشاء', '${(f['created_at'] ?? f['createdAt'] ?? '-').toString().split('T').first}'),
          ]),
        )),
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value == '-' || value == 'null' || value.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }

  Widget _statusRow(String label, String statusLabel, Color color) {
    if (statusLabel == '-') return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    ]));
  }

  String _formatCost(dynamic cost) {
    if (cost == null) return '-';
    final s = cost.toString();
    if (s.isEmpty || s == '0' || s == '0.00') return '-';
    return '\$$s';
  }

  // ── Actions bottom sheet (edit / delete) ──

  void _showActions(Map<String, dynamic> f) {
    final id = f['_id'] ?? f['id'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showEditDialog(f); }),
        ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _confirmDelete(id); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  // ── Add dialog ──

  void _showAddDialog() {
    final flightNumC = TextEditingController();
    final airlineC = TextEditingController();
    final originC = TextEditingController();
    final destC = TextEditingController();
    final departureC = TextEditingController();
    final arrivalC = TextEditingController();
    final costC = TextEditingController();
    final notesC = TextEditingController();
    String status = 'loading';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة رحلة جوية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(flightNumC, 'رقم الرحلة', Icons.confirmation_number),
        _input(airlineC, 'شركة الطيران', Icons.airlines),
        _input(originC, 'مطار المغادرة', Icons.flight_takeoff),
        _input(destC, 'مطار الوصول', Icons.flight_land),
        _dateInput(departureC, 'تاريخ المغادرة', Icons.calendar_today, ctx),
        _dateInput(arrivalC, 'تاريخ الوصول المتوقع', Icons.event_available, ctx),
        _input(costC, 'التكلفة الإجمالية', Icons.attach_money, keyboard: TextInputType.number),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: _statusValues.map((v) => DropdownMenuItem(value: v, child: Text(_statusLabels[v] ?? v))).toList(),
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        _input(notesC, 'ملاحظات', Icons.notes),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (flightNumC.text.trim().isEmpty || airlineC.text.trim().isEmpty || originC.text.trim().isEmpty || destC.text.trim().isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى تعبئة الحقول المطلوبة'), backgroundColor: AppColors.error));
            return;
          }
          Navigator.pop(ctx);
          try {
            await _api.post(ApiConfig.airFlights, {
              'flight_number': flightNumC.text.trim(),
              'airline': airlineC.text.trim(),
              'origin': originC.text.trim(),
              'destination': destC.text.trim(),
              'departure_date': departureC.text.trim().isNotEmpty ? departureC.text.trim() : null,
              'arrival_date': arrivalC.text.trim().isNotEmpty ? arrivalC.text.trim() : null,
              'total_cost': costC.text.trim().isNotEmpty ? double.tryParse(costC.text.trim()) ?? 0 : 0,
              'status': status,
              'notes': notesC.text.trim(),
            }, token: _token);
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الرحلة'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة الرحلة'), backgroundColor: AppColors.error));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ── Edit dialog (pre-filled) ──

  void _showEditDialog(Map<String, dynamic> f) {
    final id = f['_id'] ?? f['id'] ?? '';
    final flightNumC = TextEditingController(text: f['flight_number'] ?? f['flightNumber'] ?? '');
    final airlineC = TextEditingController(text: f['airline'] ?? '');
    final originC = TextEditingController(text: f['origin'] ?? f['from'] ?? '');
    final destC = TextEditingController(text: f['destination'] ?? f['to'] ?? '');
    final departureC = TextEditingController(text: _formatDate(f['departure_date'] ?? f['departureDate'] ?? ''));
    final arrivalC = TextEditingController(text: _formatDate(f['arrival_date'] ?? f['arrivalDate'] ?? ''));
    final costC = TextEditingController(text: _formatCostRaw(f['total_cost'] ?? f['totalCost'] ?? f['cost']));
    final notesC = TextEditingController(text: f['notes'] ?? '');
    String status = (f['status'] ?? 'loading').toString();
    if (!_statusValues.contains(status)) status = 'loading';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل الرحلة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(flightNumC, 'رقم الرحلة', Icons.confirmation_number),
        _input(airlineC, 'شركة الطيران', Icons.airlines),
        _input(originC, 'مطار المغادرة', Icons.flight_takeoff),
        _input(destC, 'مطار الوصول', Icons.flight_land),
        _dateInput(departureC, 'تاريخ المغادرة', Icons.calendar_today, ctx),
        _dateInput(arrivalC, 'تاريخ الوصول المتوقع', Icons.event_available, ctx),
        _input(costC, 'التكلفة الإجمالية', Icons.attach_money, keyboard: TextInputType.number),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: _statusValues.map((v) => DropdownMenuItem(value: v, child: Text(_statusLabels[v] ?? v))).toList(),
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        _input(notesC, 'ملاحظات', Icons.notes),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (flightNumC.text.trim().isEmpty || airlineC.text.trim().isEmpty || originC.text.trim().isEmpty || destC.text.trim().isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى تعبئة الحقول المطلوبة'), backgroundColor: AppColors.error));
            return;
          }
          Navigator.pop(ctx);
          try {
            await _api.put('${ApiConfig.airFlights}/$id', {
              'flight_number': flightNumC.text.trim(),
              'airline': airlineC.text.trim(),
              'origin': originC.text.trim(),
              'destination': destC.text.trim(),
              'departure_date': departureC.text.trim().isNotEmpty ? departureC.text.trim() : null,
              'arrival_date': arrivalC.text.trim().isNotEmpty ? arrivalC.text.trim() : null,
              'total_cost': costC.text.trim().isNotEmpty ? double.tryParse(costC.text.trim()) ?? 0 : 0,
              'status': status,
              'notes': notesC.text.trim(),
            }, token: _token);
            _load();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل التعديل'), backgroundColor: AppColors.error));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ── Delete confirmation ──

  void _confirmDelete(dynamic id) {
    if (id == null || id.toString().isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف الرحلة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذه الرحلة نهائياً؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _api.delete('${ApiConfig.airFlights}/$id', token: _token); _load(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success)); }
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

  String _formatCostRaw(dynamic cost) {
    if (cost == null) return '';
    final s = cost.toString();
    if (s == '0' || s == '0.00') return '';
    return s;
  }

  DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;
    try { return DateTime.parse(text); } catch (_) { return null; }
  }
}
