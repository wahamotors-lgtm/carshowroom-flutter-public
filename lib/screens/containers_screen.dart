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

  static const List<Map<String, String>> _statusOptions = [
    {'value': 'pending', 'label': 'لم يجهز بعد'},
    {'value': 'loading', 'label': 'قيد التحميل'},
    {'value': 'shipped', 'label': 'تم الشحن'},
    {'value': 'arrived', 'label': 'وصلت'},
    {'value': 'customs', 'label': 'في الجمارك'},
    {'value': 'unloaded_syria', 'label': 'تم التفريغ'},
    {'value': 'delivered', 'label': 'تم التسليم'},
  ];

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

  // ── Status helpers ──

  String _statusLabel(String status) {
    for (final opt in _statusOptions) {
      if (opt['value'] == status.toLowerCase()) return opt['label']!;
    }
    // Legacy mapping
    switch (status.toLowerCase()) {
      case 'in_transit': case 'shipping': return 'في الطريق';
    }
    return status.isNotEmpty ? status : '-';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.blue600;
      case 'loading': return const Color(0xFF7C3AED);
      case 'shipped': return const Color(0xFFD97706);
      case 'arrived': return const Color(0xFF059669);
      case 'customs': return const Color(0xFFEA580C);
      case 'unloaded_syria': return const Color(0xFF0891B2);
      case 'delivered': return AppColors.success;
      case 'in_transit': case 'shipping': return const Color(0xFFD97706);
      default: return AppColors.textMuted;
    }
  }

  // ── Card ──

  Widget _buildCard(Map<String, dynamic> c) {
    final number = c['container_number'] ?? c['containerNumber'] ?? c['number'] ?? '';
    final status = (c['status'] ?? '').toString();
    final shippingLine = c['shipping_line'] ?? c['shippingLine'] ?? '';
    final originPort = c['origin_port'] ?? c['origin'] ?? '';
    final destinationPort = c['destination_port'] ?? c['destination'] ?? '';
    final departure = c['departure_date'] ?? c['departureDate'] ?? '';
    final arrival = c['arrival_date'] ?? c['arrivalDate'] ?? c['estimated_arrival'] ?? '';
    final totalCost = c['total_cost'] ?? c['totalCost'] ?? '';
    final notes = c['notes'] ?? '';

    final sColor = _statusColor(status);
    final sLabel = _statusLabel(status);

    // First line of notes for preview
    String notesPreview = '';
    if (notes.toString().isNotEmpty) {
      notesPreview = notes.toString().split('\n').first;
      if (notesPreview.length > 40) notesPreview = '${notesPreview.substring(0, 40)}...';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(c),
        onLongPress: () => _showActions(c),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2, color: Color(0xFF0284C7), size: 22)),
          title: Text(number.toString().isNotEmpty ? number.toString() : 'حاوية', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (shippingLine.toString().isNotEmpty) Text(shippingLine.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (originPort.toString().isNotEmpty || destinationPort.toString().isNotEmpty) Text('${originPort.toString().isNotEmpty ? originPort : '—'} → ${destinationPort.toString().isNotEmpty ? destinationPort : '—'}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (departure.toString().isNotEmpty) Text('مغادرة: ${departure.toString().split('T').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (arrival.toString().isNotEmpty) Text('وصول: ${arrival.toString().split('T').first}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (totalCost.toString().isNotEmpty && totalCost.toString() != '0' && totalCost.toString() != '0.00')
              Text('التكلفة: \$${totalCost.toString()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF059669))),
            if (notesPreview.isNotEmpty) Text(notesPreview, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
          ]),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(sLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sColor)),
          ),
        ),
      ),
    );
  }

  // ── Details bottom sheet ──

  void _showDetails(Map<String, dynamic> c) {
    final number = c['container_number'] ?? c['containerNumber'] ?? c['number'] ?? '';
    final status = (c['status'] ?? '').toString();
    final shippingLine = c['shipping_line'] ?? c['shippingLine'] ?? '';
    final originPort = c['origin_port'] ?? c['origin'] ?? '';
    final destinationPort = c['destination_port'] ?? c['destination'] ?? '';
    final departure = c['departure_date'] ?? c['departureDate'] ?? '';
    final arrival = c['arrival_date'] ?? c['arrivalDate'] ?? c['estimated_arrival'] ?? '';
    final totalCost = c['total_cost'] ?? c['totalCost'] ?? '';
    final notes = c['notes'] ?? '';

    final sColor = _statusColor(status);
    final sLabel = _statusLabel(status);

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          // Header
          Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF0284C7).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.inventory_2, color: Color(0xFF0284C7), size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(number.toString().isNotEmpty ? number.toString() : 'حاوية', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: sColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(sLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sColor))),
            ])),
          ]),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Fields
          _detailRow(Icons.directions_boat, 'شركة الشحن', shippingLine.toString()),
          _detailRow(Icons.flight_takeoff, 'ميناء التحميل', originPort.toString()),
          _detailRow(Icons.flight_land, 'ميناء الوصول', destinationPort.toString()),
          _detailRow(Icons.calendar_today, 'تاريخ المغادرة', _formatDate(departure)),
          _detailRow(Icons.event_available, 'تاريخ الوصول المتوقع', _formatDate(arrival)),
          _detailRow(Icons.attach_money, 'التكلفة الإجمالية', totalCost.toString().isNotEmpty && totalCost.toString() != '0' && totalCost.toString() != '0.00' ? '\$${totalCost.toString()}' : ''),
          if (notes.toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.notes, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ملاحظات', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(notes.toString(), style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
              ])),
            ]),
          ],
          const SizedBox(height: 20),
          // Action buttons
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _showEditDialog(c); },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('تعديل'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: () { Navigator.pop(context); _confirmDelete(c['_id'] ?? c['id'] ?? ''); },
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('حذف'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
            )),
          ]),
        ]),
      ))),
    ));
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ])),
      ]),
    );
  }

  // ── Actions bottom sheet (edit / delete) ──

  void _showActions(Map<String, dynamic> c) {
    final id = c['_id'] ?? c['id'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ListTile(leading: const Icon(Icons.visibility, color: AppColors.primary), title: const Text('عرض التفاصيل'), onTap: () { Navigator.pop(context); _showDetails(c); }),
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
    final originPortC = TextEditingController();
    final destinationPortC = TextEditingController();
    final departureC = TextEditingController();
    final arrivalC = TextEditingController();
    final totalCostC = TextEditingController();
    final notesC = TextEditingController();
    String status = 'pending';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة حاوية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(numberC, 'رقم الحاوية', Icons.tag),
        _input(shippingLineC, 'شركة الشحن', Icons.directions_boat),
        _input(originPortC, 'ميناء التحميل', Icons.flight_takeoff),
        _input(destinationPortC, 'ميناء الوصول', Icons.flight_land),
        _dateInput(departureC, 'تاريخ المغادرة', Icons.calendar_today, ctx),
        _dateInput(arrivalC, 'تاريخ الوصول المتوقع', Icons.event_available, ctx),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: _statusOptions.map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!))).toList(),
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        _input(totalCostC, 'التكلفة الإجمالية', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _textArea(notesC, 'ملاحظات', Icons.notes),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (numberC.text.trim().isEmpty) return; Navigator.pop(ctx);
          try {
            final body = <String, dynamic>{
              'container_number': numberC.text.trim(),
              'shipping_line': shippingLineC.text.trim(),
              'origin_port': originPortC.text.trim(),
              'destination_port': destinationPortC.text.trim(),
              'departure_date': departureC.text.trim(),
              'arrival_date': arrivalC.text.trim(),
              'status': status,
            };
            if (totalCostC.text.trim().isNotEmpty) body['total_cost'] = totalCostC.text.trim();
            if (notesC.text.trim().isNotEmpty) body['notes'] = notesC.text.trim();
            await _ds.createContainer(_token, body);
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
    final originPortC = TextEditingController(text: c['origin_port'] ?? c['origin'] ?? '');
    final destinationPortC = TextEditingController(text: c['destination_port'] ?? c['destination'] ?? '');
    final departureC = TextEditingController(text: _formatDate(c['departure_date'] ?? c['departureDate'] ?? ''));
    final arrivalC = TextEditingController(text: _formatDate(c['arrival_date'] ?? c['arrivalDate'] ?? c['estimated_arrival'] ?? ''));
    final totalCostC = TextEditingController(text: (c['total_cost'] ?? c['totalCost'] ?? '').toString());
    final notesC = TextEditingController(text: c['notes'] ?? '');
    String status = (c['status'] ?? 'pending').toString();
    final validStatuses = _statusOptions.map((o) => o['value']).toList();
    if (!validStatuses.contains(status)) status = 'pending';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل الحاوية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(numberC, 'رقم الحاوية', Icons.tag),
        _input(shippingLineC, 'شركة الشحن', Icons.directions_boat),
        _input(originPortC, 'ميناء التحميل', Icons.flight_takeoff),
        _input(destinationPortC, 'ميناء الوصول', Icons.flight_land),
        _dateInput(departureC, 'تاريخ المغادرة', Icons.calendar_today, ctx),
        _dateInput(arrivalC, 'تاريخ الوصول المتوقع', Icons.event_available, ctx),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(value: status,
          items: _statusOptions.map((opt) => DropdownMenuItem(value: opt['value'], child: Text(opt['label']!))).toList(),
          onChanged: (v) => setS(() => status = v!),
          decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)))),
        _input(totalCostC, 'التكلفة الإجمالية', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _textArea(notesC, 'ملاحظات', Icons.notes),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try {
            final body = <String, dynamic>{
              'container_number': numberC.text.trim(),
              'shipping_line': shippingLineC.text.trim(),
              'origin_port': originPortC.text.trim(),
              'destination_port': destinationPortC.text.trim(),
              'departure_date': departureC.text.trim(),
              'arrival_date': arrivalC.text.trim(),
              'status': status,
            };
            if (totalCostC.text.trim().isNotEmpty) body['total_cost'] = totalCostC.text.trim();
            body['notes'] = notesC.text.trim();
            await _ds.updateContainer(_token, id, body);
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

  Widget _textArea(TextEditingController c, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, maxLines: 3, minLines: 2, decoration: InputDecoration(labelText: label, prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 32), child: Icon(icon, size: 20)),
      alignLabelWithHint: true, filled: true, fillColor: AppColors.bgLight,
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
