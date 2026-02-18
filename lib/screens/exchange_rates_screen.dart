import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ExchangeRatesScreen extends StatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  State<ExchangeRatesScreen> createState() => _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends State<ExchangeRatesScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _rates = [];
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
      final rates = await _ds.getExchangeRateHistory(_token);
      if (!mounted) return;
      setState(() { _rates = rates; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل أسعار الصرف'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) { _filtered = List.from(_rates); } else {
      _filtered = _rates.where((r) {
        final code = (r['currency_code'] ?? r['currencyCode'] ?? '').toString().toLowerCase();
        final rate = (r['rate'] ?? '').toString();
        final date = (r['date'] ?? '').toString();
        return code.contains(q) || rate.contains(q) || date.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أسعار الصرف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.exchangeRatesPage),
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
                hintText: 'بحث برمز العملة...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                filled: true, fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
            child: Text('${_filtered.length} سعر صرف', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          const Divider(height: 1),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
                : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.currency_exchange_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد أسعار صرف', style: TextStyle(color: AppColors.textGray))]))
                : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData,
                    child: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length, itemBuilder: (ctx, i) => _buildRateCard(_filtered[i]))),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(Map<String, dynamic> rate) {
    final code = (rate['currency_code'] ?? rate['currencyCode'] ?? '').toString();
    final rateValue = (rate['rate'] ?? '').toString();
    final date = (rate['date'] ?? '').toString();

    String displayDate = date;
    if (date.isNotEmpty && date.length >= 10) {
      displayDate = date.substring(0, 10);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRateDetails(rate),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.currency_exchange, color: AppColors.primary, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted), const SizedBox(width: 3),
              Text(displayDate, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(rateValue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary))),
          ]),
        ])),
      ),
    );
  }

  void _showAddDialog() {
    final codeC = TextEditingController();
    final rateC = TextEditingController();
    final dateC = TextEditingController(text: DateTime.now().toString().substring(0, 10));

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة سعر صرف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(codeC, 'رمز العملة', Icons.monetization_on_outlined),
        _input(rateC, 'سعر الصرف', Icons.trending_up, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(
          controller: dateC, readOnly: true,
          onTap: () async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: DateTime.tryParse(dateC.text) ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)), child: child!),
            );
            if (picked != null) {
              setS(() => dateC.text = picked.toString().substring(0, 10));
            }
          },
          decoration: InputDecoration(
            labelText: 'التاريخ', prefixIcon: const Icon(Icons.calendar_today, size: 20),
            suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
            filled: true, fillColor: AppColors.bgLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        )),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (codeC.text.trim().isEmpty || rateC.text.trim().isEmpty) return; Navigator.pop(ctx);
          try { await _ds.createExchangeRate(_token, {'currency_code': codeC.text.trim(), 'rate': double.tryParse(rateC.text.trim()) ?? 0, 'date': dateC.text.trim()}); _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة سعر الصرف'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل الإضافة'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _showRateDetails(Map<String, dynamic> rate) {
    final code = (rate['currency_code'] ?? rate['currencyCode'] ?? '').toString();
    final rateValue = (rate['rate'] ?? '').toString();
    final date = (rate['date'] ?? '').toString();

    String displayDate = date;
    if (date.isNotEmpty && date.length >= 10) {
      displayDate = date.substring(0, 10);
    }

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _detailRow('رمز العملة', code),
            _detailRow('سعر الصرف', rateValue),
            _detailRow('التاريخ', displayDate),
            const SizedBox(height: 16),
          ]),
        )),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );
}
