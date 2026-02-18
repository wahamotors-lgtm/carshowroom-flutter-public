import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

// Category helpers
const Map<String, String> _categoryLabels = {
  'shipping': 'شحن',
  'customs': 'جمارك',
  'transport': 'نقل',
  'loading': 'تحميل',
  'clearance': 'تخليص',
  'port_fees': 'رسوم ميناء',
  'government': 'رسوم حكومية',
  'car_expense': 'مصروف سيارة',
  'other': 'أخرى',
};

Color _categoryColor(String? category) {
  switch (category) {
    case 'shipping': return const Color(0xFF2563EB);
    case 'customs': return const Color(0xFFD97706);
    case 'transport': return const Color(0xFF7C3AED);
    case 'loading': return const Color(0xFF0891B2);
    case 'clearance': return const Color(0xFFDB2777);
    case 'port_fees': return const Color(0xFF0D9488);
    case 'government': return const Color(0xFFDC2626);
    case 'car_expense': return const Color(0xFFEA580C);
    case 'other':
    default: return const Color(0xFF64748B);
  }
}

String _categoryLabel(String? category) {
  if (category == null || category.isEmpty) return 'أخرى';
  return _categoryLabels[category] ?? category;
}

class OrphanedExpensesScreen extends StatefulWidget {
  const OrphanedExpensesScreen({super.key});
  @override
  State<OrphanedExpensesScreen> createState() => _OrphanedExpensesScreenState();
}

class _OrphanedExpensesScreenState extends State<OrphanedExpensesScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _allExpenses = [];
  List<Map<String, dynamic>> _orphaned = [];
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _containers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadData();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _ds.getExpenses(_token),
        _ds.getCars(_token),
        _ds.getContainers(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _allExpenses = results[0];
        _cars = results[1];
        _containers = results[2];
        _filterOrphaned();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  void _filterOrphaned() {
    _orphaned = _allExpenses.where((exp) {
      final carId = exp['car_id']?.toString() ?? exp['carId']?.toString() ?? '';
      final containerId = exp['container_id']?.toString() ?? exp['containerId']?.toString() ?? '';
      final shipmentId = exp['shipment_id']?.toString() ?? exp['shipmentId']?.toString() ?? '';
      return carId.isEmpty && containerId.isEmpty && shipmentId.isEmpty;
    }).toList();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double get _totalOrphanedAmount {
    double total = 0;
    for (final exp in _orphaned) {
      total += _parseDouble(exp['amount'] ?? 0);
    }
    return total;
  }

  void _showReassignDialog(Map<String, dynamic> expense) {
    final id = (expense['id'] ?? expense['_id'])?.toString();
    if (id == null || id.isEmpty) return;

    String? selectedCarId;
    String? selectedContainerId;
    String assignTo = 'car'; // 'car' or 'container'

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إعادة تعيين المصروف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show expense info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense['description']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const SizedBox(height: 4),
                        Text('${_parseDouble(expense['amount'] ?? 0).toStringAsFixed(2)} ${expense['currency'] ?? 'USD'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Toggle car/container
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setS(() { assignTo = 'car'; selectedContainerId = null; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: assignTo == 'car' ? AppColors.primary : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Text('سيارة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: assignTo == 'car' ? Colors.white : AppColors.textGray))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setS(() { assignTo = 'container'; selectedCarId = null; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: assignTo == 'container' ? AppColors.primary : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Text('حاوية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: assignTo == 'container' ? Colors.white : AppColors.textGray))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (assignTo == 'car') ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedCarId,
                      decoration: InputDecoration(
                        labelText: 'اختر السيارة',
                        prefixIcon: const Icon(Icons.directions_car, size: 20),
                        filled: true,
                        fillColor: AppColors.bgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: _cars.map((car) {
                        final carId = (car['id'] ?? car['_id'])?.toString() ?? '';
                        final make = car['make'] ?? car['brand'] ?? '';
                        final model = car['model'] ?? '';
                        final year = car['year'] ?? '';
                        return DropdownMenuItem(value: carId, child: Text('$make $model ($year)', style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) => setS(() => selectedCarId = v),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedContainerId,
                      decoration: InputDecoration(
                        labelText: 'اختر الحاوية',
                        prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                        filled: true,
                        fillColor: AppColors.bgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      items: _containers.map((container) {
                        final cId = (container['id'] ?? container['_id'])?.toString() ?? '';
                        final name = container['name'] ?? container['container_number'] ?? container['containerNumber'] ?? 'حاوية $cId';
                        return DropdownMenuItem(value: cId, child: Text(name.toString(), style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) => setS(() => selectedContainerId = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final body = <String, dynamic>{};
                if (assignTo == 'car' && selectedCarId != null && selectedCarId!.isNotEmpty) {
                  body['car_id'] = int.tryParse(selectedCarId!) ?? selectedCarId;
                } else if (assignTo == 'container' && selectedContainerId != null && selectedContainerId!.isNotEmpty) {
                  body['container_id'] = int.tryParse(selectedContainerId!) ?? selectedContainerId;
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى اختيار عنصر'), backgroundColor: AppColors.error));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _ds.updateExpense(_token, id, body);
                  _loadData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إعادة التعيين بنجاح'), backgroundColor: AppColors.success));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إعادة التعيين'), backgroundColor: AppColors.error));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف المصروف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('هل تريد حذف "$description" نهائياً؟', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _ds.deleteExpense(_token, id);
                _loadData();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showActions(Map<String, dynamic> expense) {
    final id = (expense['id'] ?? expense['_id'])?.toString() ?? '';
    final description = expense['description']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.primary),
                title: const Text('إعادة تعيين'),
                subtitle: const Text('ربط المصروف بسيارة أو حاوية', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                onTap: () { Navigator.pop(context); _showReassignDialog(expense); },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('حذف', style: TextStyle(color: AppColors.error)),
                onTap: () { Navigator.pop(context); _confirmDelete(id, description); },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مصاريف غير مربوطة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.orphanedExpenses),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Summary card
                      SliverToBoxAdapter(child: _buildSummaryCard()),
                      // Info notice
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('هذه المصاريف غير مرتبطة بأي سيارة أو حاوية أو شحنة. اضغط مطولاً لإعادة تعيينها أو حذفها.', style: TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.4))),
                            ],
                          ),
                        ),
                      ),
                      // Count
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: Colors.white,
                          child: Text('${_orphaned.length} مصروف غير مربوط', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SliverToBoxAdapter(child: Divider(height: 1)),
                      // List
                      _orphaned.isEmpty
                          ? SliverFillRemaining(
                              child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
                                SizedBox(height: 12),
                                Text('لا توجد مصاريف غير مربوطة', style: TextStyle(color: AppColors.textGray, fontSize: 14)),
                                SizedBox(height: 4),
                                Text('جميع المصاريف مرتبطة بشكل صحيح', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ])),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildExpenseCard(_orphaned[i]),
                                childCount: _orphaned.length,
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.link_off, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إجمالي المصاريف غير المربوطة', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '\$${_totalOrphanedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Text('${_orphaned.length}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final description = expense['description']?.toString() ?? '';
    final amount = _parseDouble(expense['amount'] ?? 0);
    final currency = expense['currency']?.toString() ?? 'USD';
    final category = expense['category']?.toString();
    final date = (expense['expense_date'] ?? expense['expenseDate'] ?? expense['date'] ?? '').toString();
    final notes = expense['notes']?.toString() ?? '';
    final catColor = _categoryColor(category);
    final catLabel = _categoryLabel(category);

    return GestureDetector(
      onLongPress: () => _showActions(expense),
      onTap: () => _showActions(expense),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          border: Border.all(color: const Color(0xFFFEE2E2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Category + description + amount
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: catColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(catLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: catColor)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text('${amount.toStringAsFixed(2)} $currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: catColor)),
                ],
              ),
              const SizedBox(height: 6),
              // Row 2: Date + unlinked badge
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    date.length >= 10 ? date.substring(0, 10) : date,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_off, size: 10, color: AppColors.error),
                        SizedBox(width: 3),
                        Text('غير مربوط', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(notes, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
