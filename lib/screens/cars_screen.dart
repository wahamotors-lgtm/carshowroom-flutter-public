import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> with SingleTickerProviderStateMixin {
  late final DataService _ds;
  late final TabController _tabController;
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  int _selectedTabIndex = 0;

  // Related data for dropdowns
  List<Map<String, dynamic>> _containers = [];
  List<Map<String, dynamic>> _shipments = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _sales = [];

  // Status maps
  static const Map<String, String> _statusLabels = {
    'in_korea_warehouse': 'في مستودع كوريا',
    'in_container': 'في الحاوية',
    'shipped': 'في الطريق',
    'arrived': 'وصلت',
    'customs': 'في الجمارك',
    'in_showroom': 'في المعرض',
    'sold': 'مباعة',
    'purchased_local': 'شراء محلي',
  };

  static const Map<String, Color> _statusColors = {
    'in_korea_warehouse': Color(0xFF2563EB),
    'in_container': Color(0xFF7C3AED),
    'shipped': Color(0xFFD97706),
    'arrived': Color(0xFF0891B2),
    'customs': Color(0xFFDB2777),
    'in_showroom': Color(0xFF22C55E),
    'sold': Color(0xFFEF4444),
    'purchased_local': Color(0xFF64748B),
  };

  static const Map<String, IconData> _statusIcons = {
    'in_korea_warehouse': Icons.warehouse_outlined,
    'in_container': Icons.inventory_2_outlined,
    'shipped': Icons.local_shipping_outlined,
    'arrived': Icons.flight_land_outlined,
    'customs': Icons.gavel_outlined,
    'in_showroom': Icons.store_outlined,
    'sold': Icons.sell_outlined,
    'purchased_local': Icons.shopping_cart_outlined,
  };

  static const List<String> _fuelTypes = ['بنزين', 'ديزل', 'هايبرد', 'كهربائي'];
  static const List<String> _currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];
  static const List<String> _paymentMethods = ['كاش', 'تحويل بنكي', 'شيك', 'أقساط', 'دفع إلكتروني'];
  static const List<String> _conditions = ['جديد', 'مستعمل', 'ممتاز', 'جيد جداً', 'جيد', 'مقبول'];
  static const List<String> _expenseCategories = ['شحن', 'جمارك', 'نقل', 'صيانة', 'فحص', 'تأمين', 'رسوم', 'أخرى'];

  // Tab filters
  static const List<List<String>> _tabStatuses = [
    [],
    ['in_korea_warehouse', 'in_container', 'shipped', 'arrived', 'customs'],
    ['in_showroom'],
    ['sold'],
  ];

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() { _selectedTabIndex = _tabController.index; _applyFilter(); });
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _ds.getCars(_token),
        _ds.getContainers(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getShipments(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getWarehouses(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getSuppliers(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getCustomers(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getExpenses(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getSales(_token).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _cars = results[0];
        _containers = results[1];
        _shipments = results[2];
        _warehouses = results[3];
        _suppliers = results[4];
        _customers = results[5];
        _expenses = results[6];
        _sales = results[7];
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل السيارات'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    final tabStatuses = _tabStatuses[_selectedTabIndex];
    _filtered = _cars.where((c) {
      if (tabStatuses.isNotEmpty) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        if (!tabStatuses.contains(status)) return false;
      }
      if (q.isNotEmpty) {
        final make = (c['make'] ?? c['brand'] ?? '').toString().toLowerCase();
        final model = (c['model'] ?? '').toString().toLowerCase();
        final year = (c['year'] ?? '').toString();
        final vin = (c['vin'] ?? '').toString().toLowerCase();
        final stockNumber = (c['stock_number'] ?? '').toString().toLowerCase();
        final color = (c['color'] ?? '').toString().toLowerCase();
        return make.contains(q) || model.contains(q) || year.contains(q) || vin.contains(q) || stockNumber.contains(q) || color.contains(q);
      }
      return true;
    }).toList();
  }

  int _getTabCount(int tabIndex) {
    final tabStatuses = _tabStatuses[tabIndex];
    if (tabStatuses.isEmpty) return _cars.length;
    return _cars.where((c) => tabStatuses.contains((c['status'] ?? '').toString().toLowerCase())).length;
  }

  String _getStatusLabel(String s) => _statusLabels[s] ?? s;
  Color _getStatusColor(String s) => _statusColors[s] ?? AppColors.textMuted;
  IconData _getStatusIcon(String s) => _statusIcons[s] ?? Icons.info_outline;

  // ── Lookup helpers ──
  String _getContainerName(dynamic id) {
    if (id == null) return '';
    return _containers.where((c) => c['id']?.toString() == id.toString() || c['_id']?.toString() == id.toString()).firstOrNull?['container_number']?.toString() ?? '';
  }
  String _getShipmentName(dynamic id) {
    if (id == null) return '';
    return _shipments.where((s) => s['id']?.toString() == id.toString() || s['_id']?.toString() == id.toString()).firstOrNull?['shipment_number']?.toString() ?? '';
  }
  String _getWarehouseName(dynamic id) {
    if (id == null) return '';
    return _warehouses.where((w) => w['id']?.toString() == id.toString() || w['_id']?.toString() == id.toString()).firstOrNull?['name']?.toString() ?? '';
  }
  String _getSupplierName(dynamic id) {
    if (id == null) return '';
    return _suppliers.where((s) => s['id']?.toString() == id.toString() || s['_id']?.toString() == id.toString()).firstOrNull?['name']?.toString() ?? '';
  }
  String _getCustomerName(dynamic id) {
    if (id == null) return '';
    return _customers.where((c) => c['id']?.toString() == id.toString() || c['_id']?.toString() == id.toString()).firstOrNull?['name']?.toString() ?? '';
  }

  List<Map<String, dynamic>> _getCarExpenses(dynamic carId) {
    if (carId == null) return [];
    return _expenses.where((e) => e['car_id']?.toString() == carId.toString()).toList();
  }

  // Get container-shared expenses and calculate per-car share
  double _getContainerShareExpenses(Map<String, dynamic> car) {
    final containerId = car['container_id'];
    if (containerId == null) return 0;
    final containerExpenses = _expenses.where((e) =>
      e['container_id']?.toString() == containerId.toString() && e['car_id'] == null
    ).toList();
    if (containerExpenses.isEmpty) return 0;
    final carsInContainer = _cars.where((c) => c['container_id']?.toString() == containerId.toString()).length;
    if (carsInContainer == 0) return 0;
    double total = 0;
    for (final e in containerExpenses) {
      total += double.tryParse(e['amount']?.toString() ?? '0') ?? 0;
    }
    return total / carsInContainer;
  }

  double _getCarDirectExpenses(dynamic carId) {
    final carExpenses = _getCarExpenses(carId);
    double total = 0;
    for (final e in carExpenses) {
      total += double.tryParse(e['amount']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  double _getCarTotalExpenses(Map<String, dynamic> car) {
    return _getCarDirectExpenses(car['id'] ?? car['_id']) + _getContainerShareExpenses(car);
  }

  double _getCarTotalCost(Map<String, dynamic> car) {
    final purchasePrice = double.tryParse((car['purchase_price'] ?? car['purchasePrice'] ?? '0').toString()) ?? 0;
    return purchasePrice + _getCarTotalExpenses(car);
  }

  // Get sale info for a car
  Map<String, dynamic>? _getCarSale(dynamic carId) {
    if (carId == null) return null;
    return _sales.where((s) => s['car_id']?.toString() == carId.toString()).firstOrNull;
  }

  String _formatPrice(dynamic price, String currency) {
    final num = double.tryParse(price.toString()) ?? 0;
    if (num == 0) return '';
    return '${NumberFormat('#,##0.##').format(num)} $currency';
  }

  // ════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('السيارات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController, isScrollable: false,
          indicatorColor: Colors.white, indicatorWeight: 3,
          labelColor: Colors.white, unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          tabs: [
            Tab(child: _buildTabLabel('الكل', _getTabCount(0))),
            Tab(child: _buildTabLabel('في الطريق', _getTabCount(1))),
            Tab(child: _buildTabLabel('جاهزة للبيع', _getTabCount(2))),
            Tab(child: _buildTabLabel('مباعة', _getTabCount(3))),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.cars),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog, child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Container(
          color: Colors.white, padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController, onChanged: (_) => setState(() => _applyFilter()),
            decoration: InputDecoration(
              hintText: 'بحث بالبراند، الموديل، VIN، رقم المخزون...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
              suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); setState(() => _applyFilter()); }) : null,
              filled: true, fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
          child: Text('${_filtered.length} سيارة', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        const Divider(height: 1),
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null ? _buildError()
              : _filtered.isEmpty ? _buildEmpty()
              : RefreshIndicator(color: AppColors.primary, onRefresh: _loadData,
                  child: ListView.builder(padding: const EdgeInsets.only(bottom: 80), itemCount: _filtered.length, itemBuilder: (ctx, i) => _buildCarCard(_filtered[i]))),
        ),
      ]),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16),
    ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
  ]));

  Widget _buildEmpty() => const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.directions_car_outlined, size: 48, color: AppColors.textMuted), SizedBox(height: 12), Text('لا توجد سيارات', style: TextStyle(color: AppColors.textGray)),
  ]));

  Widget _buildTabLabel(String text, int count) => Row(
    mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      if (count > 0) ...[const SizedBox(width: 4), Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
        child: Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
      )],
    ],
  );

  // ════════════════════════════════════════
  // CAR CARD
  // ════════════════════════════════════════

  Widget _buildCarCard(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final status = (car['status'] ?? '').toString();
    final sellingPrice = car['selling_price'] ?? car['sellingPrice'] ?? car['price'];
    final purchasePrice = car['purchase_price'] ?? car['purchasePrice'];
    final color = car['color'] ?? '';
    final vin = (car['vin'] ?? '').toString();
    final stockNumber = (car['stock_number'] ?? '').toString();
    final containerId = car['container_id'];
    final supplierId = car['supplier_id'];
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final statusIcon = _getStatusIcon(status);
    final displayPrice = sellingPrice != null && sellingPrice.toString().isNotEmpty && sellingPrice.toString() != '0' ? sellingPrice : purchasePrice;
    final priceLabel = sellingPrice != null && sellingPrice.toString().isNotEmpty && sellingPrice.toString() != '0' ? 'بيع' : 'شراء';
    final priceCurrency = car['purchase_currency'] ?? 'USD';
    final containerName = _getContainerName(containerId);
    final supplierName = _getSupplierName(supplierId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCarDetails(car),
        onLongPress: () => _showActions(car),
        child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(statusIcon, color: statusColor, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$make $model ${year != '' ? '($year)' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              if (color.toString().isNotEmpty) ...[const Icon(Icons.palette_outlined, size: 12, color: AppColors.textMuted), const SizedBox(width: 3), Text(color.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)), const SizedBox(width: 8)],
              if (vin.isNotEmpty) Text('VIN: ${vin.length > 8 ? '...${vin.substring(vin.length - 8)}' : vin}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
            if (stockNumber.isNotEmpty || containerName.isNotEmpty || supplierName.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(children: [
                if (stockNumber.isNotEmpty) ...[Icon(Icons.inventory, size: 11, color: Colors.grey.shade400), const SizedBox(width: 2), Text('#$stockNumber', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)), const SizedBox(width: 6)],
                if (containerName.isNotEmpty) ...[Icon(Icons.inventory_2_outlined, size: 11, color: Colors.purple.shade300), const SizedBox(width: 2), Flexible(child: Text(containerName, style: TextStyle(fontSize: 10, color: Colors.purple.shade400), overflow: TextOverflow.ellipsis)), const SizedBox(width: 6)],
                if (supplierName.isNotEmpty) ...[Icon(Icons.business_outlined, size: 11, color: Colors.blue.shade300), const SizedBox(width: 2), Flexible(child: Text(supplierName, style: TextStyle(fontSize: 10, color: Colors.blue.shade400), overflow: TextOverflow.ellipsis))],
              ]),
            ],
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
            if (displayPrice != null && displayPrice.toString().isNotEmpty && displayPrice.toString() != '0') ...[
              const SizedBox(height: 4),
              Text(_formatPrice(displayPrice, priceCurrency), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              Text(priceLabel, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            ],
          ]),
        ])),
      ),
    );
  }

  // ════════════════════════════════════════
  // ACTIONS BOTTOM SHEET
  // ════════════════════════════════════════

  void _showActions(Map<String, dynamic> car) {
    final id = car['_id'] ?? car['id'] ?? '';
    final status = (car['status'] ?? '').toString();
    final isSold = status == 'sold';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 8),
        Text('${car['make'] ?? ''} ${car['model'] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const Divider(),
        ListTile(leading: const Icon(Icons.edit, color: AppColors.primary), title: const Text('تعديل'), onTap: () { Navigator.pop(context); _showEditDialog(car); }),
        ListTile(leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF7C3AED)), title: const Text('تكلفة السيارة'), onTap: () { Navigator.pop(context); _showCostBreakdown(car); }),
        ListTile(leading: const Icon(Icons.add_circle_outline, color: Color(0xFF0891B2)), title: const Text('إضافة مصروف'), onTap: () { Navigator.pop(context); _showAddExpenseDialog(car); }),
        if (car['container_id'] != null)
          ListTile(leading: const Icon(Icons.group_work_outlined, color: Color(0xFF6366F1)), title: const Text('مصروف مشترك (حاوية)'), onTap: () { Navigator.pop(context); _showContainerExpenseDialog(car); }),
        if (!isSold) ...[
          ListTile(leading: const Icon(Icons.swap_horiz, color: Color(0xFFD97706)), title: const Text('تغيير الحالة'), onTap: () { Navigator.pop(context); _showChangeStatusDialog(car); }),
          if (status != 'in_showroom')
            ListTile(leading: const Icon(Icons.store_outlined, color: AppColors.success), title: const Text('نقل للمعرض'), onTap: () { Navigator.pop(context); _changeCarStatus(id.toString(), 'in_showroom'); }),
          ListTile(leading: const Icon(Icons.sell, color: Color(0xFF2563EB)), title: const Text('بيع السيارة'), onTap: () { Navigator.pop(context); _showSellCarDialog(car); }),
        ],
        ListTile(leading: const Icon(Icons.delete, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(context); _confirmDelete(id.toString()); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  // ════════════════════════════════════════
  // CHANGE STATUS
  // ════════════════════════════════════════

  void _showChangeStatusDialog(Map<String, dynamic> car) {
    final id = car['_id'] ?? car['id'] ?? '';
    final currentStatus = (car['status'] ?? '').toString();
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const Padding(padding: EdgeInsets.all(16), child: Text('تغيير حالة السيارة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        const Divider(height: 1),
        ..._statusLabels.entries.map((e) {
          final isSelected = e.key == currentStatus;
          final color = _getStatusColor(e.key);
          return ListTile(
            leading: Icon(_getStatusIcon(e.key), color: color),
            title: Text(e.value, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
            trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
            tileColor: isSelected ? color.withValues(alpha: 0.05) : null,
            onTap: isSelected ? null : () { Navigator.pop(context); _changeCarStatus(id.toString(), e.key); },
          );
        }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  Future<void> _changeCarStatus(String id, String newStatus) async {
    try {
      await _ds.updateCar(_token, id, {'status': newStatus});
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تغيير الحالة إلى ${_getStatusLabel(newStatus)}'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل تغيير الحالة'), backgroundColor: AppColors.error));
    }
  }

  // ════════════════════════════════════════
  // COST BREAKDOWN
  // ════════════════════════════════════════

  void _showCostBreakdown(Map<String, dynamic> car) {
    final carId = car['id'] ?? car['_id'];
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final purchasePrice = double.tryParse((car['purchase_price'] ?? car['purchasePrice'] ?? '0').toString()) ?? 0;
    final purchaseCurrency = car['purchase_currency'] ?? 'USD';
    final carExpenses = _getCarExpenses(carId);
    final directExpenses = _getCarDirectExpenses(carId);
    final containerShare = _getContainerShareExpenses(car);
    final totalExpenses = directExpenses + containerShare;
    final totalCost = purchasePrice + totalExpenses;
    final sellingPrice = double.tryParse((car['selling_price'] ?? car['sellingPrice'] ?? car['price'] ?? '0').toString()) ?? 0;
    final profit = sellingPrice > 0 ? sellingPrice - totalCost : 0.0;

    // Group direct expenses by category
    final Map<String, double> expensesByCategory = {};
    for (final e in carExpenses) {
      final category = e['category']?.toString() ?? 'أخرى';
      final amount = double.tryParse(e['amount']?.toString() ?? '0') ?? 0;
      expensesByCategory[category] = (expensesByCategory[category] ?? 0) + amount;
    }

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Icon(Icons.receipt_long, size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text('تكلفة $make $model', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
            ])),
            const Divider(height: 1),
            Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.all(20), children: [
              _costRow('سعر الشراء', purchasePrice, purchaseCurrency, Icons.shopping_cart_outlined, AppColors.primary),
              const SizedBox(height: 12),

              if (carExpenses.isNotEmpty) ...[
                const Text('المصاريف المباشرة:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 8),
                ...expensesByCategory.entries.map((e) => _costRow(e.key, e.value, purchaseCurrency, Icons.receipt_outlined, const Color(0xFFD97706))),
                const SizedBox(height: 4),
                _costRow('إجمالي المصاريف المباشرة', directExpenses, purchaseCurrency, Icons.calculate_outlined, const Color(0xFFEF4444)),
                const SizedBox(height: 12),
              ],

              if (containerShare > 0) ...[
                const Text('حصة مصاريف الحاوية:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 8),
                _costRow('حصة من مصاريف الحاوية', containerShare, purchaseCurrency, Icons.group_work_outlined, const Color(0xFF6366F1)),
                const SizedBox(height: 12),
              ],

              if (totalExpenses > 0) ...[
                _costRow('إجمالي كل المصاريف', totalExpenses, purchaseCurrency, Icons.summarize_outlined, const Color(0xFFEF4444), bold: true),
                const SizedBox(height: 12),
              ],

              Container(height: 2, decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(1))),
              const SizedBox(height: 12),
              _costRow('التكلفة الإجمالية', totalCost, purchaseCurrency, Icons.account_balance_wallet_outlined, const Color(0xFF7C3AED), bold: true),
              const SizedBox(height: 8),

              if (sellingPrice > 0) ...[
                _costRow('سعر البيع', sellingPrice, purchaseCurrency, Icons.sell_outlined, const Color(0xFF2563EB)),
                const SizedBox(height: 8),
                _costRow(profit >= 0 ? 'الربح المتوقع' : 'الخسارة المتوقعة', profit.abs(), purchaseCurrency,
                    profit >= 0 ? Icons.trending_up : Icons.trending_down,
                    profit >= 0 ? AppColors.success : AppColors.error, bold: true),
              ],

              if (carExpenses.isEmpty && containerShare == 0) ...[
                const SizedBox(height: 20),
                Center(child: Column(children: [
                  Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('لا توجد مصاريف مسجلة', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ])),
              ],
            ])),
          ])),
        ),
      ),
    );
  }

  Widget _costRow(String label, double amount, String currency, IconData icon, Color color, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 18, color: color), const SizedBox(width: 8),
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppColors.textDark))),
      Text(_formatPrice(amount, currency), style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color)),
    ]),
  );

  // ════════════════════════════════════════
  // ADD EXPENSE (direct to car)
  // ════════════════════════════════════════

  void _showAddExpenseDialog(Map<String, dynamic> car) {
    final carId = car['id'] ?? car['_id'];
    final descC = TextEditingController();
    final amountC = TextEditingController();
    final notesC = TextEditingController();
    String category = 'شحن';
    String currency = car['purchase_currency'] ?? 'USD';
    DateTime expenseDate = DateTime.now();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة مصروف للسيارة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(descC, 'الوصف', Icons.description_outlined),
        _input(amountC, 'المبلغ', Icons.money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _dropdown('التصنيف', Icons.category_outlined, category,
          _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          (v) => setS(() => category = v ?? 'شحن')),
        _dropdown('العملة', Icons.currency_exchange, currency,
          _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          (v) => setS(() => currency = v ?? 'USD')),
        _datePicker(ctx, 'تاريخ المصروف', Icons.date_range, expenseDate, (d) => setS(() => expenseDate = d)),
        _textArea(notesC, 'ملاحظات', Icons.notes),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (amountC.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى إدخال المبلغ'), backgroundColor: AppColors.error)); return; }
          Navigator.pop(ctx);
          try {
            await _ds.createExpense(_token, {
              'description': descC.text.trim().isNotEmpty ? descC.text.trim() : '$category - ${car['make'] ?? ''} ${car['model'] ?? ''}',
              'amount': double.tryParse(amountC.text.trim()) ?? 0,
              'currency': currency, 'category': category,
              'expense_date': expenseDate.toIso8601String(),
              'car_id': carId,
              if (car['container_id'] != null) 'container_id': car['container_id'],
              if (car['shipment_id'] != null) 'shipment_id': car['shipment_id'],
              if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
            });
            _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المصروف'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة المصروف'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ════════════════════════════════════════
  // CONTAINER SHARED EXPENSE
  // ════════════════════════════════════════

  void _showContainerExpenseDialog(Map<String, dynamic> car) {
    final containerId = car['container_id'];
    if (containerId == null) return;
    final containerName = _getContainerName(containerId);
    final carsInContainer = _cars.where((c) => c['container_id']?.toString() == containerId.toString()).length;

    final descC = TextEditingController();
    final amountC = TextEditingController();
    final notesC = TextEditingController();
    String category = 'شحن';
    String currency = car['purchase_currency'] ?? 'USD';
    DateTime expenseDate = DateTime.now();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('مصروف مشترك للحاوية', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Info box
        Container(
          padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Expanded(child: Text('الحاوية: $containerName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.directions_car, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 6),
              Text('عدد السيارات: $carsInContainer', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4338CA))),
            ]),
            if (amountC.text.trim().isNotEmpty && carsInContainer > 0) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.pie_chart_outline, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text('حصة كل سيارة: ${_formatPrice((double.tryParse(amountC.text.trim()) ?? 0) / carsInContainer, currency)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4338CA))),
              ]),
            ],
          ]),
        ),
        _input(descC, 'الوصف', Icons.description_outlined),
        _input(amountC, 'المبلغ الإجمالي', Icons.money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _dropdown('التصنيف', Icons.category_outlined, category,
          _expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          (v) => setS(() => category = v ?? 'شحن')),
        _dropdown('العملة', Icons.currency_exchange, currency,
          _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          (v) => setS(() => currency = v ?? 'USD')),
        _datePicker(ctx, 'تاريخ المصروف', Icons.date_range, expenseDate, (d) => setS(() => expenseDate = d)),
        _textArea(notesC, 'ملاحظات', Icons.notes),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (amountC.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى إدخال المبلغ'), backgroundColor: AppColors.error)); return; }
          Navigator.pop(ctx);
          try {
            await _ds.createExpense(_token, {
              'description': descC.text.trim().isNotEmpty ? descC.text.trim() : '$category - حاوية $containerName',
              'amount': double.tryParse(amountC.text.trim()) ?? 0,
              'currency': currency, 'category': category,
              'expense_date': expenseDate.toIso8601String(),
              'container_id': containerId,
              if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
            });
            _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المصروف المشترك'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة المصروف'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة مصروف مشترك', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ════════════════════════════════════════
  // SELL CAR DIALOG (with profit summary)
  // ════════════════════════════════════════

  void _showSellCarDialog(Map<String, dynamic> car) {
    final carId = car['id'] ?? car['_id'];
    final salePriceC = TextEditingController(text: _cleanPrice(car['selling_price'] ?? car['sellingPrice'] ?? car['price']));
    final notesC = TextEditingController();
    String? selectedCustomerId;
    String currency = car['purchase_currency'] ?? 'USD';
    String paymentMethod = 'كاش';
    DateTime saleDate = DateTime.now();
    final totalCost = _getCarTotalCost(car);

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final salePrice = double.tryParse(salePriceC.text.trim()) ?? 0;
      final profit = salePrice - totalCost;
      final isProfit = profit >= 0;

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.sell, color: Color(0xFF2563EB), size: 22), const SizedBox(width: 8),
          Flexible(child: Text('بيع ${car['make'] ?? ''} ${car['model'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16), overflow: TextOverflow.ellipsis)),
        ]),
        content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Cost info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)), const SizedBox(width: 6),
                Expanded(child: Text('التكلفة الإجمالية: ${_formatPrice(totalCost, currency)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)))),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Profit/loss preview (dynamic)
          if (salePrice > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(isProfit ? Icons.trending_up : Icons.trending_down, size: 18, color: isProfit ? AppColors.success : AppColors.error),
                const SizedBox(width: 8),
                Text(isProfit ? 'ربح: ' : 'خسارة: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isProfit ? AppColors.success : AppColors.error)),
                Expanded(child: Text(_formatPrice(profit.abs(), currency), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isProfit ? AppColors.success : AppColors.error))),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          _dropdown('اختر الزبون', Icons.person_outline, selectedCustomerId,
            _customers.map((c) {
              final cId = c['id']?.toString() ?? c['_id']?.toString() ?? '';
              final cName = c['name']?.toString() ?? '';
              return DropdownMenuItem(value: cId, child: Text(cName));
            }).toList(),
            (v) => setS(() => selectedCustomerId = v)),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: salePriceC,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setS(() {}),
              decoration: InputDecoration(labelText: 'سعر البيع', prefixIcon: const Icon(Icons.attach_money, size: 20), filled: true, fillColor: AppColors.bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
          ),
          _dropdown('العملة', Icons.currency_exchange, currency,
            _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            (v) => setS(() => currency = v ?? 'USD')),
          _dropdown('طريقة الدفع', Icons.payment, paymentMethod,
            _paymentMethods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            (v) => setS(() => paymentMethod = v ?? 'كاش')),
          _datePicker(ctx, 'تاريخ البيع', Icons.date_range, saleDate, (d) => setS(() => saleDate = d)),
          _textArea(notesC, 'ملاحظات', Icons.notes),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () async {
            if (salePriceC.text.trim().isEmpty) { ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى إدخال سعر البيع'), backgroundColor: AppColors.error)); return; }
            Navigator.pop(ctx);
            try {
              await _ds.createSale(_token, {
                'car_id': carId,
                if (selectedCustomerId != null) 'customer_id': int.tryParse(selectedCustomerId!) ?? selectedCustomerId,
                'sale_date': saleDate.toIso8601String(),
                'sale_price': double.tryParse(salePriceC.text.trim()) ?? 0,
                'currency': currency, 'payment_method': paymentMethod,
                if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
              });
              _loadData();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم بيع السيارة بنجاح'), backgroundColor: AppColors.success));
            } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل عملية البيع'), backgroundColor: AppColors.error)); }
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('تأكيد البيع', style: TextStyle(fontWeight: FontWeight.w700))),
        ],
      );
    }));
  }

  String _cleanPrice(dynamic val) {
    if (val == null) return '';
    final s = val.toString();
    if (s == 'null' || s == '0' || s == '0.00') return '';
    return s;
  }

  // ════════════════════════════════════════
  // ADD CAR DIALOG (with extended fields + acquisition type)
  // ════════════════════════════════════════

  void _showAddDialog() {
    final vinC = TextEditingController();
    final makeC = TextEditingController();
    final modelC = TextEditingController();
    final yearC = TextEditingController();
    final colorC = TextEditingController();
    final mileageC = TextEditingController();
    final purchasePriceC = TextEditingController();
    final sellingPriceC = TextEditingController();
    final stockNumberC = TextEditingController();
    final notesC = TextEditingController();
    // Extended fields
    final interiorC = TextEditingController();
    final specificationsC = TextEditingController();
    final realOdometerC = TextEditingController();
    final arrivalOdometerC = TextEditingController();
    final paintPiecesC = TextEditingController();
    final exchangeRateC = TextEditingController();

    String fuelType = '';
    String purchaseCurrency = 'USD';
    String status = 'in_korea_warehouse';
    String condition = '';
    String acquisitionType = 'import'; // import or local
    bool hasAccident = false;
    bool hasPanoramicRoof = false;
    DateTime? purchaseDate;
    String? containerId;
    String? shipmentId;
    String? warehouseId;
    String? supplierId;
    String? customerId;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة سيارة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Acquisition type toggle
        _sectionHeader('نوع الاستحواذ'),
        Row(children: [
          Expanded(child: _toggleChip('استيراد', acquisitionType == 'import', () => setS(() { acquisitionType = 'import'; status = 'in_korea_warehouse'; purchaseCurrency = 'KRW'; }))),
          const SizedBox(width: 8),
          Expanded(child: _toggleChip('شراء محلي', acquisitionType == 'local', () => setS(() { acquisitionType = 'local'; status = 'purchased_local'; purchaseCurrency = 'AED'; }))),
        ]),
        const SizedBox(height: 8),

        // Basic info
        _sectionHeader('معلومات السيارة'),
        _input(vinC, 'رقم الشاصي (VIN) *', Icons.qr_code, uppercase: true),
        _input(makeC, 'البراند *', Icons.directions_car),
        _input(modelC, 'الموديل *', Icons.model_training),
        _input(yearC, 'السنة', Icons.calendar_today, keyboard: TextInputType.number),
        _input(colorC, 'اللون', Icons.palette_outlined),
        _dropdown('نوع الوقود', Icons.local_gas_station, fuelType.isEmpty ? null : fuelType,
          _fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          (v) => setS(() => fuelType = v ?? '')),
        _input(mileageC, 'العداد (كم)', Icons.speed, keyboard: TextInputType.number),

        // Extended fields
        _sectionHeader('معلومات إضافية'),
        _dropdown('الحالة الفنية', Icons.build_outlined, condition.isEmpty ? null : condition,
          _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          (v) => setS(() => condition = v ?? '')),
        _input(interiorC, 'الداخلية', Icons.event_seat_outlined),
        _input(realOdometerC, 'العداد الحقيقي', Icons.speed, keyboard: TextInputType.number),
        _input(arrivalOdometerC, 'عداد الوصول', Icons.speed, keyboard: TextInputType.number),
        _input(paintPiecesC, 'عدد القطع المدهونة', Icons.format_paint_outlined, keyboard: TextInputType.number),
        _checkboxTile('بها حادثة', hasAccident, (v) => setS(() => hasAccident = v ?? false)),
        _checkboxTile('سقف بانورامي', hasPanoramicRoof, (v) => setS(() => hasPanoramicRoof = v ?? false)),
        _textArea(specificationsC, 'المواصفات', Icons.list_alt_outlined),

        // Pricing
        _sectionHeader('الأسعار'),
        _input(purchasePriceC, 'سعر الشراء', Icons.money_off, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _dropdown('عملة الشراء', Icons.currency_exchange, purchaseCurrency,
          _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          (v) => setS(() => purchaseCurrency = v ?? 'USD')),
        if (acquisitionType == 'import' && purchaseCurrency != 'USD')
          _input(exchangeRateC, 'سعر الصرف → USD', Icons.swap_horiz, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _input(sellingPriceC, 'سعر البيع', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _datePicker(ctx, 'تاريخ الشراء', Icons.date_range, purchaseDate, (d) => setS(() => purchaseDate = d)),

        // Connections
        _sectionHeader('التوصيلات'),
        _input(stockNumberC, 'رقم المخزون', Icons.inventory),
        if (_containers.isNotEmpty)
          _dropdown('الحاوية', Icons.inventory_2_outlined, containerId,
            _containers.map((c) { final cId = c['id']?.toString() ?? c['_id']?.toString() ?? ''; return DropdownMenuItem(value: cId, child: Text(c['container_number']?.toString() ?? 'حاوية $cId')); }).toList(),
            (v) => setS(() => containerId = v)),
        if (_shipments.isNotEmpty)
          _dropdown('الشحنة', Icons.local_shipping_outlined, shipmentId,
            _shipments.map((s) { final sId = s['id']?.toString() ?? s['_id']?.toString() ?? ''; return DropdownMenuItem(value: sId, child: Text(s['shipment_number']?.toString() ?? 'شحنة $sId')); }).toList(),
            (v) => setS(() => shipmentId = v)),
        if (_warehouses.isNotEmpty)
          _dropdown('المستودع', Icons.warehouse_outlined, warehouseId,
            _warehouses.map((w) { final wId = w['id']?.toString() ?? w['_id']?.toString() ?? ''; return DropdownMenuItem(value: wId, child: Text(w['name']?.toString() ?? 'مستودع $wId')); }).toList(),
            (v) => setS(() => warehouseId = v)),
        if (_suppliers.isNotEmpty)
          _dropdown('المورد', Icons.business_outlined, supplierId,
            _suppliers.map((s) { final sId = s['id']?.toString() ?? s['_id']?.toString() ?? ''; return DropdownMenuItem(value: sId, child: Text(s['name']?.toString() ?? 'مورد $sId')); }).toList(),
            (v) => setS(() => supplierId = v)),
        if (_customers.isNotEmpty)
          _dropdown('الزبون', Icons.person_outline, customerId,
            _customers.map((c) { final cId = c['id']?.toString() ?? c['_id']?.toString() ?? ''; return DropdownMenuItem(value: cId, child: Text(c['name']?.toString() ?? 'زبون $cId')); }).toList(),
            (v) => setS(() => customerId = v)),

        // Status
        _sectionHeader('الحالة'),
        _dropdown('الحالة', Icons.flag_outlined, status,
          _statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          (v) => setS(() => status = v ?? 'in_korea_warehouse')),
        _textArea(notesC, 'ملاحظات', Icons.notes),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (vinC.text.trim().isEmpty || makeC.text.trim().isEmpty || modelC.text.trim().isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى ملء الحقول المطلوبة (VIN، البراند، الموديل)'), backgroundColor: AppColors.error)); return;
          }
          Navigator.pop(ctx);
          try {
            final body = <String, dynamic>{
              'vin': vinC.text.trim().toUpperCase(), 'make': makeC.text.trim(), 'model': modelC.text.trim(),
              'year': yearC.text.trim(), 'color': colorC.text.trim(), 'status': status,
              'selling_price': double.tryParse(sellingPriceC.text.trim()) ?? 0,
              'purchase_price': double.tryParse(purchasePriceC.text.trim()) ?? 0,
              'purchase_currency': purchaseCurrency, 'stock_number': stockNumberC.text.trim(), 'notes': notesC.text.trim(),
            };
            if (fuelType.isNotEmpty) body['fuel_type'] = fuelType;
            if (condition.isNotEmpty) body['condition'] = condition;
            if (interiorC.text.trim().isNotEmpty) body['interior'] = interiorC.text.trim();
            if (specificationsC.text.trim().isNotEmpty) body['specifications'] = specificationsC.text.trim();
            if (mileageC.text.trim().isNotEmpty) body['mileage'] = int.tryParse(mileageC.text.trim()) ?? 0;
            if (realOdometerC.text.trim().isNotEmpty) body['real_odometer'] = int.tryParse(realOdometerC.text.trim()) ?? 0;
            if (arrivalOdometerC.text.trim().isNotEmpty) body['arrival_odometer'] = int.tryParse(arrivalOdometerC.text.trim()) ?? 0;
            if (paintPiecesC.text.trim().isNotEmpty) body['paint_pieces'] = int.tryParse(paintPiecesC.text.trim()) ?? 0;
            body['has_accident'] = hasAccident;
            body['has_panoramic_roof'] = hasPanoramicRoof;
            body['acquisition_type'] = acquisitionType;
            if (exchangeRateC.text.trim().isNotEmpty) body['exchange_rate_at_purchase'] = double.tryParse(exchangeRateC.text.trim()) ?? 0;
            if (purchaseDate != null) body['purchase_date'] = purchaseDate!.toIso8601String();
            if (containerId != null) body['container_id'] = int.tryParse(containerId!) ?? containerId;
            if (shipmentId != null) body['shipment_id'] = int.tryParse(shipmentId!) ?? shipmentId;
            if (warehouseId != null) body['warehouse_id'] = int.tryParse(warehouseId!) ?? warehouseId;
            if (supplierId != null) body['supplier_id'] = int.tryParse(supplierId!) ?? supplierId;
            if (customerId != null) body['customer_id'] = int.tryParse(customerId!) ?? customerId;
            await _ds.createCar(_token, body);
            _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة السيارة'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الإضافة'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ════════════════════════════════════════
  // EDIT CAR DIALOG
  // ════════════════════════════════════════

  void _showEditDialog(Map<String, dynamic> car) {
    final id = car['_id'] ?? car['id'] ?? '';
    final vinC = TextEditingController(text: car['vin'] ?? '');
    final makeC = TextEditingController(text: car['make'] ?? car['brand'] ?? '');
    final modelC = TextEditingController(text: car['model'] ?? '');
    final yearC = TextEditingController(text: _cleanVal(car['year']));
    final colorC = TextEditingController(text: car['color'] ?? '');
    final mileageC = TextEditingController(text: _cleanVal(car['mileage']));
    final purchasePriceC = TextEditingController(text: _cleanVal(car['purchase_price'] ?? car['purchasePrice']));
    final sellingPriceC = TextEditingController(text: _cleanVal(car['selling_price'] ?? car['sellingPrice'] ?? car['price']));
    final stockNumberC = TextEditingController(text: car['stock_number'] ?? '');
    final notesC = TextEditingController(text: car['notes'] ?? '');
    // Extended
    final interiorC = TextEditingController(text: car['interior'] ?? '');
    final specificationsC = TextEditingController(text: car['specifications'] ?? '');
    final realOdometerC = TextEditingController(text: _cleanVal(car['real_odometer'] ?? car['realOdometer']));
    final arrivalOdometerC = TextEditingController(text: _cleanVal(car['arrival_odometer'] ?? car['arrivalOdometer']));
    final paintPiecesC = TextEditingController(text: _cleanVal(car['paint_pieces'] ?? car['paintPieces']));
    final exchangeRateC = TextEditingController(text: _cleanVal(car['exchange_rate_at_purchase'] ?? car['exchangeRateAtPurchase']));

    String fuelType = car['fuel_type'] ?? car['fuelType'] ?? '';
    String purchaseCurrency = car['purchase_currency'] ?? 'USD';
    if (!_currencies.contains(purchaseCurrency)) purchaseCurrency = 'USD';
    String status = car['status'] ?? 'in_korea_warehouse';
    if (!_statusLabels.containsKey(status)) status = 'in_korea_warehouse';
    String condition = car['condition'] ?? '';
    String acquisitionType = car['acquisition_type'] ?? car['acquisitionType'] ?? 'import';
    bool hasAccident = car['has_accident'] == true || car['hasAccident'] == true;
    bool hasPanoramicRoof = car['has_panoramic_roof'] == true || car['hasPanoramicRoof'] == true;
    DateTime? purchaseDate;
    if (car['purchase_date'] != null && car['purchase_date'].toString().isNotEmpty) purchaseDate = DateTime.tryParse(car['purchase_date'].toString());

    String? containerId = _cleanNull(car['container_id']);
    String? shipmentId = _cleanNull(car['shipment_id']);
    String? warehouseId = _cleanNull(car['warehouse_id']);
    String? supplierId = _cleanNull(car['supplier_id']);
    String? customerId = _cleanNull(car['customer_id']);

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل السيارة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [

        _sectionHeader('نوع الاستحواذ'),
        Row(children: [
          Expanded(child: _toggleChip('استيراد', acquisitionType == 'import', () => setS(() => acquisitionType = 'import'))),
          const SizedBox(width: 8),
          Expanded(child: _toggleChip('شراء محلي', acquisitionType == 'local', () => setS(() => acquisitionType = 'local'))),
        ]),
        const SizedBox(height: 8),

        _sectionHeader('معلومات السيارة'),
        _input(vinC, 'رقم الشاصي (VIN)', Icons.qr_code, uppercase: true),
        _input(makeC, 'البراند', Icons.directions_car),
        _input(modelC, 'الموديل', Icons.model_training),
        _input(yearC, 'السنة', Icons.calendar_today, keyboard: TextInputType.number),
        _input(colorC, 'اللون', Icons.palette_outlined),
        _dropdown('نوع الوقود', Icons.local_gas_station, fuelType.isEmpty ? null : fuelType,
          _fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
          (v) => setS(() => fuelType = v ?? '')),
        _input(mileageC, 'العداد (كم)', Icons.speed, keyboard: TextInputType.number),

        _sectionHeader('معلومات إضافية'),
        _dropdown('الحالة الفنية', Icons.build_outlined, condition.isEmpty ? null : condition,
          _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          (v) => setS(() => condition = v ?? '')),
        _input(interiorC, 'الداخلية', Icons.event_seat_outlined),
        _input(realOdometerC, 'العداد الحقيقي', Icons.speed, keyboard: TextInputType.number),
        _input(arrivalOdometerC, 'عداد الوصول', Icons.speed, keyboard: TextInputType.number),
        _input(paintPiecesC, 'عدد القطع المدهونة', Icons.format_paint_outlined, keyboard: TextInputType.number),
        _checkboxTile('بها حادثة', hasAccident, (v) => setS(() => hasAccident = v ?? false)),
        _checkboxTile('سقف بانورامي', hasPanoramicRoof, (v) => setS(() => hasPanoramicRoof = v ?? false)),
        _textArea(specificationsC, 'المواصفات', Icons.list_alt_outlined),

        _sectionHeader('الأسعار'),
        _input(purchasePriceC, 'سعر الشراء', Icons.money_off, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _dropdown('عملة الشراء', Icons.currency_exchange, purchaseCurrency,
          _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          (v) => setS(() => purchaseCurrency = v ?? 'USD')),
        if (acquisitionType == 'import' && purchaseCurrency != 'USD')
          _input(exchangeRateC, 'سعر الصرف → USD', Icons.swap_horiz, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _input(sellingPriceC, 'سعر البيع', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _datePicker(ctx, 'تاريخ الشراء', Icons.date_range, purchaseDate, (d) => setS(() => purchaseDate = d)),

        _sectionHeader('التوصيلات'),
        _input(stockNumberC, 'رقم المخزون', Icons.inventory),
        if (_containers.isNotEmpty)
          _dropdown('الحاوية', Icons.inventory_2_outlined, _validDropdownVal(containerId, _containers),
            _containers.map((c) { final cId = c['id']?.toString() ?? c['_id']?.toString() ?? ''; return DropdownMenuItem(value: cId, child: Text(c['container_number']?.toString() ?? 'حاوية $cId')); }).toList(),
            (v) => setS(() => containerId = v)),
        if (_shipments.isNotEmpty)
          _dropdown('الشحنة', Icons.local_shipping_outlined, _validDropdownVal(shipmentId, _shipments),
            _shipments.map((s) { final sId = s['id']?.toString() ?? s['_id']?.toString() ?? ''; return DropdownMenuItem(value: sId, child: Text(s['shipment_number']?.toString() ?? 'شحنة $sId')); }).toList(),
            (v) => setS(() => shipmentId = v)),
        if (_warehouses.isNotEmpty)
          _dropdown('المستودع', Icons.warehouse_outlined, _validDropdownVal(warehouseId, _warehouses),
            _warehouses.map((w) { final wId = w['id']?.toString() ?? w['_id']?.toString() ?? ''; return DropdownMenuItem(value: wId, child: Text(w['name']?.toString() ?? 'مستودع $wId')); }).toList(),
            (v) => setS(() => warehouseId = v)),
        if (_suppliers.isNotEmpty)
          _dropdown('المورد', Icons.business_outlined, _validDropdownVal(supplierId, _suppliers),
            _suppliers.map((s) { final sId = s['id']?.toString() ?? s['_id']?.toString() ?? ''; return DropdownMenuItem(value: sId, child: Text(s['name']?.toString() ?? 'مورد $sId')); }).toList(),
            (v) => setS(() => supplierId = v)),
        if (_customers.isNotEmpty)
          _dropdown('الزبون', Icons.person_outline, _validDropdownVal(customerId, _customers),
            _customers.map((c) { final cId = c['id']?.toString() ?? c['_id']?.toString() ?? ''; return DropdownMenuItem(value: cId, child: Text(c['name']?.toString() ?? 'زبون $cId')); }).toList(),
            (v) => setS(() => customerId = v)),

        _sectionHeader('الحالة'),
        _dropdown('الحالة', Icons.flag_outlined, status,
          _statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          (v) => setS(() => status = v ?? 'in_korea_warehouse')),
        _textArea(notesC, 'ملاحظات', Icons.notes),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            final body = <String, dynamic>{
              'vin': vinC.text.trim().toUpperCase(), 'make': makeC.text.trim(), 'model': modelC.text.trim(),
              'year': yearC.text.trim(), 'color': colorC.text.trim(), 'status': status,
              'selling_price': double.tryParse(sellingPriceC.text.trim()) ?? 0,
              'purchase_price': double.tryParse(purchasePriceC.text.trim()) ?? 0,
              'purchase_currency': purchaseCurrency, 'stock_number': stockNumberC.text.trim(), 'notes': notesC.text.trim(),
              'acquisition_type': acquisitionType, 'has_accident': hasAccident, 'has_panoramic_roof': hasPanoramicRoof,
            };
            if (fuelType.isNotEmpty) body['fuel_type'] = fuelType;
            if (condition.isNotEmpty) body['condition'] = condition;
            if (interiorC.text.trim().isNotEmpty) body['interior'] = interiorC.text.trim();
            if (specificationsC.text.trim().isNotEmpty) body['specifications'] = specificationsC.text.trim();
            if (mileageC.text.trim().isNotEmpty) body['mileage'] = int.tryParse(mileageC.text.trim()) ?? 0;
            if (realOdometerC.text.trim().isNotEmpty) body['real_odometer'] = int.tryParse(realOdometerC.text.trim()) ?? 0;
            if (arrivalOdometerC.text.trim().isNotEmpty) body['arrival_odometer'] = int.tryParse(arrivalOdometerC.text.trim()) ?? 0;
            if (paintPiecesC.text.trim().isNotEmpty) body['paint_pieces'] = int.tryParse(paintPiecesC.text.trim()) ?? 0;
            if (exchangeRateC.text.trim().isNotEmpty) body['exchange_rate_at_purchase'] = double.tryParse(exchangeRateC.text.trim()) ?? 0;
            if (purchaseDate != null) body['purchase_date'] = purchaseDate!.toIso8601String();
            body['container_id'] = containerId != null ? (int.tryParse(containerId!) ?? containerId) : null;
            body['shipment_id'] = shipmentId != null ? (int.tryParse(shipmentId!) ?? shipmentId) : null;
            body['warehouse_id'] = warehouseId != null ? (int.tryParse(warehouseId!) ?? warehouseId) : null;
            body['supplier_id'] = supplierId != null ? (int.tryParse(supplierId!) ?? supplierId) : null;
            body['customer_id'] = customerId != null ? (int.tryParse(customerId!) ?? customerId) : null;
            await _ds.updateCar(_token, id, body);
            _loadData();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل'), backgroundColor: AppColors.success));
          } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل التعديل'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  // ════════════════════════════════════════
  // DELETE CONFIRMATION
  // ════════════════════════════════════════

  void _confirmDelete(String id) {
    if (id.isEmpty) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف السيارة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: const Text('هل تريد حذف هذه السيارة نهائياً؟', textAlign: TextAlign.center),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async { Navigator.pop(ctx);
          try { await _ds.deleteCar(_token, id); _loadData(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف'), backgroundColor: AppColors.success)); }
          catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل الحذف'), backgroundColor: AppColors.error)); }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    ));
  }

  // ════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════

  String _cleanVal(dynamic val) {
    if (val == null) return '';
    final s = val.toString();
    if (s == 'null' || s == '0') return '';
    return s;
  }

  String? _cleanNull(dynamic val) {
    if (val == null) return null;
    final s = val.toString();
    if (s == 'null' || s.isEmpty) return null;
    return s;
  }

  String? _validDropdownVal(String? val, List<Map<String, dynamic>> items) {
    if (val == null) return null;
    final exists = items.any((i) => (i['id']?.toString() ?? i['_id']?.toString()) == val);
    return exists ? val : null;
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
    ]),
  );

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard, bool uppercase = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, keyboardType: keyboard,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      onChanged: uppercase ? (v) { final upper = v.toUpperCase(); if (v != upper) c.value = c.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length)); } : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );

  Widget _textArea(TextEditingController c, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: c, maxLines: 3, minLines: 2,
      decoration: InputDecoration(labelText: label, prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 40), child: Icon(icon, size: 20)), filled: true, fillColor: AppColors.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );

  Widget _dropdown(String label, IconData icon, String? value, List<DropdownMenuItem<String>> items, void Function(String?) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(value: value, items: items, onChanged: onChanged, isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
  );

  Widget _datePicker(BuildContext dialogCtx, String label, IconData icon, DateTime? currentValue, void Function(DateTime) onPicked) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: dialogCtx, initialDate: currentValue ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)), child: child!));
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
        child: Text(currentValue != null ? DateFormat('yyyy-MM-dd').format(currentValue) : '', style: const TextStyle(fontSize: 14))),
    ),
  );

  Widget _checkboxTile(String label, bool value, void Function(bool?) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Container(
      decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)),
      child: CheckboxListTile(
        value: value, onChanged: onChanged,
        title: Text(label, style: const TextStyle(fontSize: 14)),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        activeColor: AppColors.primary,
      ),
    ),
  );

  Widget _toggleChip(String label, bool selected, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
      ),
      child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.textGray))),
    ),
  );

  // ════════════════════════════════════════
  // CAR DETAILS BOTTOM SHEET
  // ════════════════════════════════════════

  void _showCarDetails(Map<String, dynamic> car) {
    final carId = car['id'] ?? car['_id'];
    final carExpenses = _getCarExpenses(carId);
    final directExpenses = _getCarDirectExpenses(carId);
    final containerShare = _getContainerShareExpenses(car);
    final totalExpenses = directExpenses + containerShare;
    final totalCost = _getCarTotalCost(car);
    final status = (car['status'] ?? '').toString();
    final isSold = status == 'sold';
    final sale = _getCarSale(carId);
    final pCurrency = car['purchase_currency'] ?? 'USD';

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85, minChildSize: 0.4, maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('${car['make'] ?? car['brand'] ?? ''} ${car['model'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              if (car['year'] != null && car['year'].toString().isNotEmpty) Text('(${car['year']})', style: const TextStyle(fontSize: 14, color: AppColors.textGray)),
              const SizedBox(height: 8),
              _buildStatusBadge(status),
              const SizedBox(height: 12),
            ])),
            const Divider(height: 1),
            Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
              ..._detailRows(car),

              // Connections
              if (_hasConnections(car)) ...[const SizedBox(height: 16), _sectionHeader('التوصيلات'), ..._connectionRows(car)],

              // Expenses
              if (carExpenses.isNotEmpty || containerShare > 0) ...[
                const SizedBox(height: 16), _sectionHeader('المصاريف'),
                ...carExpenses.map((e) => _expenseRow(e)),
                if (containerShare > 0)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Container(
                    padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF6366F1).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.group_work_outlined, size: 16, color: Color(0xFF6366F1)), const SizedBox(width: 8),
                      const Expanded(child: Text('حصة مصاريف الحاوية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)))),
                      Text(_formatPrice(containerShare, pCurrency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6366F1))),
                    ]),
                  )),
                Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
                  const SizedBox(width: 120, child: Text('إجمالي المصاريف', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w700))),
                  Expanded(child: Text(_formatPrice(totalExpenses, pCurrency), style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w700))),
                ])),
              ],

              // Sale info
              if (isSold && sale != null) ...[
                const SizedBox(height: 16), _sectionHeader('معلومات البيع'),
                _detailField('سعر البيع', _formatPrice(sale['sale_price'], sale['currency'] ?? pCurrency)),
                _detailField('الزبون', sale['customer_name']?.toString() ?? _getCustomerName(sale['customer_id'])),
                _detailField('طريقة الدفع', sale['payment_method']?.toString() ?? ''),
                if (sale['sale_date'] != null) _detailField('تاريخ البيع', _formatDate(sale['sale_date'])),
              ],

              // Total cost box
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.account_balance_wallet, size: 20, color: Color(0xFF7C3AED)), const SizedBox(width: 8),
                  const Expanded(child: Text('التكلفة الإجمالية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)))),
                  Text(_formatPrice(totalCost, pCurrency), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
                ])),

              // Profit/loss
              if ((double.tryParse((car['selling_price'] ?? car['sellingPrice'] ?? '0').toString()) ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final sp = double.tryParse((car['selling_price'] ?? car['sellingPrice'] ?? '0').toString()) ?? 0;
                  final profit = sp - totalCost;
                  final isP = profit >= 0;
                  return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (isP ? AppColors.success : AppColors.error).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(isP ? Icons.trending_up : Icons.trending_down, size: 20, color: isP ? AppColors.success : AppColors.error), const SizedBox(width: 8),
                      Expanded(child: Text(isP ? 'الربح المتوقع' : 'الخسارة المتوقعة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isP ? AppColors.success : AppColors.error))),
                      Text(_formatPrice(profit.abs(), pCurrency), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isP ? AppColors.success : AppColors.error)),
                    ]));
                }),
              ],

              // Actions
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showEditDialog(car); }, icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showCostBreakdown(car); }, icon: const Icon(Icons.receipt_long, size: 18), label: const Text('التكلفة'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                if (!isSold) ...[
                  Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showSellCarDialog(car); }, icon: const Icon(Icons.sell, size: 18), label: const Text('بيع'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
                  const SizedBox(width: 8),
                ],
                Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _confirmDelete(carId?.toString() ?? ''); }, icon: const Icon(Icons.delete, size: 18), label: const Text('حذف'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
              ]),
            ])),
          ])),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_getStatusIcon(status), size: 14, color: color), const SizedBox(width: 4),
        Text(_getStatusLabel(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  bool _hasConnections(Map<String, dynamic> car) =>
    _getContainerName(car['container_id']).isNotEmpty || _getShipmentName(car['shipment_id']).isNotEmpty ||
    _getWarehouseName(car['warehouse_id']).isNotEmpty || _getSupplierName(car['supplier_id']).isNotEmpty ||
    _getCustomerName(car['customer_id']).isNotEmpty;

  List<Widget> _connectionRows(Map<String, dynamic> car) {
    final rows = <Widget>[];
    void addRow(String label, String value, IconData icon) {
      if (value.isNotEmpty) {
        rows.add(Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primary), const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ])));
      }
    }
    addRow('الحاوية', _getContainerName(car['container_id']), Icons.inventory_2_outlined);
    addRow('الشحنة', _getShipmentName(car['shipment_id']), Icons.local_shipping_outlined);
    addRow('المستودع', _getWarehouseName(car['warehouse_id']), Icons.warehouse_outlined);
    addRow('المورد', _getSupplierName(car['supplier_id']), Icons.business_outlined);
    addRow('الزبون', _getCustomerName(car['customer_id']), Icons.person_outline);
    return rows;
  }

  Widget _expenseRow(Map<String, dynamic> expense) {
    final desc = expense['description'] ?? expense['category'] ?? '';
    final amount = expense['amount']?.toString() ?? '0';
    final currency = expense['currency'] ?? 'USD';
    final category = expense['category'] ?? '';
    final dateStr = _formatDate(expense['expense_date'] ?? expense['created_at']);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.receipt_outlined, size: 16, color: Color(0xFFD97706))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(desc.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (category.isNotEmpty || dateStr.isNotEmpty) Row(children: [
              if (category.isNotEmpty) Text(category, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              if (category.isNotEmpty && dateStr.isNotEmpty) const Text(' - ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              if (dateStr.isNotEmpty) Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ])),
          Text(_formatPrice(double.tryParse(amount) ?? 0, currency), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
        ])),
    );
  }

  Widget _detailField(String label, String value) {
    if (value.isEmpty || value == '-' || value == 'null') return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
    ]));
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return '';
    final dt = DateTime.tryParse(date.toString());
    return dt != null ? DateFormat('yyyy-MM-dd').format(dt) : '';
  }

  List<Widget> _detailRows(Map<String, dynamic> car) {
    final status = (car['status'] ?? '').toString();
    final pPrice = car['purchase_price'] ?? car['purchasePrice'];
    final pCurrency = car['purchase_currency'] ?? 'USD';
    final sPrice = car['selling_price'] ?? car['sellingPrice'] ?? car['price'];

    final fields = <MapEntry<String, String>>[
      MapEntry('رقم المخزون', car['stock_number']?.toString() ?? '-'),
      MapEntry('رقم الشاصي (VIN)', car['vin']?.toString() ?? '-'),
      MapEntry('البراند', (car['make'] ?? car['brand'] ?? '-').toString()),
      MapEntry('الموديل', car['model']?.toString() ?? '-'),
      MapEntry('السنة', car['year']?.toString() ?? '-'),
      MapEntry('اللون', car['color']?.toString() ?? '-'),
      MapEntry('نوع الوقود', (car['fuel_type'] ?? car['fuelType'] ?? '-').toString()),
      MapEntry('العداد (كم)', car['mileage']?.toString() ?? '-'),
      MapEntry('الحالة الفنية', (car['condition'] ?? '-').toString()),
      MapEntry('الداخلية', (car['interior'] ?? '-').toString()),
      MapEntry('العداد الحقيقي', (car['real_odometer'] ?? car['realOdometer'] ?? '-').toString()),
      MapEntry('عداد الوصول', (car['arrival_odometer'] ?? car['arrivalOdometer'] ?? '-').toString()),
      MapEntry('القطع المدهونة', (car['paint_pieces'] ?? car['paintPieces'] ?? '-').toString()),
      MapEntry('بها حادثة', (car['has_accident'] == true || car['hasAccident'] == true) ? 'نعم' : '-'),
      MapEntry('سقف بانورامي', (car['has_panoramic_roof'] == true || car['hasPanoramicRoof'] == true) ? 'نعم' : '-'),
      MapEntry('المواصفات', (car['specifications'] ?? '-').toString()),
      MapEntry('نوع الاستحواذ', car['acquisition_type'] == 'local' ? 'شراء محلي' : car['acquisition_type'] == 'import' ? 'استيراد' : '-'),
      MapEntry('سعر الشراء', pPrice != null && pPrice.toString() != '0' && pPrice.toString().isNotEmpty ? _formatPrice(pPrice, pCurrency) : '-'),
      if ((car['exchange_rate_at_purchase'] ?? car['exchangeRateAtPurchase']) != null)
        MapEntry('سعر الصرف', (car['exchange_rate_at_purchase'] ?? car['exchangeRateAtPurchase']).toString()),
      MapEntry('سعر البيع', sPrice != null && sPrice.toString() != '0' && sPrice.toString().isNotEmpty ? _formatPrice(sPrice, pCurrency) : '-'),
      MapEntry('تاريخ الشراء', _formatDate(car['purchase_date'] ?? car['purchaseDate'])),
      MapEntry('الحالة', _getStatusLabel(status)),
      MapEntry('ملاحظات', car['notes']?.toString() ?? '-'),
    ];
    return fields.where((f) => f.value != '-' && f.value != 'null' && f.value.isNotEmpty && f.value != '0').map((f) =>
      _detailField(f.key, f.value)).toList();
  }
}
