import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class ConsignmentCarsScreen extends StatefulWidget {
  const ConsignmentCarsScreen({super.key});
  @override
  State<ConsignmentCarsScreen> createState() => _ConsignmentCarsScreenState();
}

class _ConsignmentCarsScreenState extends State<ConsignmentCarsScreen> with SingleTickerProviderStateMixin {
  late final DataService _ds;
  late final TabController _tabController;

  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _currencies = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  // ── Constants ──

  static const List<String> _carBrands = [
    'هيونداي', 'كيا', 'تويوتا', 'هوندا', 'نيسان', 'مازدا', 'سوبارو',
    'ميتسوبيشي', 'سوزوكي', 'لكزس', 'إنفينيتي', 'أكيورا', 'بي إم دبليو',
    'مرسيدس', 'أودي', 'فولكس فاجن', 'شيفروليه', 'فورد', 'جيب', 'رينو',
    'بيجو', 'جينيسيس', 'تسلا', 'أخرى',
  ];

  static const List<String> _carColors = [
    'أبيض', 'أسود', 'فضي', 'رمادي', 'أزرق', 'أحمر', 'أخضر', 'بني',
    'ذهبي', 'برتقالي', 'بيج', 'كحلي', 'بنفسجي', 'وردي', 'أخرى',
  ];

  static const List<String> _regionalSpecs = ['أمريكي', 'كوري', 'خليجي'];
  static const List<String> _sunroofTypes = ['بانوراما', 'فتحة عادية', 'بدون فتحة'];

  static const Map<String, String> _statusLabels = {
    'available': 'متاحة للبيع',
    'reserved': 'محجوزة',
    'sold': 'مباعة',
    'returned': 'مُرجعة',
  };

  static const Map<String, Color> _statusColors = {
    'available': Color(0xFF22C55E),
    'reserved': Color(0xFFD97706),
    'sold': Color(0xFF64748B),
    'returned': Color(0xFFEA580C),
  };

  static const List<String> _defaultCurrencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY'];

  static const List<Map<String, String>> _warehouses = [
    {'id': 'main', 'name': 'مستودع الأمانة الرئيسي'},
    {'id': 'showroom', 'name': 'معرض السيارات'},
    {'id': 'outdoor', 'name': 'الساحة الخارجية'},
  ];

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _tabController = TabController(length: 3, vsync: this);
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
        _ds.getConsignmentCars(_token),
        _ds.getConsignmentSales(_token),
        _ds.getAccounts(_token),
        _ds.getCurrencies(_token).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _cars = results[0];
        _sales = results[1];
        _accounts = results[2];
        _currencies = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل سيارات الأمانة'; _isLoading = false; });
    }
  }

  // ── Helpers ──

  String _statusLabel(String? status) => _statusLabels[status] ?? status ?? '-';
  Color _statusColor(String? status) => _statusColors[status] ?? AppColors.textMuted;

  List<String> get _currencyCodes {
    if (_currencies.isNotEmpty) {
      return _currencies.map((c) => (c['code'] ?? '').toString()).where((c) => c.isNotEmpty).toList();
    }
    return _defaultCurrencies;
  }

  List<Map<String, dynamic>> get _cashBoxAccounts =>
      _accounts.where((a) => (a['type'] ?? '').toString() == 'cash_box').toList();

  List<Map<String, dynamic>> get _revenueAccounts =>
      _accounts.where((a) => (a['type'] ?? '').toString() == 'revenue').toList();

  double _convertToUSD(double amount, String currency) {
    if (currency == 'USD') return amount;
    for (final c in _currencies) {
      if ((c['code'] ?? '').toString() == currency) {
        final rate = double.tryParse((c['rate_to_usd'] ?? c['rateToUSD'] ?? '0').toString());
        if (rate != null && rate > 0) return (amount * rate * 100).roundToDouble() / 100;
      }
    }
    if (currency == 'AED') return (amount / 3.67 * 100).roundToDouble() / 100;
    if (currency == 'KRW') return (amount * 0.00075 * 100).roundToDouble() / 100;
    return amount;
  }

  String _getDefaultCashBoxId() {
    final showroomBox = _cashBoxAccounts.where((a) => (a['name'] ?? '').toString().contains('المعرض')).firstOrNull;
    return (showroomBox?['id'] ?? showroomBox?['_id'] ?? _cashBoxAccounts.firstOrNull?['id'] ?? '').toString();
  }

  List<Map<String, dynamic>> get _filteredCars {
    final q = _searchController.text.trim().toLowerCase();
    return _cars.where((car) {
      // Status filter
      if (_statusFilter != 'all') {
        final status = (car['status'] ?? '').toString();
        if (status != _statusFilter) return false;
      }
      // Search filter
      if (q.isNotEmpty) {
        final ownerName = (car['owner_name'] ?? car['ownerName'] ?? '').toString().toLowerCase();
        final brand = (car['brand'] ?? car['make'] ?? '').toString().toLowerCase();
        final model = (car['model'] ?? '').toString().toLowerCase();
        final vin = (car['vin_or_last5'] ?? car['vinOrLast5'] ?? '').toString().toLowerCase();
        final plate = (car['plate_number'] ?? car['plateNumber'] ?? '').toString().toLowerCase();
        return ownerName.contains(q) || brand.contains(q) || model.contains(q) || vin.contains(q) || plate.contains(q);
      }
      return true;
    }).toList();
  }

  int get _availableCount => _cars.where((c) => c['status'] == 'available').length;
  int get _soldCount => _cars.where((c) => c['status'] == 'sold').length;

  double get _totalCommissions {
    double total = 0;
    for (final sale in _sales) {
      final usd = sale['commission_amount_usd'] ?? sale['commissionAmountUSD'] ?? sale['commission_amount'] ?? sale['commissionAmount'] ?? 0;
      total += (usd is num) ? usd.toDouble() : (double.tryParse(usd.toString()) ?? 0);
    }
    return total;
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سيارات الأمانة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          tabs: const [
            Tab(text: 'السيارات'),
            Tab(text: 'المبيعات والعمولات'),
            Tab(text: 'سجل الدخول والخروج'),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.consignmentCarsPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        onPressed: _showAddDialog, child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(controller: _tabController, children: [
                  _buildCarsTab(),
                  _buildSalesTab(),
                  _buildMovementsTab(),
                ]),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
    const SizedBox(height: 12), Text(_error!),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
  ]));

  // ══════════════════════════════════════════════════════════
  //  TAB 1: السيارات
  // ══════════════════════════════════════════════════════════

  Widget _buildCarsTab() {
    final filtered = _filteredCars;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Stats Cards
          _buildStatsCards(),
          // Search & Filter
          _buildSearchBar(),
          // Count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text('${filtered.length} سيارة', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          // Cars List
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.car_rental_outlined, size: 48, color: AppColors.textMuted),
                SizedBox(height: 12),
                Text('لا توجد سيارات أمانة', style: TextStyle(color: AppColors.textGray)),
              ])),
            )
          else
            ...filtered.map((car) => _buildCarCard(car)),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(children: [
        _statCard('إجمالي السيارات', '${_cars.length}', const Color(0xFF2563EB), Icons.directions_car),
        const SizedBox(width: 8),
        _statCard('متاحة للبيع', '$_availableCount', const Color(0xFF22C55E), Icons.check_circle_outline),
        const SizedBox(width: 8),
        _statCard('مباعة', '$_soldCount', const Color(0xFF64748B), Icons.sell_outlined),
        const SizedBox(width: 8),
        _statCard('العمولات', '\$${_totalCommissions.toStringAsFixed(0)}', const Color(0xFF7C3AED), Icons.attach_money),
      ]),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ]),
    ));
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'بحث بالمالك، الماركة، الموديل، الشاصي...',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
            filled: true, fillColor: AppColors.bgLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        )),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: _statusFilter,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('الكل')),
              ..._statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
            ],
            onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
          )),
        ),
      ]),
    );
  }

  Widget _buildCarCard(Map<String, dynamic> car) {
    final brand = car['brand'] ?? car['make'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final ownerName = car['owner_name'] ?? car['ownerName'] ?? '';
    final ownerPhone = car['owner_phone'] ?? car['ownerPhone'] ?? '';
    final status = (car['status'] ?? '').toString();
    final color = car['color'] ?? '';
    final vin = car['vin_or_last5'] ?? car['vinOrLast5'] ?? '';
    final plate = car['plate_number'] ?? car['plateNumber'] ?? '';
    final askingPrice = car['asking_price'] ?? car['askingPrice'];
    final askingCurrency = car['asking_price_currency'] ?? car['askingPriceCurrency'] ?? 'AED';

    final statusCol = _statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCarDetails(car),
        onLongPress: () => _showActions(car),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.car_rental, color: Color(0xFF7C3AED), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$brand $model ${year.toString().isNotEmpty && year.toString() != 'null' ? '($year)' : ''}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Flexible(child: Text(ownerName.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (ownerPhone.toString().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(ownerPhone.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ]),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusCol.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusCol)),
                ),
                if (askingPrice != null && askingPrice.toString().isNotEmpty && askingPrice.toString() != '0' && askingPrice.toString() != 'null') ...[
                  const SizedBox(height: 4),
                  Text('$askingPrice $askingCurrency', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ],
              ]),
            ]),
            // Bottom row: VIN + plate + color
            if (vin.toString().isNotEmpty || plate.toString().isNotEmpty || color.toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 60),
                child: Row(children: [
                  if (color.toString().isNotEmpty && color.toString() != 'null') ...[
                    const Icon(Icons.palette_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(color.toString(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(width: 10),
                  ],
                  if (vin.toString().isNotEmpty && vin.toString() != 'null') ...[
                    const Icon(Icons.qr_code, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(vin.toString(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace')),
                    const SizedBox(width: 10),
                  ],
                  if (plate.toString().isNotEmpty && plate.toString() != 'null') ...[
                    const Icon(Icons.confirmation_number_outlined, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(plate.toString(), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ]),
              ),
            // Action buttons for available cars
            if (status == 'available')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  _actionButton('بيع', Icons.shopping_cart, AppColors.primary, () => _showSellDialog(car)),
                  const SizedBox(width: 6),
                  _actionButton('إرجاع', Icons.undo, const Color(0xFFEA580C), () => _showReturnDialog(car)),
                  const SizedBox(width: 6),
                  _actionButton('تعديل', Icons.edit_outlined, AppColors.blue600, () => _showEditDialog(car)),
                  const SizedBox(width: 6),
                  _actionButton('حذف', Icons.delete_outline, AppColors.error, () => _confirmDelete(car)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 2: المبيعات والعمولات
  // ══════════════════════════════════════════════════════════

  Widget _buildSalesTab() {
    if (_sales.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.point_of_sale_outlined, size: 48, color: AppColors.textMuted),
        SizedBox(height: 12),
        Text('لا توجد مبيعات بعد', style: TextStyle(color: AppColors.textGray)),
      ]));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: _sales.length,
        itemBuilder: (ctx, i) => _buildSaleCard(_sales[i]),
      ),
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final carBrand = sale['car_brand'] ?? sale['carBrand'] ?? '';
    final carModel = sale['car_model'] ?? sale['carModel'] ?? '';
    final ownerName = sale['owner_name'] ?? sale['ownerName'] ?? '';
    final buyerName = sale['buyer_name'] ?? sale['buyerName'] ?? '';
    final buyerPhone = sale['buyer_phone'] ?? sale['buyerPhone'] ?? '';
    final salePrice = sale['sale_price'] ?? sale['salePrice'] ?? 0;
    final saleCurrency = sale['sale_currency'] ?? sale['saleCurrency'] ?? 'AED';
    final commissionAmount = sale['commission_amount'] ?? sale['commissionAmount'] ?? 0;
    final commissionCurrency = sale['commission_currency'] ?? sale['commissionCurrency'] ?? 'AED';
    final ownerShare = sale['owner_share'] ?? sale['ownerShare'] ?? 0;
    final saleDate = sale['sale_date'] ?? sale['saleDate'] ?? sale['created_at'] ?? '';

    String dateStr = '';
    if (saleDate.toString().isNotEmpty) {
      final dt = DateTime.tryParse(saleDate.toString());
      if (dt != null) dateStr = DateFormat('yyyy/MM/dd').format(dt);
      else dateStr = saleDate.toString().split('T').first;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: car info + date
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.point_of_sale, color: Color(0xFF7C3AED), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$carBrand $carModel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              if (dateStr.isNotEmpty) Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Text('$salePrice $saleCurrency', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ]),
          const Divider(height: 16),
          // Details grid
          Row(children: [
            Expanded(child: _saleDetailItem('صاحب السيارة', ownerName.toString())),
            Expanded(child: _saleDetailItem('المشتري', '$buyerName${buyerPhone.toString().isNotEmpty ? '\n$buyerPhone' : ''}')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _saleDetailItem('العمولة', '$commissionAmount $commissionCurrency', valueColor: AppColors.success)),
            Expanded(child: _saleDetailItem('حصة المالك', '$ownerShare $saleCurrency')),
          ]),
        ]),
      ),
    );
  }

  Widget _saleDetailItem(String label, String value, {Color? valueColor}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
    ]);
  }

  // ══════════════════════════════════════════════════════════
  //  TAB 3: سجل الدخول والخروج
  // ══════════════════════════════════════════════════════════

  Widget _buildMovementsTab() {
    // Build movements from cars data (entries) and sales data (exits)
    final movements = <Map<String, dynamic>>[];

    // Entry movements: when car was created
    for (final car in _cars) {
      final createdAt = car['created_at'] ?? car['createdAt'] ?? car['receipt_date'] ?? car['receiptDate'] ?? '';
      movements.add({
        'type': 'entry',
        'date': createdAt.toString(),
        'car': car,
        'reason': null,
        'description': 'دخول سيارة أمانة - ${car['brand'] ?? car['make'] ?? ''} ${car['model'] ?? ''}',
      });
    }

    // Exit movements: sold cars
    for (final sale in _sales) {
      final carId = sale['consignment_car_id'] ?? sale['consignmentCarId'] ?? '';
      final car = _cars.where((c) => (c['id']?.toString() ?? c['_id']?.toString()) == carId.toString()).firstOrNull;
      movements.add({
        'type': 'exit',
        'date': (sale['sale_date'] ?? sale['saleDate'] ?? sale['created_at'] ?? '').toString(),
        'car': car ?? sale,
        'reason': 'sold',
        'description': 'بيع سيارة أمانة - ${sale['car_brand'] ?? sale['carBrand'] ?? ''} ${sale['car_model'] ?? sale['carModel'] ?? ''}',
      });
    }

    // Exit movements: returned cars
    for (final car in _cars.where((c) => c['status'] == 'returned')) {
      final returnedAt = car['returned_at'] ?? car['returnedAt'] ?? car['updated_at'] ?? car['updatedAt'] ?? '';
      movements.add({
        'type': 'exit',
        'date': returnedAt.toString(),
        'car': car,
        'reason': 'returned',
        'description': 'إرجاع سيارة أمانة لصاحبها - ${car['brand'] ?? car['make'] ?? ''} ${car['model'] ?? ''}',
      });
    }

    // Sort by date descending
    movements.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    if (movements.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, size: 48, color: AppColors.textMuted),
        SizedBox(height: 12),
        Text('لا توجد حركات مسجلة بعد', style: TextStyle(color: AppColors.textGray)),
      ]));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemCount: movements.length,
        itemBuilder: (ctx, i) => _buildMovementCard(movements[i]),
      ),
    );
  }

  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final isEntry = movement['type'] == 'entry';
    final car = movement['car'] as Map<String, dynamic>? ?? {};
    final brand = car['brand'] ?? car['make'] ?? car['car_brand'] ?? car['carBrand'] ?? '';
    final model = car['model'] ?? car['car_model'] ?? car['carModel'] ?? '';
    final year = car['year'] ?? '';
    final ownerName = car['owner_name'] ?? car['ownerName'] ?? car['owner_name'] ?? '';
    final vin = car['vin_or_last5'] ?? car['vinOrLast5'] ?? '';
    final plate = car['plate_number'] ?? car['plateNumber'] ?? '';
    final reason = movement['reason'];

    String dateStr = '';
    if (movement['date'].toString().isNotEmpty) {
      final dt = DateTime.tryParse(movement['date']);
      if (dt != null) dateStr = DateFormat('yyyy/MM/dd HH:mm').format(dt);
      else dateStr = movement['date'].toString().split('T').first;
    }

    final typeColor = isEntry ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final typeLabel = isEntry ? 'دخول' : 'خروج';
    final typeIcon = isEntry ? Icons.arrow_downward : Icons.arrow_upward;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(typeIcon, size: 10, color: typeColor),
                  const SizedBox(width: 3),
                  Text(typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor)),
                ]),
              ),
              const SizedBox(width: 6),
              if (reason != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: reason == 'sold' ? AppColors.blue600 : const Color(0xFFEA580C), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    reason == 'sold' ? 'بيع' : 'إرجاع للمالك',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: reason == 'sold' ? AppColors.blue600 : const Color(0xFFEA580C)),
                  ),
                ),
              const Spacer(),
              if (dateStr.isNotEmpty) Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 6),
            Text('$brand $model ${year.toString().isNotEmpty && year.toString() != 'null' ? '($year)' : ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            if (ownerName.toString().isNotEmpty && ownerName.toString() != 'null')
              Text('المالك: $ownerName', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            Row(children: [
              if (vin.toString().isNotEmpty && vin.toString() != 'null')
                Text('شاصي: $vin', style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace')),
              if (vin.toString().isNotEmpty && plate.toString().isNotEmpty) const SizedBox(width: 10),
              if (plate.toString().isNotEmpty && plate.toString() != 'null')
                Text('لوحة: $plate', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ]),
          ])),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  CAR DETAILS BOTTOM SHEET
  // ══════════════════════════════════════════════════════════

  void _showCarDetails(Map<String, dynamic> car) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('${car['brand'] ?? car['make'] ?? ''} ${car['model'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _buildStatusBadge(car['status'] ?? ''),
              const SizedBox(height: 12),
            ])),
            const Divider(height: 1),
            Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
              ..._carDetailRows(car),
              const SizedBox(height: 20),
              // Actions
              if (car['status'] == 'available') ...[
                Row(children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(context); _showSellDialog(car); },
                    icon: const Icon(Icons.shopping_cart, size: 18), label: const Text('بيع'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(context); _showReturnDialog(car); },
                    icon: const Icon(Icons.undo, size: 18), label: const Text('إرجاع'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  )),
                ]),
                const SizedBox(height: 8),
              ],
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _showEditDialog(car); },
                  icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () { Navigator.pop(context); _confirmDelete(car); },
                  icon: const Icon(Icons.delete, size: 18), label: const Text('حذف'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ]),
            ])),
          ])),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(_statusLabel(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  List<Widget> _carDetailRows(Map<String, dynamic> car) {
    final fields = <MapEntry<String, String>>[
      MapEntry('صاحب السيارة', '${car['owner_name'] ?? car['ownerName'] ?? '-'}'),
      MapEntry('هاتف المالك', '${car['owner_phone'] ?? car['ownerPhone'] ?? '-'}'),
      MapEntry('رقم هوية المالك', '${car['owner_id_number'] ?? car['ownerIdNumber'] ?? '-'}'),
      MapEntry('اسم المالك في الأوراق', '${car['document_owner_name'] ?? car['documentOwnerName'] ?? '-'}'),
      MapEntry('نوع السيارة', '${car['brand'] ?? car['make'] ?? '-'}'),
      MapEntry('الموديل', '${car['model'] ?? '-'}'),
      MapEntry('سنة الصنع', '${car['year'] ?? '-'}'),
      MapEntry('اللون', '${car['color'] ?? '-'}'),
      MapEntry('رقم الشاصي', '${car['vin_or_last5'] ?? car['vinOrLast5'] ?? '-'}'),
      MapEntry('رقم اللوحة', '${car['plate_number'] ?? car['plateNumber'] ?? '-'}'),
      MapEntry('المواصفات الإقليمية', '${car['regional_spec'] ?? car['regionalSpec'] ?? '-'}'),
      MapEntry('حادث', _accidentLabel(car['has_accident'] ?? car['hasAccident'])),
      MapEntry('فتحة السقف', '${car['sunroof_type'] ?? car['sunroofType'] ?? '-'}'),
      MapEntry('قطع الصبغ', '${car['paint_pieces'] ?? car['paintPieces'] ?? '-'}'),
      MapEntry('السعر المطلوب', _priceDisplay(car['asking_price'] ?? car['askingPrice'], car['asking_price_currency'] ?? car['askingPriceCurrency'])),
      MapEntry('أجرة الأرضية/يوم', _priceDisplay(car['ground_fee_per_day'] ?? car['groundFeePerDay'], car['ground_fee_currency'] ?? car['groundFeeCurrency'])),
      MapEntry('تاريخ الاستلام', _formatDate(car['receipt_date'] ?? car['receiptDate'])),
      MapEntry('تاريخ الإرجاع', _formatDate(car['returned_at'] ?? car['returnedAt'])),
      MapEntry('الحالة', _statusLabel((car['status'] ?? '').toString())),
      MapEntry('ملاحظات', '${car['notes'] ?? '-'}'),
    ];
    return fields.where((f) => f.value != '-' && f.value != 'null' && f.value.isNotEmpty).map((f) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(f.key, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(f.value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ]),
    )).toList();
  }

  String _accidentLabel(dynamic val) {
    if (val == null || val.toString().isEmpty) return '-';
    if (val == 'yes' || val == true) return 'نعم';
    if (val == 'no' || val == false) return 'لا';
    return val.toString();
  }

  String _priceDisplay(dynamic price, dynamic currency) {
    if (price == null || price.toString().isEmpty || price.toString() == '0' || price.toString() == 'null') return '-';
    return '$price ${currency ?? 'AED'}';
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty || date.toString() == 'null') return '-';
    final dt = DateTime.tryParse(date.toString());
    if (dt != null) return DateFormat('yyyy/MM/dd').format(dt);
    return date.toString().split('T').first;
  }

  // ══════════════════════════════════════════════════════════
  //  ACTIONS MENU
  // ══════════════════════════════════════════════════════════

  void _showActions(Map<String, dynamic> car) {
    final status = (car['status'] ?? '').toString();
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        if (status == 'available') ...[
          ListTile(leading: const Icon(Icons.shopping_cart, color: AppColors.primary), title: const Text('بيع'), onTap: () { Navigator.pop(ctx); _showSellDialog(car); }),
          ListTile(leading: const Icon(Icons.undo, color: Color(0xFFEA580C)), title: const Text('إرجاع للمالك'), onTap: () { Navigator.pop(ctx); _showReturnDialog(car); }),
        ],
        ListTile(leading: const Icon(Icons.edit_outlined, color: AppColors.blue600), title: const Text('تعديل'), onTap: () { Navigator.pop(ctx); _showEditDialog(car); }),
        ListTile(leading: const Icon(Icons.delete_outline, color: AppColors.error), title: const Text('حذف', style: TextStyle(color: AppColors.error)), onTap: () { Navigator.pop(ctx); _confirmDelete(car); }),
        const SizedBox(height: 8),
      ])),
    ));
  }

  // ══════════════════════════════════════════════════════════
  //  ADD CAR DIALOG
  // ══════════════════════════════════════════════════════════

  void _showAddDialog() {
    final ownerNameC = TextEditingController();
    final ownerPhoneC = TextEditingController();
    final ownerIdC = TextEditingController();
    final docOwnerNameC = TextEditingController();
    final modelC = TextEditingController();
    final yearC = TextEditingController(text: '${DateTime.now().year}');
    final vinC = TextEditingController();
    final plateC = TextEditingController();
    final paintPiecesC = TextEditingController();
    final askingPriceC = TextEditingController();
    final groundFeeC = TextEditingController();
    final notesC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String brand = '';
    String color = '';
    String regionalSpec = '';
    String hasAccident = '';
    String sunroofType = '';
    String askingCurrency = 'AED';
    String groundFeeCurrency = 'AED';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة سيارة أمانة جديدة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: SizedBox(width: double.maxFinite, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Owner Info Section ──
        _sectionHeader('معلومات المالك', Icons.person, const Color(0xFF2563EB)),
        _formInput(ownerNameC, 'اسم صاحب السيارة *', Icons.person_outline, validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        _formInput(ownerPhoneC, 'رقم هاتف المالك', Icons.phone_outlined, keyboard: TextInputType.phone),
        _formInput(ownerIdC, 'رقم هوية المالك', Icons.badge_outlined),
        _formInput(docOwnerNameC, 'اسم المالك في الأوراق', Icons.description_outlined),

        // ── Car Data Section ──
        _sectionHeader('بيانات السيارة', Icons.directions_car, AppColors.primary),
        _formDropdown('نوع السيارة *', Icons.directions_car_outlined, brand.isEmpty ? null : brand,
            _carBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            (v) => setS(() => brand = v ?? '')),
        _formInput(modelC, 'الموديل', Icons.model_training),
        Row(children: [
          Expanded(child: _formDropdown('اللون *', Icons.palette_outlined, color.isEmpty ? null : color,
              _carColors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              (v) => setS(() => color = v ?? ''))),
          const SizedBox(width: 8),
          Expanded(child: _formInput(yearC, 'سنة الصنع', Icons.calendar_today, keyboard: TextInputType.number)),
        ]),
        _formInput(plateC, 'رقم اللوحة', Icons.confirmation_number_outlined),
        _formInput(vinC, 'رقم الشاصي أو آخر 5 أرقام *', Icons.qr_code, validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),

        // ── Additional Specs Section ──
        _sectionHeader('مواصفات إضافية', Icons.settings, const Color(0xFFD97706)),
        Row(children: [
          Expanded(child: _formDropdown('المواصفات الإقليمية', Icons.public, regionalSpec.isEmpty ? null : regionalSpec,
              [const DropdownMenuItem(value: '', child: Text('-- غير محدد --')), ..._regionalSpecs.map((s) => DropdownMenuItem(value: s, child: Text(s)))],
              (v) => setS(() => regionalSpec = v ?? ''))),
          const SizedBox(width: 8),
          Expanded(child: _formDropdown('حادث؟', Icons.car_crash_outlined, hasAccident.isEmpty ? null : hasAccident,
              [const DropdownMenuItem(value: '', child: Text('-- غير محدد --')), const DropdownMenuItem(value: 'no', child: Text('لا')), const DropdownMenuItem(value: 'yes', child: Text('نعم'))],
              (v) => setS(() => hasAccident = v ?? ''))),
        ]),
        Row(children: [
          Expanded(child: _formDropdown('فتحة السقف', Icons.roofing, sunroofType.isEmpty ? null : sunroofType,
              [const DropdownMenuItem(value: '', child: Text('-- غير محدد --')), ..._sunroofTypes.map((s) => DropdownMenuItem(value: s, child: Text(s)))],
              (v) => setS(() => sunroofType = v ?? ''))),
          const SizedBox(width: 8),
          Expanded(child: _formInput(paintPiecesC, 'قطع الصبغ', Icons.format_paint, keyboard: TextInputType.number)),
        ]),

        // ── Pricing Section ──
        _sectionHeader('التسعير والملاحظات', Icons.attach_money, const Color(0xFF7C3AED)),
        Row(children: [
          Expanded(flex: 2, child: _formInput(askingPriceC, 'السعر المطلوب', Icons.money, keyboard: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 8),
          Expanded(child: _formDropdown('العملة', Icons.currency_exchange, askingCurrency,
              _currencyCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              (v) => setS(() => askingCurrency = v ?? 'AED'))),
        ]),
        Row(children: [
          Expanded(flex: 2, child: _formInput(groundFeeC, 'أجرة الأرضية/يوم', Icons.calendar_view_day, keyboard: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 8),
          Expanded(child: _formDropdown('العملة', Icons.currency_exchange, groundFeeCurrency,
              _currencyCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              (v) => setS(() => groundFeeCurrency = v ?? 'AED'))),
        ]),
        _formTextArea(notesC, 'ملاحظات', Icons.notes),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            if (brand.isEmpty) { _showSnack('يرجى اختيار نوع السيارة', isError: true); return; }
            if (color.isEmpty) { _showSnack('يرجى اختيار اللون', isError: true); return; }
            Navigator.pop(ctx);
            try {
              await _ds.createConsignmentCar(_token, {
                'owner_name': ownerNameC.text.trim(),
                if (ownerPhoneC.text.trim().isNotEmpty) 'owner_phone': ownerPhoneC.text.trim(),
                if (ownerIdC.text.trim().isNotEmpty) 'owner_id_number': ownerIdC.text.trim(),
                if (docOwnerNameC.text.trim().isNotEmpty) 'document_owner_name': docOwnerNameC.text.trim(),
                'brand': brand,
                if (modelC.text.trim().isNotEmpty) 'model': modelC.text.trim(),
                if (yearC.text.trim().isNotEmpty) 'year': int.tryParse(yearC.text.trim()),
                'color': color,
                'vin_or_last5': vinC.text.trim(),
                if (plateC.text.trim().isNotEmpty) 'plate_number': plateC.text.trim(),
                if (regionalSpec.isNotEmpty) 'regional_spec': regionalSpec,
                if (hasAccident.isNotEmpty) 'has_accident': hasAccident,
                if (sunroofType.isNotEmpty) 'sunroof_type': sunroofType,
                if (paintPiecesC.text.trim().isNotEmpty) 'paint_pieces': int.tryParse(paintPiecesC.text.trim()),
                if (askingPriceC.text.trim().isNotEmpty) 'asking_price': double.tryParse(askingPriceC.text.trim()),
                'asking_price_currency': askingCurrency,
                if (groundFeeC.text.trim().isNotEmpty) 'ground_fee_per_day': double.tryParse(groundFeeC.text.trim()),
                if (groundFeeC.text.trim().isNotEmpty) 'ground_fee_currency': groundFeeCurrency,
                'status': 'available',
                if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
                'receipt_date': DateTime.now().toIso8601String(),
              });
              _loadData();
              _showSnack('تمت إضافة سيارة الأمانة بنجاح');
            } catch (e) {
              _showSnack(e is ApiException ? e.message : 'فشل إضافة سيارة الأمانة', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة السيارة', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    )));
  }

  // ══════════════════════════════════════════════════════════
  //  EDIT CAR DIALOG
  // ══════════════════════════════════════════════════════════

  void _showEditDialog(Map<String, dynamic> car) {
    final id = car['id']?.toString() ?? car['_id']?.toString();
    if (id == null) return;

    final ownerNameC = TextEditingController(text: car['owner_name'] ?? car['ownerName'] ?? '');
    final ownerPhoneC = TextEditingController(text: car['owner_phone'] ?? car['ownerPhone'] ?? '');
    final ownerIdC = TextEditingController(text: car['owner_id_number'] ?? car['ownerIdNumber'] ?? '');
    final docOwnerNameC = TextEditingController(text: car['document_owner_name'] ?? car['documentOwnerName'] ?? '');
    final modelC = TextEditingController(text: car['model'] ?? '');
    final yearC = TextEditingController(text: '${car['year'] ?? ''}');
    final vinC = TextEditingController(text: car['vin_or_last5'] ?? car['vinOrLast5'] ?? '');
    final plateC = TextEditingController(text: car['plate_number'] ?? car['plateNumber'] ?? '');
    final paintPiecesC = TextEditingController(text: '${car['paint_pieces'] ?? car['paintPieces'] ?? ''}'.replaceAll('null', ''));
    final askingPriceC = TextEditingController(text: '${car['asking_price'] ?? car['askingPrice'] ?? ''}'.replaceAll('null', '').replaceAll('0', ''));
    final groundFeeC = TextEditingController(text: '${car['ground_fee_per_day'] ?? car['groundFeePerDay'] ?? ''}'.replaceAll('null', ''));
    final notesC = TextEditingController(text: car['notes'] ?? '');
    final formKey = GlobalKey<FormState>();

    String brand = car['brand'] ?? car['make'] ?? '';
    String color = car['color'] ?? '';
    String regionalSpec = car['regional_spec'] ?? car['regionalSpec'] ?? '';
    String hasAccident = (car['has_accident'] ?? car['hasAccident'] ?? '').toString();
    if (hasAccident == 'null') hasAccident = '';
    String sunroofType = car['sunroof_type'] ?? car['sunroofType'] ?? '';
    String askingCurrency = car['asking_price_currency'] ?? car['askingPriceCurrency'] ?? 'AED';
    String groundFeeCurrency = car['ground_fee_currency'] ?? car['groundFeeCurrency'] ?? 'AED';
    String status = car['status'] ?? 'available';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('تعديل سيارة الأمانة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      content: SizedBox(width: double.maxFinite, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Owner Info ──
        _sectionHeader('معلومات المالك', Icons.person, const Color(0xFF2563EB)),
        _formInput(ownerNameC, 'اسم صاحب السيارة *', Icons.person_outline, validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
        _formInput(ownerPhoneC, 'رقم هاتف المالك', Icons.phone_outlined, keyboard: TextInputType.phone),
        _formInput(ownerIdC, 'رقم هوية المالك', Icons.badge_outlined),
        _formInput(docOwnerNameC, 'اسم المالك في الأوراق', Icons.description_outlined),

        // ── Car Data ──
        _sectionHeader('بيانات السيارة', Icons.directions_car, AppColors.primary),
        _formDropdown('نوع السيارة *', Icons.directions_car_outlined, brand.isEmpty ? null : brand,
            _carBrands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            (v) => setS(() => brand = v ?? '')),
        _formInput(modelC, 'الموديل', Icons.model_training),
        Row(children: [
          Expanded(child: _formDropdown('اللون *', Icons.palette_outlined, color.isEmpty ? null : color,
              _carColors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              (v) => setS(() => color = v ?? ''))),
          const SizedBox(width: 8),
          Expanded(child: _formInput(yearC, 'سنة الصنع', Icons.calendar_today, keyboard: TextInputType.number)),
        ]),
        _formInput(plateC, 'رقم اللوحة', Icons.confirmation_number_outlined),
        _formInput(vinC, 'رقم الشاصي أو آخر 5 أرقام *', Icons.qr_code, validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),

        // ── Additional Specs ──
        _sectionHeader('مواصفات إضافية', Icons.settings, const Color(0xFFD97706)),
        Row(children: [
          Expanded(child: _formDropdown('المواصفات الإقليمية', Icons.public, regionalSpec.isEmpty ? null : regionalSpec,
              [const DropdownMenuItem(value: '', child: Text('-- غير محدد --')), ..._regionalSpecs.map((s) => DropdownMenuItem(value: s, child: Text(s)))],
              (v) => setS(() => regionalSpec = v ?? ''))),
          const SizedBox(width: 8),
          Expanded(child: _formDropdown('حادث؟', Icons.car_crash_outlined, hasAccident.isEmpty ? null : hasAccident,
              [const DropdownMenuItem(value: '', child: Text('-- غير محدد --')), const DropdownMenuItem(value: 'no', child: Text('لا')), const DropdownMenuItem(value: 'yes', child: Text('نعم'))],
              (v) => setS(() => hasAccident = v ?? ''))),
        ]),
        Row(children: [
          Expanded(child: _formDropdown('فتحة السقف', Icons.roofing, sunroofType.isEmpty ? null : sunroofType,
              [const DropdownMenuItem(value: '', child: Text('-- غير محدد --')), ..._sunroofTypes.map((s) => DropdownMenuItem(value: s, child: Text(s)))],
              (v) => setS(() => sunroofType = v ?? ''))),
          const SizedBox(width: 8),
          Expanded(child: _formInput(paintPiecesC, 'قطع الصبغ', Icons.format_paint, keyboard: TextInputType.number)),
        ]),

        // ── Pricing ──
        _sectionHeader('التسعير', Icons.attach_money, const Color(0xFF7C3AED)),
        Row(children: [
          Expanded(flex: 2, child: _formInput(askingPriceC, 'السعر المطلوب', Icons.money, keyboard: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 8),
          Expanded(child: _formDropdown('العملة', Icons.currency_exchange, askingCurrency,
              _currencyCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              (v) => setS(() => askingCurrency = v ?? 'AED'))),
        ]),
        Row(children: [
          Expanded(flex: 2, child: _formInput(groundFeeC, 'أجرة الأرضية/يوم', Icons.calendar_view_day, keyboard: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 8),
          Expanded(child: _formDropdown('العملة', Icons.currency_exchange, groundFeeCurrency,
              _currencyCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              (v) => setS(() => groundFeeCurrency = v ?? 'AED'))),
        ]),

        // ── Status ──
        _formDropdown('الحالة', Icons.flag_outlined, status,
            _statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            (v) => setS(() => status = v ?? 'available')),
        _formTextArea(notesC, 'ملاحظات', Icons.notes),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(ctx);
            try {
              await _ds.updateConsignmentCar(_token, id, {
                'owner_name': ownerNameC.text.trim(),
                'owner_phone': ownerPhoneC.text.trim(),
                'owner_id_number': ownerIdC.text.trim(),
                'document_owner_name': docOwnerNameC.text.trim(),
                'brand': brand,
                'model': modelC.text.trim(),
                'year': int.tryParse(yearC.text.trim()),
                'color': color,
                'vin_or_last5': vinC.text.trim(),
                'plate_number': plateC.text.trim(),
                'regional_spec': regionalSpec,
                'has_accident': hasAccident.isNotEmpty ? hasAccident : null,
                'sunroof_type': sunroofType,
                'paint_pieces': paintPiecesC.text.trim().isNotEmpty ? int.tryParse(paintPiecesC.text.trim()) : null,
                'asking_price': askingPriceC.text.trim().isNotEmpty ? double.tryParse(askingPriceC.text.trim()) : null,
                'asking_price_currency': askingCurrency,
                'ground_fee_per_day': groundFeeC.text.trim().isNotEmpty ? double.tryParse(groundFeeC.text.trim()) : null,
                'ground_fee_currency': groundFeeCurrency,
                'status': status,
                'notes': notesC.text.trim(),
              });
              _loadData();
              _showSnack('تم تحديث بيانات السيارة بنجاح');
            } catch (e) {
              _showSnack(e is ApiException ? e.message : 'فشل تعديل سيارة الأمانة', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حفظ التعديلات', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    )));
  }

  // ══════════════════════════════════════════════════════════
  //  SELL CAR DIALOG
  // ══════════════════════════════════════════════════════════

  void _showSellDialog(Map<String, dynamic> car) {
    final id = car['id']?.toString() ?? car['_id']?.toString();
    if (id == null) return;

    final brand = car['brand'] ?? car['make'] ?? '';
    final model = car['model'] ?? '';
    final ownerName = car['owner_name'] ?? car['ownerName'] ?? '';
    final vin = car['vin_or_last5'] ?? car['vinOrLast5'] ?? '';
    final initPrice = car['asking_price'] ?? car['askingPrice'];
    final initCurrency = car['asking_price_currency'] ?? car['askingPriceCurrency'] ?? 'AED';

    final salePriceC = TextEditingController(text: initPrice != null && initPrice.toString() != '0' && initPrice.toString() != 'null' ? initPrice.toString() : '');
    final commissionC = TextEditingController();
    final buyerNameC = TextEditingController();
    final buyerPhoneC = TextEditingController();
    final notesC = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String saleCurrency = initCurrency.toString();
    String commissionCurrency = 'AED';
    String receivingAccountId = _getDefaultCashBoxId();

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final salePrice = double.tryParse(salePriceC.text) ?? 0;
      final commissionAmount = double.tryParse(commissionC.text) ?? 0;
      final ownerShare = salePrice - commissionAmount;

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('بيع سيارة الأمانة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: SizedBox(width: double.maxFinite, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Car info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.directions_car, size: 18, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Text('$brand $model', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              Text('المالك: $ownerName', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text('الشاصي: $vin', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace')),
              if (initPrice != null && initPrice.toString() != '0' && initPrice.toString() != 'null')
                Text('السعر المطلوب: $initPrice $initCurrency', style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),

          // Sale price
          Row(children: [
            Expanded(flex: 2, child: _formInput(salePriceC, 'سعر البيع *', Icons.attach_money,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                onChanged: (_) => setS(() {}))),
            const SizedBox(width: 8),
            Expanded(child: _formDropdown('العملة', Icons.currency_exchange, saleCurrency,
                _currencyCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                (v) => setS(() => saleCurrency = v ?? 'AED'))),
          ]),

          // Commission
          Row(children: [
            Expanded(flex: 2, child: _formInput(commissionC, 'مبلغ العمولة *', Icons.percent,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                onChanged: (_) => setS(() {}))),
            const SizedBox(width: 8),
            Expanded(child: _formDropdown('العملة', Icons.currency_exchange, commissionCurrency,
                _currencyCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                (v) => setS(() => commissionCurrency = v ?? 'AED'))),
          ]),

          // Owner share display
          if (salePrice > 0 && commissionAmount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('حصة المالك:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textGray)),
                Text('${ownerShare.toStringAsFixed(0)} $saleCurrency', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF22C55E))),
              ]),
            ),

          // Buyer info
          _formInput(buyerNameC, 'اسم المشتري *', Icons.person_outline, validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null),
          _formInput(buyerPhoneC, 'هاتف المشتري', Icons.phone_outlined, keyboard: TextInputType.phone),

          // Receiving account
          if (_cashBoxAccounts.isNotEmpty)
            _formDropdown('صندوق الاستلام', Icons.account_balance_wallet, receivingAccountId.isNotEmpty ? receivingAccountId : null,
                _cashBoxAccounts.map((a) => DropdownMenuItem(value: (a['id'] ?? a['_id']).toString(), child: Text(a['name'] ?? ''))).toList(),
                (v) => setS(() => receivingAccountId = v ?? '')),

          _formTextArea(notesC, 'ملاحظات', Icons.notes),
        ])))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                // Create consignment sale with USD conversions (matching React)
                final salePriceVal = double.tryParse(salePriceC.text.trim()) ?? 0;
                final commissionVal = double.tryParse(commissionC.text.trim()) ?? 0;
                final salePriceUSD = _convertToUSD(salePriceVal, saleCurrency);
                final commissionAmountUSD = _convertToUSD(commissionVal, commissionCurrency);
                final ownerShareUSD = salePriceUSD - commissionAmountUSD;

                await _ds.createConsignmentSale(_token, {
                  'consignment_car_id': id,
                  'car_brand': brand,
                  'car_model': model,
                  'car_color': car['color'] ?? '',
                  'owner_name': ownerName,
                  'sale_price': salePriceVal,
                  'sale_currency': saleCurrency,
                  'sale_price_usd': salePriceUSD,
                  'commission_amount': commissionVal,
                  'commission_currency': commissionCurrency,
                  'commission_amount_usd': commissionAmountUSD,
                  'owner_share': ownerShare,
                  'owner_share_usd': ownerShareUSD,
                  'sale_date': DateTime.now().toIso8601String().split('T').first,
                  'buyer_name': buyerNameC.text.trim(),
                  if (buyerPhoneC.text.trim().isNotEmpty) 'buyer_phone': buyerPhoneC.text.trim(),
                  if (receivingAccountId.isNotEmpty) 'receiving_account_id': receivingAccountId,
                  if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
                });
                // Update car status to sold
                await _ds.updateConsignmentCar(_token, id, {'status': 'sold'});
                _loadData();
                _showSnack('تم بيع السيارة بنجاح. العمولة: ${commissionC.text.trim()} $commissionCurrency');
              } catch (e) {
                _showSnack(e is ApiException ? e.message : 'فشل عملية البيع', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('تأكيد البيع', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }));
  }

  // ══════════════════════════════════════════════════════════
  //  RETURN CAR DIALOG
  // ══════════════════════════════════════════════════════════

  void _showReturnDialog(Map<String, dynamic> car) {
    final id = car['id']?.toString() ?? car['_id']?.toString();
    if (id == null) return;

    final brand = car['brand'] ?? car['make'] ?? '';
    final model = car['model'] ?? '';
    final ownerName = car['owner_name'] ?? car['ownerName'] ?? '';
    final vin = car['vin_or_last5'] ?? car['vinOrLast5'] ?? '';
    final plate = car['plate_number'] ?? car['plateNumber'] ?? '';
    final groundFeePerDay = double.tryParse((car['ground_fee_per_day'] ?? car['groundFeePerDay'] ?? '0').toString()) ?? 0;
    final groundFeeCurrency = (car['ground_fee_currency'] ?? car['groundFeeCurrency'] ?? 'AED').toString();
    final receiptDateStr = (car['receipt_date'] ?? car['receiptDate'] ?? car['created_at'] ?? car['createdAt'] ?? '').toString();

    final notesC = TextEditingController();
    DateTime returnDate = DateTime.now();
    String warehouseId = 'main';
    bool collectFee = groundFeePerDay > 0;
    String cashAccountId = _getDefaultCashBoxId();
    String revenueAccountId = (_revenueAccounts.firstOrNull?['id'] ?? _revenueAccounts.firstOrNull?['_id'] ?? '').toString();

    // Calculate days stored
    int daysStored = 0;
    if (receiptDateStr.isNotEmpty) {
      final receiptDate = DateTime.tryParse(receiptDateStr);
      if (receiptDate != null) {
        daysStored = returnDate.difference(receiptDate).inDays;
        if (daysStored < 0) daysStored = 0;
      }
    }
    double totalFee = daysStored * groundFeePerDay;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFEA580C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.undo, color: Color(0xFFEA580C), size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Text('إرجاع سيارة أمانة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
      ]),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Car info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFEA580C).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.15))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('بيانات السيارة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
            const SizedBox(height: 6),
            _infoRow('المالك', ownerName.toString()),
            _infoRow('السيارة', '$brand $model'),
            _infoRow('الشاصي', vin.toString()),
            if (plate.toString().isNotEmpty && plate.toString() != 'null') _infoRow('اللوحة', plate.toString()),
          ]),
        ),
        const SizedBox(height: 12),

        // Return date
        _formDatePicker(ctx, 'تاريخ الإرجاع', returnDate, (picked) {
          setS(() {
            returnDate = picked;
            if (receiptDateStr.isNotEmpty) {
              final receipt = DateTime.tryParse(receiptDateStr);
              if (receipt != null) {
                daysStored = picked.difference(receipt).inDays;
                if (daysStored < 0) daysStored = 0;
                totalFee = daysStored * groundFeePerDay;
              }
            }
          });
        }),

        // Warehouse
        _formDropdown('مكان الاستلام', Icons.warehouse, warehouseId,
            _warehouses.map((w) => DropdownMenuItem(value: w['id'], child: Text(w['name']!))).toList(),
            (v) => setS(() => warehouseId = v ?? 'main')),

        // Ground fee info
        if (groundFeePerDay > 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: const Color(0xFF2563EB).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.15))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('أجور الأرضية', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Row(children: [
                  const Text('قبض الأجور', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 6),
                  Switch(
                    value: collectFee, activeColor: AppColors.primary,
                    onChanged: (v) => setS(() => collectFee = v),
                  ),
                ]),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _feeItem('عدد الأيام', '$daysStored', const Color(0xFF2563EB)),
                const SizedBox(width: 12),
                _feeItem('الأجرة/يوم', '$groundFeePerDay $groundFeeCurrency', AppColors.textDark),
                const SizedBox(width: 12),
                _feeItem('الإجمالي', '${totalFee.toStringAsFixed(0)} $groundFeeCurrency', const Color(0xFF22C55E)),
              ]),
            ]),
          ),
        ],

        // Accounts for fee collection
        if (collectFee && totalFee > 0) ...[
          if (_cashBoxAccounts.isNotEmpty)
            _formDropdown('حساب القبض *', Icons.account_balance_wallet, cashAccountId.isNotEmpty ? cashAccountId : null,
                _cashBoxAccounts.map((a) => DropdownMenuItem(value: (a['id'] ?? a['_id']).toString(), child: Text(a['name'] ?? ''))).toList(),
                (v) => setS(() => cashAccountId = v ?? '')),
          if (_revenueAccounts.isNotEmpty)
            _formDropdown('حساب الإيرادات *', Icons.account_balance, revenueAccountId.isNotEmpty ? revenueAccountId : null,
                _revenueAccounts.map((a) => DropdownMenuItem(value: (a['id'] ?? a['_id']).toString(), child: Text(a['name'] ?? ''))).toList(),
                (v) => setS(() => revenueAccountId = v ?? '')),
        ],

        _formTextArea(notesC, 'ملاحظات', Icons.notes),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (collectFee && totalFee > 0) {
              if (cashAccountId.isEmpty || revenueAccountId.isEmpty) {
                _showSnack('يرجى تحديد حسابات القبض والإيرادات', isError: true);
                return;
              }
            }
            Navigator.pop(ctx);
            try {
              final warehouseName = _warehouses.firstWhere((w) => w['id'] == warehouseId, orElse: () => {'name': warehouseId})['name'];
              final returnNotes = '${notesC.text.trim().isNotEmpty ? '${notesC.text.trim()} - ' : ''}مكان الاستلام: $warehouseName';

              await _ds.updateConsignmentCar(_token, id, {
                'status': 'returned',
                'returned_at': returnDate.toIso8601String(),
                'return_notes': returnNotes,
                'collect_fee': collectFee && totalFee > 0,
                if (collectFee && totalFee > 0) ...{
                  'days_stored': daysStored,
                  'ground_fee_per_day': groundFeePerDay,
                  'ground_fee_total': totalFee,
                  'ground_fee_currency': groundFeeCurrency,
                  'cash_account_id': cashAccountId,
                  'revenue_account_id': revenueAccountId,
                },
              });
              _loadData();
              final msg = collectFee && totalFee > 0
                  ? 'تم إرجاع السيارة وقبض ${totalFee.toStringAsFixed(0)} $groundFeeCurrency أجور أرضية'
                  : 'تم إرجاع السيارة لصاحبها بنجاح';
              _showSnack(msg);
            } catch (e) {
              _showSnack(e is ApiException ? e.message : 'فشل إرجاع السيارة', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(
            collectFee && totalFee > 0 ? 'إرجاع وقبض ${totalFee.toStringAsFixed(0)} $groundFeeCurrency' : 'إرجاع السيارة',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    )));
  }

  Widget _feeItem(String label, String value, Color valueColor) {
    return Expanded(child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor)),
    ]));
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  DELETE CONFIRMATION
  // ══════════════════════════════════════════════════════════

  void _confirmDelete(Map<String, dynamic> car) {
    final id = car['id']?.toString() ?? car['_id']?.toString();
    if (id == null) return;
    final name = car['owner_name'] ?? car['ownerName'] ?? '';
    final label = name.toString().isNotEmpty ? name : 'سيارة الأمانة';

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('حذف سيارة أمانة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('هل أنت متأكد من حذف سيارة "$label"؟', textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await _ds.deleteConsignmentCar(_token, id);
              _loadData();
              _showSnack('تم حذف السيارة بنجاح');
            } catch (e) {
              _showSnack(e is ApiException ? e.message : 'فشل حذف سيارة الأمانة', isError: true);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  // ══════════════════════════════════════════════════════════
  //  FORM HELPERS
  // ══════════════════════════════════════════════════════════

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _formInput(TextEditingController c, String label, IconData icon, {
    TextInputType? keyboard,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: c,
      keyboardType: keyboard,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true, fillColor: AppColors.bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
  );

  Widget _formTextArea(TextEditingController c, String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: c,
      maxLines: 3, minLines: 2,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 40), child: Icon(icon, size: 20)),
        filled: true, fillColor: AppColors.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
  );

  Widget _formDropdown(String label, IconData icon, String? value, List<DropdownMenuItem<String>> items, void Function(String?) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true, fillColor: AppColors.bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    ),
  );

  Widget _formDatePicker(BuildContext dialogCtx, String label, DateTime currentValue, void Function(DateTime) onPicked) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: dialogCtx,
          initialDate: currentValue,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)), child: child!),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          filled: true, fillColor: AppColors.bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        child: Text(DateFormat('yyyy-MM-dd').format(currentValue), style: const TextStyle(fontSize: 14)),
      ),
    ),
  );

  // ── Snackbar ──

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ));
  }
}
