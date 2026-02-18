import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _filterType = 'all'; // all, in, out

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getPayments(_token);
      if (!mounted) return;
      setState(() {
        _payments = data;
        _isLoading = false;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'فشل تحميل المدفوعات';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _payments.where((p) {
        // Type filter
        if (_filterType != 'all') {
          final type = (p['type'] ?? p['payment_type'] ?? '').toString().toLowerCase();
          if (_filterType == 'in' && !['income', 'received', 'in'].contains(type)) return false;
          if (_filterType == 'out' && !['expense', 'paid', 'out'].contains(type)) return false;
        }

        // Search filter
        if (query.isEmpty) return true;
        final desc = (p['description'] ?? p['reference'] ?? '').toString().toLowerCase();
        final amount = (p['amount'] ?? '').toString();
        final currency = (p['currency'] ?? '').toString().toLowerCase();
        final method = (p['method'] ?? p['payment_method'] ?? '').toString().toLowerCase();
        final date = (p['date'] ?? p['payment_date'] ?? p['created_at'] ?? '').toString().toLowerCase();
        return desc.contains(query) || amount.contains(query) || currency.contains(query) || method.contains(query) || date.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدفوعات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.paymentsPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'بحث في المدفوعات...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); _applyFilter(); })
                    : null,
                filled: true,
                fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                _filterChip('الكل', 'all'),
                const SizedBox(width: 6),
                _filterChip('وارد', 'in'),
                const SizedBox(width: 6),
                _filterChip('صادر', 'out'),
                const Spacer(),
                if (!_isLoading)
                  Text('${_filtered.length} دفعة', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ]))
                    : _filtered.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.payment_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty || _filterType != 'all' ? 'لا توجد نتائج' : 'لا توجد مدفوعات',
                              style: const TextStyle(color: AppColors.textGray),
                            ),
                          ]))
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterType = value);
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.bgLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppColors.textMuted,
        )),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'income': case 'received': case 'in': return 'وارد';
      case 'expense': case 'paid': case 'out': return 'صادر';
      default: return type.isNotEmpty ? type : 'دفعة';
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'income': case 'received': case 'in': return AppColors.success;
      case 'expense': case 'paid': case 'out': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  bool _isIncoming(String type) {
    return ['income', 'received', 'in'].contains(type.toLowerCase());
  }

  Widget _buildCard(Map<String, dynamic> payment) {
    final description = (payment['description'] ?? payment['reference'] ?? '').toString();
    final amount = payment['amount'] ?? 0;
    final currency = (payment['currency'] ?? 'USD').toString();
    final date = (payment['date'] ?? payment['payment_date'] ?? payment['created_at'] ?? '').toString();
    final type = (payment['type'] ?? payment['payment_type'] ?? '').toString();
    final method = (payment['method'] ?? payment['payment_method'] ?? '').toString();

    final typeColor = _getTypeColor(type);
    final typeLabel = _getTypeLabel(type);

    return GestureDetector(
      onTap: () => _showDetails(payment),
      onLongPress: () => _showActions(payment),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(
              _isIncoming(type) ? Icons.arrow_downward : Icons.arrow_upward,
              color: typeColor, size: 22,
            ),
          ),
          title: Text(
            description.isNotEmpty ? description : typeLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (method.isNotEmpty) Text(method, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            if (date.isNotEmpty) Text(date.split('T').first, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ]),
          trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$amount $currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: typeColor)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: typeColor)),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> payment) {
    final description = (payment['description'] ?? payment['reference'] ?? '').toString();
    final amount = payment['amount'] ?? 0;
    final currency = (payment['currency'] ?? 'USD').toString();
    final date = (payment['date'] ?? payment['payment_date'] ?? payment['created_at'] ?? '').toString();
    final type = (payment['type'] ?? payment['payment_type'] ?? '').toString();
    final method = (payment['method'] ?? payment['payment_method'] ?? '').toString();
    final notes = (payment['notes'] ?? '').toString();
    final accountId = (payment['account_id'] ?? payment['accountId'] ?? '').toString();
    final debitAccount = (payment['debit_account_id'] ?? payment['debitAccountId'] ?? '').toString();
    final creditAccount = (payment['credit_account_id'] ?? payment['creditAccountId'] ?? '').toString();
    final customerId = (payment['customer_id'] ?? payment['customerId'] ?? '').toString();
    final carId = (payment['car_id'] ?? payment['carId'] ?? '').toString();
    final createdAt = (payment['created_at'] ?? payment['createdAt'] ?? '').toString();

    final typeColor = _getTypeColor(type);
    final typeLabel = _getTypeLabel(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),

            // Header
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(_isIncoming(type) ? Icons.arrow_downward : Icons.arrow_upward, color: typeColor, size: 28),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              '$amount $currency',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: typeColor),
            ),
            const SizedBox(height: 4),
            Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(typeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: typeColor)),
            )),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // Details
            if (description.isNotEmpty) _detailRow('الوصف', description, Icons.description_outlined),
            if (method.isNotEmpty) _detailRow('طريقة الدفع', method, Icons.credit_card_outlined),
            if (date.isNotEmpty) _detailRow('التاريخ', date.split('T').first, Icons.calendar_today_outlined),
            if (accountId.isNotEmpty) _detailRow('الحساب', accountId, Icons.account_balance_outlined),
            if (debitAccount.isNotEmpty) _detailRow('حساب المدين', debitAccount, Icons.arrow_circle_up_outlined),
            if (creditAccount.isNotEmpty) _detailRow('حساب الدائن', creditAccount, Icons.arrow_circle_down_outlined),
            if (customerId.isNotEmpty) _detailRow('العميل', customerId, Icons.person_outline),
            if (carId.isNotEmpty) _detailRow('السيارة', carId, Icons.directions_car_outlined),
            if (notes.isNotEmpty) _detailRow('ملاحظات', notes, Icons.notes_outlined),
            if (createdAt.isNotEmpty) _detailRow('تاريخ الإنشاء', createdAt.split('T').first, Icons.access_time),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () { Navigator.pop(context); _showEditDialog(payment); },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('تعديل', style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _confirmDelete(payment); },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark))),
      ]),
    );
  }

  void _showActions(Map<String, dynamic> payment) {
    final description = (payment['description'] ?? payment['reference'] ?? '').toString();
    final typeLabel = _getTypeLabel((payment['type'] ?? payment['payment_type'] ?? '').toString());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Text(description.isNotEmpty ? description : typeLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const Divider(height: 20),
          ListTile(
            leading: const Icon(Icons.visibility_outlined, color: AppColors.primary),
            title: const Text('عرض التفاصيل', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _showDetails(payment); },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.orange),
            title: const Text('تعديل', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () { Navigator.pop(context); _showEditDialog(payment); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
            onTap: () { Navigator.pop(context); _confirmDelete(payment); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showAddDialog() {
    _showPaymentDialog(null);
  }

  void _showEditDialog(Map<String, dynamic> payment) {
    _showPaymentDialog(payment);
  }

  void _showPaymentDialog(Map<String, dynamic>? payment) {
    final isEdit = payment != null;
    final descC = TextEditingController(text: isEdit ? (payment['description'] ?? payment['reference'] ?? '').toString() : '');
    final amountC = TextEditingController(text: isEdit ? (payment['amount'] ?? '').toString() : '');
    final notesC = TextEditingController(text: isEdit ? (payment['notes'] ?? '').toString() : '');
    final methodC = TextEditingController(text: isEdit ? (payment['method'] ?? payment['payment_method'] ?? '').toString() : '');
    String currency = isEdit ? (payment['currency'] ?? 'USD').toString() : 'USD';
    String type = isEdit ? (payment['type'] ?? payment['payment_type'] ?? 'out').toString() : 'out';
    if (!['in', 'out', 'income', 'expense', 'received', 'paid'].contains(type.toLowerCase())) type = 'out';
    // Normalize type
    if (['income', 'received'].contains(type.toLowerCase())) type = 'in';
    if (['expense', 'paid'].contains(type.toLowerCase())) type = 'out';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'تعديل دفعة' : 'إضافة دفعة',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _input(descC, 'الوصف / المرجع', Icons.description_outlined),
          _input(amountC, 'المبلغ', Icons.attach_money, keyboard: TextInputType.number),
          Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
            value: currency,
            items: ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY', 'EUR', 'TRY'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setDialogState(() => currency = v!),
            decoration: InputDecoration(labelText: 'العملة', prefixIcon: const Icon(Icons.currency_exchange, size: 20), filled: true, fillColor: AppColors.bgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          )),
          Padding(padding: const EdgeInsets.only(bottom: 10), child: DropdownButtonFormField<String>(
            value: type,
            items: const [
              DropdownMenuItem(value: 'out', child: Text('صادر (مصروف)')),
              DropdownMenuItem(value: 'in', child: Text('وارد (إيراد)')),
            ],
            onChanged: (v) => setDialogState(() => type = v!),
            decoration: InputDecoration(labelText: 'النوع', prefixIcon: const Icon(Icons.swap_vert, size: 20), filled: true, fillColor: AppColors.bgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          )),
          _input(methodC, 'طريقة الدفع', Icons.credit_card_outlined),
          _input(notesC, 'ملاحظات', Icons.notes_outlined),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (amountC.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final body = {
                'description': descC.text.trim(),
                'amount': double.tryParse(amountC.text.trim()) ?? 0,
                'currency': currency,
                'type': type,
                if (methodC.text.trim().isNotEmpty) 'method': methodC.text.trim(),
                if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
              };
              try {
                if (isEdit) {
                  final id = (payment['id'] ?? payment['_id'] ?? '').toString();
                  await _ds.updatePayment(_token, id, body);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تعديل الدفعة بنجاح'), backgroundColor: AppColors.success),
                    );
                  }
                } else {
                  await _ds.createPayment(_token, body);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة الدفعة بنجاح'), backgroundColor: AppColors.success),
                    );
                  }
                }
                _load();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e is ApiException ? e.message : 'فشلت العملية'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isEdit ? 'تعديل' : 'إضافة', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      )),
    );
  }

  void _confirmDelete(Map<String, dynamic> payment) {
    final description = (payment['description'] ?? payment['reference'] ?? '').toString();
    final amount = payment['amount'] ?? 0;
    final currency = (payment['currency'] ?? 'USD').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد الحذف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('هل أنت متأكد من حذف هذه الدفعة؟', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (description.isNotEmpty)
            Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text('$amount $currency', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.error)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final id = (payment['id'] ?? payment['_id'] ?? '').toString();
                await _ds.deletePayment(_token, id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف الدفعة بنجاح'), backgroundColor: AppColors.success),
                  );
                }
                _load();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e is ApiException ? e.message : 'فشل حذف الدفعة'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
  );
}
