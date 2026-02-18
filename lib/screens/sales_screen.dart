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
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  // Display currency
  String _displayCurrency = 'USD';
  static const List<Map<String, String>> _currencyOptions = [
    {'code': 'USD', 'symbol': '\$', 'label': 'USD \$'},
    {'code': 'AED', 'symbol': 'د.إ', 'label': 'AED د.إ'},
    {'code': 'KRW', 'symbol': '₩', 'label': 'KRW ₩'},
    {'code': 'CNY', 'symbol': '¥', 'label': 'CNY ¥'},
    {'code': 'SYP', 'symbol': 'ل.س', 'label': 'SYP ل.س'},
    {'code': 'SAR', 'symbol': 'ر.س', 'label': 'SAR ر.س'},
  ];

  static const List<Map<String, String>> _paymentMethods = [
    {'value': 'cash', 'label': 'نقداً'},
    {'value': 'transfer', 'label': 'تحويل بنكي'},
    {'value': 'check', 'label': 'شيك'},
    {'value': 'credit', 'label': 'آجل'},
    {'value': 'installment', 'label': 'تقسيط'},
  ];

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _token =>
      Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _ds.getSales(_token),
        _ds.getCars(_token),
        _ds.getCustomers(_token),
        _ds.getExpenses(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _sales = results[0];
        _cars = results[1];
        _customers = results[2];
        _expenses = results[3];
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'فشل تحميل المبيعات';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_sales);
    } else {
      _filtered = _sales.where((s) {
        final customer = _customerDisplayName(s).toLowerCase();
        final car = _carDisplayInfo(s).toLowerCase();
        final vin = _getCarVin(s).toLowerCase();
        final amount = (s['sale_price'] ??
                s['selling_price'] ??
                s['sellingPrice'] ??
                s['amount'] ??
                s['total'] ??
                '')
            .toString();
        final notes = (s['notes'] ?? '').toString().toLowerCase();
        final method = (s['payment_method'] ?? '').toString().toLowerCase();
        return customer.contains(q) ||
            car.contains(q) ||
            vin.contains(q) ||
            amount.contains(q) ||
            notes.contains(q) ||
            method.contains(q);
      }).toList();
    }
  }

  // ── Lookup helpers ──

  String _customerDisplayName(Map<String, dynamic> sale) {
    final customerId = sale['customer_id']?.toString();
    if (customerId != null && customerId.isNotEmpty) {
      final match = _customers
          .where(
              (c) => (c['id']?.toString() ?? c['_id']?.toString()) == customerId)
          .firstOrNull;
      if (match != null) {
        return (match['name'] ?? '').toString();
      }
    }
    return (sale['customer_name'] ??
            sale['customerName'] ??
            sale['buyer_name'] ??
            '')
        .toString();
  }

  String _customerDisplayCode(Map<String, dynamic> sale) {
    final customerId = sale['customer_id']?.toString();
    if (customerId != null && customerId.isNotEmpty) {
      final match = _customers
          .where(
              (c) => (c['id']?.toString() ?? c['_id']?.toString()) == customerId)
          .firstOrNull;
      if (match != null) {
        return (match['customer_code'] ?? match['customerCode'] ?? '')
            .toString();
      }
    }
    return '';
  }

  String _customerPhone(Map<String, dynamic> sale) {
    final customerId = sale['customer_id']?.toString();
    if (customerId != null && customerId.isNotEmpty) {
      final match = _customers
          .where(
              (c) => (c['id']?.toString() ?? c['_id']?.toString()) == customerId)
          .firstOrNull;
      if (match != null) {
        return (match['phone'] ?? '').toString();
      }
    }
    return (sale['buyer_phone'] ?? sale['buyerPhone'] ?? '').toString();
  }

  Map<String, dynamic>? _getCarData(Map<String, dynamic> sale) {
    final carId = sale['car_id']?.toString();
    if (carId != null && carId.isNotEmpty) {
      return _cars
          .where(
              (c) => (c['id']?.toString() ?? c['_id']?.toString()) == carId)
          .firstOrNull;
    }
    return null;
  }

  String _carDisplayInfo(Map<String, dynamic> sale) {
    final car = _getCarData(sale);
    if (car != null) {
      final brand = car['brand'] ?? car['make'] ?? '';
      final model = car['model'] ?? '';
      final year = car['year'] ?? '';
      return '$brand $model${year.toString().isNotEmpty ? ' ($year)' : ''}'
          .trim();
    }
    final make = sale['car_make'] ?? sale['make'] ?? '';
    final model = sale['car_model'] ?? sale['model'] ?? '';
    return '$make $model'.trim();
  }

  String _getCarVin(Map<String, dynamic> sale) {
    final car = _getCarData(sale);
    if (car != null) {
      return (car['vin'] ?? car['chassis_number'] ?? '').toString();
    }
    return (sale['vin'] ?? '').toString();
  }

  double _getCarCost(Map<String, dynamic> sale) {
    final car = _getCarData(sale);
    if (car == null) return 0;
    double cost = 0;
    cost += _parseDouble(car['purchase_price'] ?? car['purchasePrice'] ?? car['cost'] ?? 0);
    cost += _parseDouble(car['shipping_cost'] ?? car['shippingCost'] ?? 0);
    cost += _parseDouble(car['customs_cost'] ?? car['customsCost'] ?? 0);
    cost += _parseDouble(car['handling_cost'] ?? car['handlingCost'] ?? 0);
    cost += _parseDouble(car['other_costs'] ?? car['otherCosts'] ?? 0);

    // Add expenses linked to this car
    final carId = sale['car_id']?.toString();
    if (carId != null) {
      for (final exp in _expenses) {
        if ((exp['car_id']?.toString() ?? exp['carId']?.toString()) == carId) {
          cost += _parseDouble(exp['amount'] ?? 0);
        }
      }
    }
    return cost;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double _getSalePrice(Map<String, dynamic> sale) {
    return _parseDouble(sale['sale_price'] ??
        sale['selling_price'] ??
        sale['sellingPrice'] ??
        sale['amount'] ??
        sale['total'] ??
        0);
  }

  bool _isCancelled(Map<String, dynamic> sale) {
    final status = (sale['status'] ?? '').toString().toLowerCase();
    return status == 'cancelled' || status == 'canceled';
  }

  String _paymentMethodLabel(String? method) {
    if (method == null || method.isEmpty) return '';
    for (final m in _paymentMethods) {
      if (m['value'] == method.toLowerCase()) return m['label']!;
    }
    return method;
  }

  Color _paymentMethodColor(String? method) {
    if (method == null || method.isEmpty) return AppColors.textMuted;
    switch (method.toLowerCase()) {
      case 'cash':
        return AppColors.success;
      case 'transfer':
        return AppColors.blue600;
      case 'check':
        return const Color(0xFF7C3AED);
      case 'credit':
        return const Color(0xFFD97706);
      case 'installment':
        return const Color(0xFFDB2777);
      default:
        return AppColors.textMuted;
    }
  }

  String _currencySymbol(String code) {
    for (final c in _currencyOptions) {
      if (c['code'] == code) return c['symbol']!;
    }
    return code;
  }

  String _formatAmount(double amount, [String? currency]) {
    final cur = currency ?? _displayCurrency;
    final sym = _currencySymbol(cur);
    final formatted =
        amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    return '$sym$formatted';
  }

  // ── Stats calculation ──

  Map<String, dynamic> get _stats {
    final activeSales = _sales.where((s) => !_isCancelled(s)).toList();
    double totalRevenue = 0;
    double totalCost = 0;
    for (final s in activeSales) {
      totalRevenue += _getSalePrice(s);
      totalCost += _getCarCost(s);
    }
    final totalProfit = totalRevenue - totalCost;
    return {
      'count': activeSales.length,
      'revenue': totalRevenue,
      'cost': totalCost,
      'profit': totalProfit,
      'avgProfit':
          activeSales.isNotEmpty ? totalProfit / activeSales.length : 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المبيعات',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Currency selector
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _displayCurrency,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.white, size: 20),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
                selectedItemBuilder: (ctx) => _currencyOptions
                    .map((c) => Center(
                        child: Text(c['code']!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700))))
                    .toList(),
                items: _currencyOptions
                    .map((c) => DropdownMenuItem(
                        value: c['code'],
                        child: Text(c['label']!,
                            style: const TextStyle(
                                color: AppColors.textDark, fontSize: 13))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _displayCurrency = v);
                },
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.salesPage),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('بيع سيارة',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      // Stats cards
                      SliverToBoxAdapter(child: _buildStatsCards(stats)),
                      // Search bar
                      SliverToBoxAdapter(child: _buildSearchBar()),
                      // Count indicator
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          color: Colors.white,
                          child: Text(
                            '${_filtered.length} عملية بيع',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: Divider(height: 1)),
                      // Sales list
                      _filtered.isEmpty
                          ? SliverFillRemaining(child: _buildEmpty())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildCard(_filtered[i]),
                                childCount: _filtered.length,
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    final profit = (stats['profit'] as double?) ?? 0;
    final isProfit = profit >= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statCard(
              'إجمالي المبيعات',
              '${stats['count']}',
              Icons.shopping_cart_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF3E8FF),
            ),
            _statCard(
              'إجمالي الإيرادات',
              _formatAmount((stats['revenue'] as double?) ?? 0),
              Icons.attach_money,
              AppColors.blue600,
              const Color(0xFFEFF6FF),
            ),
            _statCard(
              isProfit ? 'إجمالي الأرباح' : 'إجمالي الخسائر',
              _formatAmount(profit.abs()),
              isProfit ? Icons.trending_up : Icons.trending_down,
              isProfit ? AppColors.success : AppColors.error,
              isProfit
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEF2F2),
            ),
            _statCard(
              'متوسط الربح',
              _formatAmount(((stats['avgProfit'] as double?) ?? 0).abs()),
              Icons.trending_up,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      width: 155,
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textGray,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() => _applyFilter()),
        decoration: InputDecoration(
          hintText: 'بحث بالمشتري أو الشاصي أو البراند...',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textMuted, size: 22),
          filled: true,
          fillColor: AppColors.bgLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: 12),
        Text(_error!),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadData,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('إعادة المحاولة'),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.point_of_sale_outlined, size: 48, color: AppColors.textMuted),
        SizedBox(height: 12),
        Text('لا توجد مبيعات', style: TextStyle(color: AppColors.textGray)),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> sale) {
    final customerName = _customerDisplayName(sale);
    final carInfo = _carDisplayInfo(sale);
    final vin = _getCarVin(sale);
    final salePrice = _getSalePrice(sale);
    final cost = _getCarCost(sale);
    final profit = salePrice - cost;
    final date = sale['sale_date'] ?? sale['date'] ?? sale['created_at'] ?? '';
    final currency = (sale['currency'] ?? 'USD').toString();
    final notes = sale['notes'] ?? '';
    final paymentMethod = (sale['payment_method'] ?? '').toString();
    final cancelled = _isCancelled(sale);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: cancelled ? const Color(0xFFFEF2F2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
        border: cancelled
            ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSaleDetails(sale),
        onLongPress: () => _showActions(sale),
        child: Opacity(
          opacity: cancelled ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Car icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cancelled
                            ? AppColors.error.withValues(alpha: 0.1)
                            : const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: cancelled
                            ? AppColors.error
                            : const Color(0xFF7C3AED),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Car info and buyer
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  carInfo.isNotEmpty ? carInfo : 'سيارة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                    decoration: cancelled
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: AppColors.error,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cancelled)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ملغى',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.error),
                                  ),
                                ),
                            ],
                          ),
                          if (customerName.isNotEmpty)
                            Text(
                              customerName,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textGray),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // VIN
                if (vin.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'VIN: $vin',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Price/Cost/Profit row
                Row(
                  children: [
                    // Sale price
                    Expanded(
                      child: _miniStat(
                        'سعر البيع',
                        '$salePrice $currency',
                        cancelled ? AppColors.textMuted : AppColors.primary,
                      ),
                    ),
                    // Cost
                    if (cost > 0)
                      Expanded(
                        child: _miniStat(
                          'التكلفة',
                          _formatAmount(cost),
                          AppColors.textGray,
                        ),
                      ),
                    // Profit
                    if (cost > 0 && !cancelled)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: (profit >= 0
                                    ? AppColors.success
                                    : AppColors.error)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            children: [
                              Text(
                                profit >= 0 ? 'ربح' : 'خسارة',
                                style: const TextStyle(
                                    fontSize: 9, color: AppColors.textMuted),
                              ),
                              Text(
                                '${profit >= 0 ? '+' : ''}${_formatAmount(profit)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: profit >= 0
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Bottom row: date, payment method, notes
                Row(
                  children: [
                    if (date.toString().isNotEmpty)
                      Text(
                        date.toString().split('T').first,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                      ),
                    const Spacer(),
                    if (paymentMethod.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _paymentMethodColor(paymentMethod)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _paymentMethodLabel(paymentMethod),
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _paymentMethodColor(paymentMethod)),
                        ),
                      ),
                  ],
                ),
                if (notes.toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notes.toString(),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Sale Details Bottom Sheet ──

  void _showSaleDetails(Map<String, dynamic> sale) {
    final customerName = _customerDisplayName(sale);
    final customerCode = _customerDisplayCode(sale);
    final customerPhone = _customerPhone(sale);
    final carInfo = _carDisplayInfo(sale);
    final vin = _getCarVin(sale);
    final salePrice = _getSalePrice(sale);
    final cost = _getCarCost(sale);
    final profit = salePrice - cost;
    final date = sale['sale_date'] ?? sale['date'] ?? sale['created_at'] ?? '';
    final currency = (sale['currency'] ?? 'USD').toString();
    final notes = sale['notes'] ?? '';
    final paymentMethod = (sale['payment_method'] ?? '').toString();
    final status = (sale['status'] ?? '').toString();
    final cancelled = _isCancelled(sale);
    final car = _getCarData(sale);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              // Title
              Center(
                child: Text(
                  'تفاصيل عملية البيع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cancelled ? AppColors.error : AppColors.textDark,
                  ),
                ),
              ),
              if (cancelled)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('عملية بيع ملغاة',
                        style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(height: 16),
              // Car info section
              _detailSection('السيارة', Icons.directions_car, [
                _detailRow2('البراند/الموديل', carInfo),
                if (vin.isNotEmpty) _detailRow2('رقم الشاصي (VIN)', vin),
                if (car != null && car['color'] != null)
                  _detailRow2('اللون', car['color'].toString()),
              ]),
              const SizedBox(height: 12),
              // Buyer info section
              _detailSection('المشتري', Icons.person, [
                _detailRow2('الاسم', customerName),
                if (customerCode.isNotEmpty)
                  _detailRow2('الرمز', customerCode),
                if (customerPhone.isNotEmpty)
                  _detailRow2('الهاتف', customerPhone),
              ]),
              const SizedBox(height: 12),
              // Price section
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('سعر البيع',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textGray)),
                          const SizedBox(height: 4),
                          Text(
                            '$salePrice $currency',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text('التكلفة',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textGray)),
                          const SizedBox(height: 4),
                          Text(
                            _formatAmount(cost),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Profit/Loss
              if (!cancelled && cost > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: profit >= 0
                          ? [
                              const Color(0xFFF0FDF4),
                              const Color(0xFFECFDF5)
                            ]
                          : [
                              const Color(0xFFFEF2F2),
                              const Color(0xFFFEE2E2)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        profit >= 0 ? 'الربح' : 'الخسارة',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGray),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profit >= 0 ? '+' : ''}${_formatAmount(profit)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color:
                              profit >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // Cost breakdown if car has costs
              if (car != null) _buildCostBreakdown(car, sale),
              const SizedBox(height: 12),
              // Other details
              _detailSection('تفاصيل أخرى', Icons.info_outline, [
                _detailRow2(
                    'طريقة الدفع', _paymentMethodLabel(paymentMethod)),
                _detailRow2('التاريخ', date.toString().split('T').first),
                _detailRow2('العملة', currency),
                _detailRow2('الحالة', status),
                if (notes.toString().isNotEmpty)
                  _detailRow2('ملاحظات', notes.toString()),
              ]),
              const SizedBox(height: 16),
              // Actions
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (!cancelled)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditDialog(sale);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('تعديل'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
                if (!cancelled) const SizedBox(width: 8),
                if (!cancelled)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmCancelSale(sale);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('إلغاء البيع'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final id =
                        sale['_id']?.toString() ?? sale['id']?.toString() ?? '';
                    _confirmDelete(id, customerName);
                  },
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('حذف'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostBreakdown(
      Map<String, dynamic> car, Map<String, dynamic> sale) {
    final purchasePrice =
        _parseDouble(car['purchase_price'] ?? car['purchasePrice'] ?? car['cost'] ?? 0);
    final shippingCost =
        _parseDouble(car['shipping_cost'] ?? car['shippingCost'] ?? 0);
    final customsCost =
        _parseDouble(car['customs_cost'] ?? car['customsCost'] ?? 0);
    final handlingCost =
        _parseDouble(car['handling_cost'] ?? car['handlingCost'] ?? 0);
    final otherCosts =
        _parseDouble(car['other_costs'] ?? car['otherCosts'] ?? 0);

    // Expenses for this car
    double expenseTotal = 0;
    final carId = sale['car_id']?.toString();
    if (carId != null) {
      for (final exp in _expenses) {
        if ((exp['car_id']?.toString() ?? exp['carId']?.toString()) == carId) {
          expenseTotal += _parseDouble(exp['amount'] ?? 0);
        }
      }
    }

    if (purchasePrice == 0 &&
        shippingCost == 0 &&
        customsCost == 0 &&
        handlingCost == 0 &&
        otherCosts == 0 &&
        expenseTotal == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  size: 16, color: AppColors.textGray),
              const SizedBox(width: 6),
              const Text('تفاصيل التكلفة',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          if (purchasePrice > 0)
            _costRow('سعر الشراء', _formatAmount(purchasePrice)),
          if (shippingCost > 0)
            _costRow('تكلفة الشحن', _formatAmount(shippingCost)),
          if (customsCost > 0)
            _costRow('رسوم جمركية', _formatAmount(customsCost)),
          if (handlingCost > 0)
            _costRow('تكلفة المناولة', _formatAmount(handlingCost)),
          if (otherCosts > 0)
            _costRow('تكاليف أخرى', _formatAmount(otherCosts)),
          if (expenseTotal > 0)
            _costRow('مصاريف إضافية', _formatAmount(expenseTotal)),
          const Divider(height: 16),
          _costRow('إجمالي التكلفة', _formatAmount(_getCarCost(sale)),
              bold: true),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: bold ? AppColors.textDark : AppColors.textGray,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: bold ? AppColors.textDark : AppColors.textGray,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _detailSection(
      String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow2(String label, String value) {
    if (value.isEmpty || value == '-' || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Actions Bottom Sheet ──

  void _showActions(Map<String, dynamic> sale) {
    final id = sale['_id']?.toString() ?? sale['id']?.toString();
    if (id == null || id.isEmpty) return;
    final customerName = _customerDisplayName(sale);
    final cancelled = _isCancelled(sale);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: const Icon(Icons.visibility, color: AppColors.primary),
                title: const Text('عرض التفاصيل'),
                onTap: () {
                  Navigator.pop(context);
                  _showSaleDetails(sale);
                },
              ),
              if (!cancelled)
                ListTile(
                  leading:
                      const Icon(Icons.edit, color: AppColors.primary),
                  title: const Text('تعديل'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(sale);
                  },
                ),
              if (!cancelled)
                ListTile(
                  leading: const Icon(Icons.cancel_outlined,
                      color: Color(0xFFD97706)),
                  title: const Text('إلغاء البيع',
                      style: TextStyle(color: Color(0xFFD97706))),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmCancelSale(sale);
                  },
                ),
              ListTile(
                leading:
                    const Icon(Icons.delete, color: AppColors.error),
                title: const Text('حذف نهائي',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(id, customerName);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cancel Sale Dialog ──

  void _confirmCancelSale(Map<String, dynamic> sale) {
    final id = sale['_id']?.toString() ?? sale['id']?.toString();
    if (id == null || id.isEmpty) return;
    final carInfo = _carDisplayInfo(sale);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد إلغاء البيع',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من إلغاء بيع "$carInfo"؟',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سيتم:', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('• تعليم البيع كملغى',
                      style: TextStyle(fontSize: 12)),
                  Text('• إعادة السيارة إلى حالتها السابقة',
                      style: TextStyle(fontSize: 12)),
                  Text('• لن يتم حذف السجل من النظام',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تراجع')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _ds.updateSale(_token, id, {'status': 'cancelled'});
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم إلغاء عملية البيع'),
                      backgroundColor: Color(0xFFD97706)));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e is ApiException
                          ? e.message
                          : 'فشل إلغاء عملية البيع'),
                      backgroundColor: AppColors.error));
                }
              }
            },
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('تأكيد الإلغاء',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  // ── Searchable dropdown for cars ──

  Widget _buildCarDropdown(String? selectedCarId,
      void Function(String?) onChanged, void Function(void Function()) setS) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Autocomplete<Map<String, dynamic>>(
        optionsBuilder: (textEditingValue) {
          final q = textEditingValue.text.toLowerCase();
          if (q.isEmpty) return _cars;
          return _cars.where((car) {
            final brand =
                (car['brand'] ?? car['make'] ?? '').toString().toLowerCase();
            final model = (car['model'] ?? '').toString().toLowerCase();
            final vin = (car['vin'] ?? '').toString().toLowerCase();
            final year = (car['year'] ?? '').toString().toLowerCase();
            return brand.contains(q) ||
                model.contains(q) ||
                vin.contains(q) ||
                year.contains(q);
          });
        },
        displayStringForOption: (car) {
          final brand = car['brand'] ?? car['make'] ?? '';
          final model = car['model'] ?? '';
          final year = car['year'] ?? '';
          return '$brand $model${year.toString().isNotEmpty ? ' ($year)' : ''}'
              .trim();
        },
        initialValue: selectedCarId != null && selectedCarId.isNotEmpty
            ? TextEditingValue(
                text: (() {
                final match = _cars
                    .where((c) =>
                        (c['id']?.toString() ?? c['_id']?.toString()) ==
                        selectedCarId)
                    .firstOrNull;
                if (match != null) {
                  final brand = match['brand'] ?? match['make'] ?? '';
                  final model = match['model'] ?? '';
                  final year = match['year'] ?? '';
                  return '$brand $model${year.toString().isNotEmpty ? ' ($year)' : ''}'
                      .trim();
                }
                return '';
              })())
            : null,
        onSelected: (car) {
          final id = car['id']?.toString() ?? car['_id']?.toString();
          setS(() => onChanged(id));
        },
        fieldViewBuilder:
            (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'السيارة',
              hintText: 'بحث بالماركة/الموديل/VIN...',
              prefixIcon: const Icon(Icons.directions_car, size: 20),
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topRight,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 200, maxWidth: 350),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final car = options.elementAt(index);
                    final brand = car['brand'] ?? car['make'] ?? '';
                    final model = car['model'] ?? '';
                    final year = car['year'] ?? '';
                    final vin = car['vin'] ?? '';
                    return ListTile(
                      dense: true,
                      title: Text(
                          '$brand $model${year.toString().isNotEmpty ? ' ($year)' : ''}'
                              .trim(),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: vin.toString().isNotEmpty
                          ? Text('VIN: $vin',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted))
                          : null,
                      onTap: () => onSelected(car),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Searchable dropdown for customers ──

  Widget _buildCustomerDropdown(
      String? selectedCustomerId,
      void Function(String?) onChanged,
      void Function(void Function()) setS) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Autocomplete<Map<String, dynamic>>(
        optionsBuilder: (textEditingValue) {
          final q = textEditingValue.text.toLowerCase();
          if (q.isEmpty) return _customers;
          return _customers.where((cust) {
            final name = (cust['name'] ?? '').toString().toLowerCase();
            final phone = (cust['phone'] ?? '').toString().toLowerCase();
            final code = (cust['customer_code'] ?? cust['customerCode'] ?? '')
                .toString()
                .toLowerCase();
            return name.contains(q) || phone.contains(q) || code.contains(q);
          });
        },
        displayStringForOption: (cust) {
          final name = cust['name'] ?? '';
          final code = cust['customer_code'] ?? cust['customerCode'] ?? '';
          return '$name${code.toString().isNotEmpty ? ' ($code)' : ''}'.trim();
        },
        initialValue:
            selectedCustomerId != null && selectedCustomerId.isNotEmpty
                ? TextEditingValue(
                    text: (() {
                    final match = _customers
                        .where((c) =>
                            (c['id']?.toString() ?? c['_id']?.toString()) ==
                            selectedCustomerId)
                        .firstOrNull;
                    if (match != null) {
                      final name = match['name'] ?? '';
                      final code = match['customer_code'] ??
                          match['customerCode'] ??
                          '';
                      return '$name${code.toString().isNotEmpty ? ' ($code)' : ''}'
                          .trim();
                    }
                    return '';
                  })())
                : null,
        onSelected: (cust) {
          final id = cust['id']?.toString() ?? cust['_id']?.toString();
          setS(() => onChanged(id));
        },
        fieldViewBuilder:
            (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'العميل',
              hintText: 'بحث بالاسم/الهاتف/الرمز...',
              prefixIcon: const Icon(Icons.person_outline, size: 20),
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topRight,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 200, maxWidth: 350),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final cust = options.elementAt(index);
                    final name = cust['name'] ?? '';
                    final code = cust['customer_code'] ??
                        cust['customerCode'] ??
                        '';
                    final phone = cust['phone'] ?? '';
                    return ListTile(
                      dense: true,
                      title: Text(
                          '$name${code.toString().isNotEmpty ? ' ($code)' : ''}'
                              .trim(),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: phone.toString().isNotEmpty
                          ? Text(phone.toString(),
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted))
                          : null,
                      onTap: () => onSelected(cust),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Add Sale Dialog ──

  void _showAddDialog() {
    String? selectedCarId;
    String? selectedCustomerId;
    final priceC = TextEditingController();
    final dateC = TextEditingController(
        text: DateTime.now().toString().split(' ').first);
    final notesC = TextEditingController();
    String currency = 'USD';
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('بيع سيارة',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCarDropdown(
                      selectedCarId, (v) => selectedCarId = v, setS),
                  _buildCustomerDropdown(
                      selectedCustomerId,
                      (v) => selectedCustomerId = v,
                      setS),
                  _input(priceC, 'سعر البيع', Icons.attach_money,
                      keyboard: TextInputType.number),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DropdownButtonFormField<String>(
                      value: currency,
                      items: _currencyOptions
                          .map((c) => DropdownMenuItem(
                              value: c['code'], child: Text(c['label']!)))
                          .toList(),
                      onChanged: (v) => setS(() => currency = v!),
                      decoration: InputDecoration(
                        labelText: 'العملة',
                        prefixIcon:
                            const Icon(Icons.currency_exchange, size: 20),
                        filled: true,
                        fillColor: AppColors.bgLight,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DropdownButtonFormField<String>(
                      value: paymentMethod,
                      items: _paymentMethods
                          .map((m) => DropdownMenuItem(
                              value: m['value'], child: Text(m['label']!)))
                          .toList(),
                      onChanged: (v) => setS(() => paymentMethod = v!),
                      decoration: InputDecoration(
                        labelText: 'طريقة الدفع',
                        prefixIcon: const Icon(Icons.payment, size: 20),
                        filled: true,
                        fillColor: AppColors.bgLight,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  _inputDate(
                      dateC, 'تاريخ البيع', Icons.calendar_today),
                  _input(notesC, 'ملاحظات', Icons.notes),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (priceC.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _ds.createSale(_token, {
                    if (selectedCarId != null && selectedCarId!.isNotEmpty)
                      'car_id':
                          int.tryParse(selectedCarId!) ?? selectedCarId,
                    if (selectedCustomerId != null &&
                        selectedCustomerId!.isNotEmpty)
                      'customer_id': int.tryParse(selectedCustomerId!) ??
                          selectedCustomerId,
                    'sale_price':
                        double.tryParse(priceC.text.trim()) ?? 0,
                    'currency': currency,
                    'payment_method': paymentMethod,
                    'sale_date': dateC.text.trim(),
                    if (notesC.text.trim().isNotEmpty)
                      'notes': notesC.text.trim(),
                  });
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم إضافة عملية البيع بنجاح'),
                        backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e is ApiException
                            ? e.message
                            : 'فشل إضافة عملية البيع'),
                        backgroundColor: AppColors.error));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('إضافة',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Sale Dialog ──

  void _showEditDialog(Map<String, dynamic> sale) {
    final id = sale['_id']?.toString() ?? sale['id']?.toString();
    if (id == null || id.isEmpty) return;

    String? selectedCarId = sale['car_id']?.toString();
    String? selectedCustomerId = sale['customer_id']?.toString();
    final priceC = TextEditingController(
        text:
            '${sale['sale_price'] ?? sale['selling_price'] ?? sale['sellingPrice'] ?? sale['amount'] ?? sale['total'] ?? ''}');
    final rawDate =
        (sale['sale_date'] ?? sale['date'] ?? sale['created_at'] ?? '')
            .toString();
    final dateC = TextEditingController(text: rawDate.split('T').first);
    final notesC = TextEditingController(text: sale['notes'] ?? '');
    String currency = (sale['currency'] ?? 'USD').toString();
    if (!_currencyOptions.any((c) => c['code'] == currency)) {
      currency = 'USD';
    }
    String paymentMethod = (sale['payment_method'] ?? 'cash').toString();
    if (!_paymentMethods.any((m) => m['value'] == paymentMethod)) {
      paymentMethod = 'cash';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تعديل عملية البيع',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCarDropdown(
                      selectedCarId, (v) => selectedCarId = v, setS),
                  _buildCustomerDropdown(
                      selectedCustomerId,
                      (v) => selectedCustomerId = v,
                      setS),
                  _input(priceC, 'سعر البيع', Icons.attach_money,
                      keyboard: TextInputType.number),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DropdownButtonFormField<String>(
                      value: currency,
                      items: _currencyOptions
                          .map((c) => DropdownMenuItem(
                              value: c['code'], child: Text(c['label']!)))
                          .toList(),
                      onChanged: (v) => setS(() => currency = v!),
                      decoration: InputDecoration(
                        labelText: 'العملة',
                        prefixIcon:
                            const Icon(Icons.currency_exchange, size: 20),
                        filled: true,
                        fillColor: AppColors.bgLight,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DropdownButtonFormField<String>(
                      value: paymentMethod,
                      items: _paymentMethods
                          .map((m) => DropdownMenuItem(
                              value: m['value'], child: Text(m['label']!)))
                          .toList(),
                      onChanged: (v) => setS(() => paymentMethod = v!),
                      decoration: InputDecoration(
                        labelText: 'طريقة الدفع',
                        prefixIcon: const Icon(Icons.payment, size: 20),
                        filled: true,
                        fillColor: AppColors.bgLight,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  _inputDate(
                      dateC, 'تاريخ البيع', Icons.calendar_today),
                  _input(notesC, 'ملاحظات', Icons.notes),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _ds.updateSale(_token, id, {
                    'car_id': selectedCarId != null &&
                            selectedCarId!.isNotEmpty
                        ? (int.tryParse(selectedCarId!) ?? selectedCarId)
                        : null,
                    'customer_id': selectedCustomerId != null &&
                            selectedCustomerId!.isNotEmpty
                        ? (int.tryParse(selectedCustomerId!) ??
                            selectedCustomerId)
                        : null,
                    'sale_price':
                        double.tryParse(priceC.text.trim()) ?? 0,
                    'currency': currency,
                    'payment_method': paymentMethod,
                    'sale_date': dateC.text.trim(),
                    'notes': notesC.text.trim(),
                  });
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم تعديل عملية البيع'),
                        backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e is ApiException
                            ? e.message
                            : 'فشل تعديل عملية البيع'),
                        backgroundColor: AppColors.error));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('حفظ',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Confirmation ──

  void _confirmDelete(String id, String name) {
    if (id.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف سجل البيع نهائياً',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'هل أنت متأكد من حذف ${name.isNotEmpty ? '"$name"' : 'هذه العملية'} نهائياً؟',
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تحذير:',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                          fontSize: 12)),
                  Text('• سيتم حذف السجل من النظام بالكامل',
                      style: TextStyle(fontSize: 11)),
                  Text('• لن يتم إنشاء قيود عكسية',
                      style: TextStyle(fontSize: 11)),
                  Text('• سيتم إعادة السيارة للمعرض',
                      style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _ds.deleteSale(_token, id);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم حذف سجل البيع'),
                      backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e is ApiException
                          ? e.message
                          : 'فشل حذف عملية البيع'),
                      backgroundColor: AppColors.error));
                }
              }
            },
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('حذف نهائي',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _input(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: AppColors.bgLight,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _inputDate(
      TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: AppColors.bgLight,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context)
                        .colorScheme
                        .copyWith(primary: AppColors.primary)),
                child: child!),
          );
          if (picked != null) c.text = picked.toString().split(' ').first;
        },
      ),
    );
  }
}
