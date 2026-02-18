import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  static const List<String> _currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

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
      final data = await _ds.getSales(_token);
      if (!mounted) return;
      setState(() { _sales = data; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل المبيعات'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) { _filtered = List.from(_sales); } else {
      _filtered = _sales.where((s) {
        final customer = (s['customer_name'] ?? s['customerName'] ?? s['buyer_name'] ?? '').toString().toLowerCase();
        final make = (s['car_make'] ?? s['make'] ?? '').toString().toLowerCase();
        final model = (s['car_model'] ?? s['model'] ?? '').toString().toLowerCase();
        final amount = (s['selling_price'] ?? s['sellingPrice'] ?? s['amount'] ?? s['total'] ?? '').toString();
        final notes = (s['notes'] ?? '').toString().toLowerCase();
        return customer.contains(q) || make.contains(q) || model.contains(q) || amount.contains(q) || notes.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.salesPage),
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
                hintText: 'بحث عن عملية بيع...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                filled: true, fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
            child: Text('${_filtered.length} عملية بيع', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          const Divider(height: 1),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
                : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.point_of_sale_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد مبيعات', style: TextStyle(color: AppColors.textGray))]))
                : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData,
                    child: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length, itemBuilder: (ctx, i) => _buildCard(_filtered[i]))),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> sale) {
    final customerName = sale['customer_name'] ?? sale['customerName'] ?? sale['buyer_name'] ?? '';
    final carInfo = '${sale['car_make'] ?? sale['make'] ?? ''} ${sale['car_model'] ?? sale['model'] ?? ''}';
    final amount = sale['selling_price'] ?? sale['sellingPrice'] ?? sale['amount'] ?? sale['total'] ?? 0;
    final date = sale['date'] ?? sale['sale_date'] ?? sale['created_at'] ?? '';
    final currency = sale['currency'] ?? 'USD';
    final notes = sale['notes'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSaleDetails(sale),
        onLongPress: () => _showActions(sale),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.point_of_sale, color: Color(0xFFD97706), size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(customerName.toString().isNotEmpty ? customerName.toString() : 'بيع', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            if (carInfo.trim().isNotEmpty) Text(carInfo.trim(), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            if (date.toString().isNotEmpty) Text(date.toString().split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (notes.toString().isNotEmpty) Text(notes.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Text('$amount $currency', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ])),
      ),
    );
  }

  void _showSaleDetails(Map<String, dynamic> sale) {
    final customerName = sale['customer_name'] ?? sale['customerName'] ?? sale['buyer_name'] ?? '';
    final carMake = sale['car_make'] ?? sale['make'] ?? '';
    final carModel = sale['car_model'] ?? sale['model'] ?? '';
    final amount = sale['selling_price'] ?? sale['sellingPrice'] ?? sale['amount'] ?? sale['total'] ?? 0;
    final date = sale['date'] ?? sale['sale_date'] ?? sale['created_at'] ?? '';
    final currency = sale['currency'] ?? 'USD';
    final notes = sale['notes'] ?? '';

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(customerName.toString().isNotEmpty ? customerName.toString() : 'بيع', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _detailRow('السيارة', '$carMake $carModel'.trim()),
            _detailRow('سعر البيع', '$amount $currency'),
            _detailRow('التاريخ', date.toString().split('T').first),
            _detailRow('العملة', currency.toString()),
            _detailRow('ملاحظات', notes.toString()),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showEditDialog(sale); }, icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(width: 10),
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _confirmDelete(sale['_id']?.toString() ?? sale['id']?.toString() ?? '', customerName.toString()); },
                icon: const Icon(Icons.delete, size: 18), label: const Text('حذف'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
          ]),
        )),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty || value == '-' || value == 'null') return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }

  void _showActions(Map<String, dynamic> sale) {
    final id = sale['_id']?.toString() ?? sale['id']?.toString();
    if (id == null || id.isEmpty) return;
    final customerName = sale['customer_name'] ?? sale['customerName'] ?? sale['buyer_name'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showEditDialog(sale); }),
        ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _confirmDelete(id, customerName.toString()); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  void _showAddDialog() {
    final customerC = TextEditingController();
    final makeC = TextEditingController();
    final modelC = TextEditingController();
    final priceC = TextEditingController();
    final dateC = TextEditingController(text: DateTime.now().toString().split(' ').first);
    final notesC = TextEditingController();
    String currency = 'USD';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة عملية بيع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(customerC, 'اسم العميل', Icons.person_outline),
        _input(makeC, 'الشركة المصنعة', Icons.directions_car),
        _input(modelC, 'الموديل', Icons.model_training),
        _input(priceC, 'سعر البيع', Icons.attach_money, keyboard: TextInputType.number),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
          value: currency,
          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setS(() => currency = v!),
          decoration: InputDecoration(labelText: 'العملة', prefixIcon: const Icon(Icons.currency_exchange, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
        )),
        _inputDate(dateC, 'التاريخ', Icons.calendar_today),
        _input(notesC, 'ملاحظات', Icons.notes),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (customerC.text.trim().isEmpty && makeC.text.trim().isEmpty) return;
          Navigator.pop(ctx);
          try {
            await _ds.createSale(_token, {
              'customer_name': customerC.text.trim(),
              'car_make': makeC.text.trim(),
              'car_model': modelC.text.trim(),
              'selling_price': double.tryParse(priceC.text.trim()) ?? 0,
              'currency': currency,
              'date': dateC.text.trim(),
              if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
            });
            _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة عملية البيع'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة عملية البيع'), backgroundColor: AppColors.error));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _showEditDialog(Map<String, dynamic> sale) {
    final id = sale['_id']?.toString() ?? sale['id']?.toString();
    if (id == null || id.isEmpty) return;

    final customerC = TextEditingController(text: sale['customer_name'] ?? sale['customerName'] ?? sale['buyer_name'] ?? '');
    final makeC = TextEditingController(text: sale['car_make'] ?? sale['make'] ?? '');
    final modelC = TextEditingController(text: sale['car_model'] ?? sale['model'] ?? '');
    final priceC = TextEditingController(text: '${sale['selling_price'] ?? sale['sellingPrice'] ?? sale['amount'] ?? sale['total'] ?? ''}');
    final rawDate = (sale['date'] ?? sale['sale_date'] ?? sale['created_at'] ?? '').toString();
    final dateC = TextEditingController(text: rawDate.split('T').first);
    final notesC = TextEditingController(text: sale['notes'] ?? '');
    String currency = (sale['currency'] ?? 'USD').toString();
    if (!_currencies.contains(currency)) currency = 'USD';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل عملية البيع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(customerC, 'اسم العميل', Icons.person_outline),
        _input(makeC, 'الشركة المصنعة', Icons.directions_car),
        _input(modelC, 'الموديل', Icons.model_training),
        _input(priceC, 'سعر البيع', Icons.attach_money, keyboard: TextInputType.number),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
          value: currency,
          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setS(() => currency = v!),
          decoration: InputDecoration(labelText: 'العملة', prefixIcon: const Icon(Icons.currency_exchange, size: 20), filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
        )),
        _inputDate(dateC, 'التاريخ', Icons.calendar_today),
        _input(notesC, 'ملاحظات', Icons.notes),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            await _ds.updateSale(_token, id, {
              'customer_name': customerC.text.trim(),
              'car_make': makeC.text.trim(),
              'car_model': modelC.text.trim(),
              'selling_price': double.tryParse(priceC.text.trim()) ?? 0,
              'currency': currency,
              'date': dateC.text.trim(),
              'notes': notesC.text.trim(),
            });
            _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل عملية البيع'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تعديل عملية البيع'), backgroundColor: AppColors.error));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _confirmDelete(String id, String name) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف عملية البيع', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('هل تريد حذف ${name.isNotEmpty ? '"$name"' : 'هذه العملية'} نهائياً؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            await _ds.deleteSale(_token, id);
            _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف عملية البيع'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف عملية البيع'), backgroundColor: AppColors.error));
          }
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

  Widget _inputDate(TextEditingController c, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, readOnly: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: DateTime.tryParse(c.text) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)), child: child!));
        if (picked != null) c.text = picked.toString().split(' ').first;
      },
    ),
  );
}
