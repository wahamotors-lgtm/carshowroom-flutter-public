import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class DataDeletionScreen extends StatefulWidget {
  const DataDeletionScreen({super.key});
  @override
  State<DataDeletionScreen> createState() => _DataDeletionScreenState();
}

class _DataDeletionScreenState extends State<DataDeletionScreen> {
  late final DataService _ds;
  bool _isDeleting = false;

  // Entity types with selection state
  final List<_EntityType> _entities = [
    _EntityType(key: 'cars', label: 'السيارات', icon: Icons.directions_car_outlined, description: 'جميع بيانات السيارات'),
    _EntityType(key: 'customers', label: 'العملاء', icon: Icons.people_outline, description: 'جميع بيانات العملاء'),
    _EntityType(key: 'sales', label: 'المبيعات', icon: Icons.point_of_sale_outlined, description: 'جميع عمليات البيع'),
    _EntityType(key: 'expenses', label: 'المصاريف', icon: Icons.add_card_outlined, description: 'جميع المصاريف المسجلة'),
    _EntityType(key: 'payments', label: 'المدفوعات', icon: Icons.payment_outlined, description: 'جميع المدفوعات'),
    _EntityType(key: 'containers', label: 'الحاويات', icon: Icons.inventory_2_outlined, description: 'جميع بيانات الحاويات'),
    _EntityType(key: 'shipments', label: 'الشحنات', icon: Icons.local_shipping_outlined, description: 'جميع بيانات الشحنات'),
    _EntityType(key: 'deliveries', label: 'التسليمات', icon: Icons.delivery_dining_outlined, description: 'جميع عمليات التسليم'),
    _EntityType(key: 'suppliers', label: 'الموردين', icon: Icons.store_outlined, description: 'جميع بيانات الموردين'),
    _EntityType(key: 'employees', label: 'الموظفين', icon: Icons.badge_outlined, description: 'جميع بيانات الموظفين'),
    _EntityType(key: 'rentals', label: 'الإيجارات', icon: Icons.home_outlined, description: 'جميع عقود الإيجار'),
    _EntityType(key: 'notes', label: 'الملاحظات', icon: Icons.note_outlined, description: 'جميع الملاحظات'),
    _EntityType(key: 'consignment-cars', label: 'سيارات الأمانة', icon: Icons.car_rental_outlined, description: 'جميع سيارات الأمانة'),
    _EntityType(key: 'air-flights', label: 'الرحلات الجوية', icon: Icons.flight_outlined, description: 'جميع الرحلات الجوية'),
  ];

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  List<_EntityType> get _selectedEntities => _entities.where((e) => e.isSelected).toList();
  bool get _hasSelection => _selectedEntities.isNotEmpty;

  void _toggleAll(bool? value) {
    setState(() {
      for (final e in _entities) {
        e.isSelected = value ?? false;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final selected = _selectedEntities;
    if (selected.isEmpty) return;

    setState(() => _isDeleting = true);

    int successCount = 0;
    int failCount = 0;
    final errors = <String>[];

    for (final entity in selected) {
      try {
        await _ds.syncDeleteEntity(_token, entity.key, {'deleteAll': true});
        successCount++;
      } catch (e) {
        failCount++;
        errors.add('${entity.label}: ${e is ApiException ? e.message : 'فشل'}');
      }
    }

    if (!mounted) return;
    setState(() => _isDeleting = false);

    // Reset selections
    for (final e in _entities) {
      e.isSelected = false;
    }
    setState(() {});

    // Show result
    if (failCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف $successCount نوع بيانات بنجاح'), backgroundColor: AppColors.success),
      );
    } else {
      _showDeleteResultDialog(successCount, failCount, errors);
    }
  }

  void _showDeleteResultDialog(int successCount, int failCount, List<String> errors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('نتيجة الحذف', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (successCount > 0) ...[
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 4),
                  Text('نجح: $successCount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                ],
                if (successCount > 0 && failCount > 0) const SizedBox(width: 16),
                if (failCount > 0) ...[
                  const Icon(Icons.error, color: AppColors.error, size: 20),
                  const SizedBox(width: 4),
                  Text('فشل: $failCount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error)),
                ],
              ],
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(e, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showFirstConfirmation() {
    final selected = _selectedEntities;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار نوع بيانات واحد على الأقل'), backgroundColor: AppColors.error));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 8),
            const Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سيتم حذف البيانات التالية نهائياً:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.red.shade800)),
                  const SizedBox(height: 8),
                  ...selected.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Icon(Icons.remove_circle, size: 14, color: Colors.red.shade700),
                      const SizedBox(width: 6),
                      Text(e.label, style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
                    ]),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'هذا الإجراء لا يمكن التراجع عنه!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.red.shade700),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _showSecondConfirmation(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('متابعة', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSecondConfirmation() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('التأكيد النهائي', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.error)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    const Icon(Icons.dangerous_outlined, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    const Text('هل أنت متأكد تماماً؟', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.error)),
                    const SizedBox(height: 8),
                    Text(
                      'اكتب "حذف" للتأكيد',
                      style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                textAlign: TextAlign.center,
                onChanged: (_) => setS(() {}),
                decoration: InputDecoration(
                  hintText: 'اكتب "حذف" هنا',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.bgLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: confirmController.text.trim() == 'حذف'
                  ? () { Navigator.pop(ctx); _deleteSelected(); }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
              ),
              child: const Text('حذف نهائي', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _entities.every((e) => e.isSelected);
    final noneSelected = _entities.every((e) => !e.isSelected);

    return Scaffold(
      appBar: AppBar(
        title: const Text('حذف البيانات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.dataDeletion),
      body: Column(
        children: [
          // Warning banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.shade50, Colors.red.shade100]),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.dangerous_outlined, size: 24, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('منطقة خطرة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.red.shade700)),
                      const SizedBox(height: 4),
                      Text(
                        'حذف البيانات عملية لا يمكن التراجع عنها. تأكد من إنشاء نسخة احتياطية قبل المتابعة.',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Select all
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Checkbox(
                  value: allSelected ? true : (noneSelected ? false : null),
                  tristate: true,
                  activeColor: AppColors.error,
                  onChanged: (v) => _toggleAll(v == null ? false : v),
                ),
                const Text('تحديد الكل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const Spacer(),
                if (_hasSelection)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('${_selectedEntities.length} محدد', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Entity list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _entities.length,
              itemBuilder: (ctx, i) => _buildEntityTile(_entities[i]),
            ),
          ),
        ],
      ),
      // Delete button
      bottomSheet: _hasSelection
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isDeleting ? null : _showFirstConfirmation,
                  icon: _isDeleting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.delete_forever, size: 22),
                  label: Text(
                    _isDeleting
                        ? 'جاري الحذف...'
                        : 'حذف ${_selectedEntities.length} نوع بيانات',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEntityTile(_EntityType entity) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: entity.isSelected ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entity.isSelected ? AppColors.error.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: entity.isSelected ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: CheckboxListTile(
        value: entity.isSelected,
        activeColor: AppColors.error,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onChanged: (v) => setState(() => entity.isSelected = v ?? false),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: entity.isSelected ? AppColors.error.withValues(alpha: 0.1) : AppColors.bgLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            entity.icon,
            size: 20,
            color: entity.isSelected ? AppColors.error : AppColors.textMuted,
          ),
        ),
        title: Text(
          entity.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: entity.isSelected ? AppColors.error : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          entity.description,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _EntityType {
  final String key;
  final String label;
  final IconData icon;
  final String description;
  bool isSelected;

  _EntityType({
    required this.key,
    required this.label,
    required this.icon,
    required this.description,
    this.isSelected = false,
  });
}
