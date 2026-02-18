import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _currencies = [];
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
      final currencies = await _ds.getCurrencies(_token);
      if (!mounted) return;
      setState(() { _currencies = currencies; _applyFilter(); _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل العملات'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) { _filtered = List.from(_currencies); } else {
      _filtered = _currencies.where((c) {
        final code = (c['code'] ?? '').toString().toLowerCase();
        final name = (c['name'] ?? '').toString().toLowerCase();
        final nameAr = (c['name_ar'] ?? c['nameAr'] ?? '').toString().toLowerCase();
        final symbol = (c['symbol'] ?? '').toString().toLowerCase();
        return code.contains(q) || name.contains(q) || nameAr.contains(q) || symbol.contains(q);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('العملات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.currenciesPage),
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
                hintText: 'بحث عن عملة...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                filled: true, fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
            child: Text('${_filtered.length} عملة', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
          const Divider(height: 1),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
                : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.currency_exchange_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد عملات', style: TextStyle(color: AppColors.textGray))]))
                : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData,
                    child: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length, itemBuilder: (ctx, i) => _buildCurrencyCard(_filtered[i]))),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard(Map<String, dynamic> currency) {
    final code = currency['code'] ?? '';
    final name = currency['name'] ?? '';
    final nameAr = currency['name_ar'] ?? currency['nameAr'] ?? '';
    final symbol = currency['symbol'] ?? '';
    final exchangeRate = currency['exchange_rate'] ?? currency['exchangeRate'] ?? 1;
    final isDefault = currency['is_default'] ?? currency['isDefault'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCurrencyDetails(currency),
        onLongPress: () => _showActions(currency),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(symbol.toString().isNotEmpty ? symbol.toString() : '\$', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$code ${nameAr.toString().isNotEmpty ? '- $nameAr' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              if (name.toString().isNotEmpty) ...[const Icon(Icons.language, size: 12, color: AppColors.textMuted), const SizedBox(width: 3), Flexible(child: Text(name.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)), const SizedBox(width: 8)],
              const Icon(Icons.swap_horiz, size: 12, color: AppColors.textMuted), const SizedBox(width: 3), Text('$exchangeRate', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (isDefault == true || isDefault.toString() == 'true') Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: const Text('افتراضي', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)))
            else Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.textMuted.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(code.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
            const SizedBox(height: 4),
            Text('$symbol $exchangeRate', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ]),
        ])),
      ),
    );
  }

  void _showActions(Map<String, dynamic> currency) {
    final id = currency['_id'] ?? currency['id'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showEditDialog(currency); }),
        ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _confirmDelete(id); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  void _showAddDialog() {
    final codeC = TextEditingController(); final nameC = TextEditingController(); final nameArC = TextEditingController();
    final symbolC = TextEditingController(); final exchangeRateC = TextEditingController(text: '1'); bool isDefault = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة عملة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(codeC, 'رمز العملة (مثل USD)', Icons.code), _input(nameC, 'الاسم بالإنجليزي', Icons.language),
        _input(nameArC, 'الاسم بالعربي', Icons.text_fields), _input(symbolC, 'الرمز (مثل \$)', Icons.attach_money),
        _input(exchangeRateC, 'سعر الصرف', Icons.swap_horiz, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: SwitchListTile(
          title: const Text('عملة افتراضية', style: TextStyle(fontSize: 14)), value: isDefault,
          onChanged: (v) => setS(() => isDefault = v), activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero, dense: true,
        )),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (codeC.text.trim().isEmpty) return; Navigator.pop(ctx);
          try { await _ds.createCurrency(_token, {'code': codeC.text.trim().toUpperCase(), 'name': nameC.text.trim(), 'name_ar': nameArC.text.trim(), 'symbol': symbolC.text.trim(),
            'exchange_rate': double.tryParse(exchangeRateC.text.trim()) ?? 1, 'is_default': isDefault}); _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة العملة'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الإضافة'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _showEditDialog(Map<String, dynamic> currency) {
    final id = currency['_id'] ?? currency['id'] ?? '';
    final codeC = TextEditingController(text: currency['code'] ?? ''); final nameC = TextEditingController(text: currency['name'] ?? '');
    final nameArC = TextEditingController(text: currency['name_ar'] ?? currency['nameAr'] ?? '');
    final symbolC = TextEditingController(text: currency['symbol'] ?? '');
    final exchangeRateC = TextEditingController(text: '${currency['exchange_rate'] ?? currency['exchangeRate'] ?? 1}');
    bool isDefault = currency['is_default'] ?? currency['isDefault'] ?? false;
    if (isDefault is! bool) isDefault = isDefault.toString() == 'true';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل العملة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(codeC, 'رمز العملة (مثل USD)', Icons.code), _input(nameC, 'الاسم بالإنجليزي', Icons.language),
        _input(nameArC, 'الاسم بالعربي', Icons.text_fields), _input(symbolC, 'الرمز (مثل \$)', Icons.attach_money),
        _input(exchangeRateC, 'سعر الصرف', Icons.swap_horiz, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: SwitchListTile(
          title: const Text('عملة افتراضية', style: TextStyle(fontSize: 14)), value: isDefault,
          onChanged: (v) => setS(() => isDefault = v), activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero, dense: true,
        )),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _ds.updateCurrency(_token, id, {'code': codeC.text.trim().toUpperCase(), 'name': nameC.text.trim(), 'name_ar': nameArC.text.trim(), 'symbol': symbolC.text.trim(),
            'exchange_rate': double.tryParse(exchangeRateC.text.trim()) ?? 1, 'is_default': isDefault}); _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل التعديل'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف العملة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذه العملة نهائياً؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _ds.deleteCurrency(_token, id); _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success)); }
          catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error)); }
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

  void _showCurrencyDetails(Map<String, dynamic> currency) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('${currency['code'] ?? ''} - ${currency['name_ar'] ?? currency['nameAr'] ?? currency['name'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ..._detailRows(currency),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showEditDialog(currency); }, icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(width: 10),
              ElevatedButton.icon(onPressed: () { Navigator.pop(context); _confirmDelete(currency['_id'] ?? currency['id'] ?? ''); }, icon: const Icon(Icons.delete, size: 18), label: const Text('حذف'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
            ]),
          ]),
        )),
      ),
    );
  }

  List<Widget> _detailRows(Map<String, dynamic> currency) {
    final isDefault = currency['is_default'] ?? currency['isDefault'] ?? false;
    final fields = <MapEntry<String, String>>[
      MapEntry('رمز العملة', '${currency['code'] ?? '-'}'), MapEntry('الاسم بالإنجليزي', '${currency['name'] ?? '-'}'),
      MapEntry('الاسم بالعربي', '${currency['name_ar'] ?? currency['nameAr'] ?? '-'}'), MapEntry('الرمز', '${currency['symbol'] ?? '-'}'),
      MapEntry('سعر الصرف', '${currency['exchange_rate'] ?? currency['exchangeRate'] ?? '-'}'),
      MapEntry('عملة افتراضية', (isDefault == true || isDefault.toString() == 'true') ? 'نعم' : 'لا'),
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
