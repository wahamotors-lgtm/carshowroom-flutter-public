import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class CarPricingScreen extends StatefulWidget {
  const CarPricingScreen({super.key});
  @override
  State<CarPricingScreen> createState() => _CarPricingScreenState();
}

class _CarPricingScreenState extends State<CarPricingScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _expenses = [];
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _ds.getCars(_token),
        _ds.getExpenses(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _cars = results[0];
        _expenses = results[1];
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.from(_cars);
    } else {
      _filtered = _cars.where((c) {
        final make = (c['make'] ?? c['brand'] ?? '').toString().toLowerCase();
        final model = (c['model'] ?? '').toString().toLowerCase();
        final year = (c['year'] ?? '').toString();
        final vin = (c['vin'] ?? '').toString().toLowerCase();
        return make.contains(q) || model.contains(q) || year.contains(q) || vin.contains(q);
      }).toList();
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double _getCarPurchasePrice(Map<String, dynamic> car) {
    return _parseDouble(car['purchase_price'] ?? car['purchasePrice'] ?? car['cost'] ?? 0);
  }

  double _getCarSellingPrice(Map<String, dynamic> car) {
    return _parseDouble(car['selling_price'] ?? car['sellingPrice'] ?? car['price'] ?? 0);
  }

  double _getCarShippingCost(Map<String, dynamic> car) {
    return _parseDouble(car['shipping_cost'] ?? car['shippingCost'] ?? 0);
  }

  double _getCarCustomsCost(Map<String, dynamic> car) {
    return _parseDouble(car['customs_cost'] ?? car['customsCost'] ?? 0);
  }

  double _getCarHandlingCost(Map<String, dynamic> car) {
    return _parseDouble(car['handling_cost'] ?? car['handlingCost'] ?? 0);
  }

  double _getCarOtherCosts(Map<String, dynamic> car) {
    return _parseDouble(car['other_costs'] ?? car['otherCosts'] ?? 0);
  }

  double _getCarExpensesTotal(Map<String, dynamic> car) {
    final carId = (car['id'] ?? car['_id'])?.toString();
    if (carId == null) return 0;
    double total = 0;
    for (final exp in _expenses) {
      if ((exp['car_id']?.toString() ?? exp['carId']?.toString()) == carId) {
        total += _parseDouble(exp['amount'] ?? 0);
      }
    }
    return total;
  }

  double _getCarTotalCost(Map<String, dynamic> car) {
    return _getCarPurchasePrice(car) +
        _getCarShippingCost(car) +
        _getCarCustomsCost(car) +
        _getCarHandlingCost(car) +
        _getCarOtherCosts(car) +
        _getCarExpensesTotal(car);
  }

  double _getProfitMargin(Map<String, dynamic> car) {
    final sellingPrice = _getCarSellingPrice(car);
    final totalCost = _getCarTotalCost(car);
    return sellingPrice - totalCost;
  }

  // Stats
  Map<String, dynamic> get _stats {
    double totalCost = 0;
    double totalSelling = 0;
    int withPricing = 0;
    for (final car in _cars) {
      final cost = _getCarTotalCost(car);
      final selling = _getCarSellingPrice(car);
      totalCost += cost;
      totalSelling += selling;
      if (cost > 0 || selling > 0) withPricing++;
    }
    return {
      'totalCost': totalCost,
      'totalSelling': totalSelling,
      'totalProfit': totalSelling - totalCost,
      'count': withPricing,
    };
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
    return '\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final totalProfit = (stats['totalProfit'] as double?) ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسعير السيارات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.carPricing),
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
                      // Stats
                      SliverToBoxAdapter(child: _buildStatsCards(stats)),
                      // Search
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() => _applyFilter()),
                            decoration: InputDecoration(
                              hintText: 'بحث بالماركة، الموديل، السنة...',
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
                              filled: true,
                              fillColor: AppColors.bgLight,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ),
                      // Count
                      SliverToBoxAdapter(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          color: Colors.white,
                          child: Text('${_filtered.length} سيارة', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SliverToBoxAdapter(child: Divider(height: 1)),
                      // List
                      _filtered.isEmpty
                          ? SliverFillRemaining(
                              child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.price_change_outlined, size: 48, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text('لا توجد سيارات', style: TextStyle(color: AppColors.textGray)),
                              ])),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _buildCarPricingCard(_filtered[i]),
                                childCount: _filtered.length,
                              ),
                            ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    final profit = (stats['totalProfit'] as double?) ?? 0;
    final isProfit = profit >= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statCard('عدد السيارات', '${stats['count']}', Icons.directions_car_outlined, const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
            _statCard('إجمالي التكلفة', _formatAmount((stats['totalCost'] as double?) ?? 0), Icons.money_off_outlined, AppColors.blue600, const Color(0xFFEFF6FF)),
            _statCard('إجمالي البيع', _formatAmount((stats['totalSelling'] as double?) ?? 0), Icons.attach_money, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
            _statCard(
              isProfit ? 'إجمالي الربح' : 'إجمالي الخسارة',
              _formatAmount(profit.abs()),
              isProfit ? Icons.trending_up : Icons.trending_down,
              isProfit ? AppColors.success : AppColors.error,
              isProfit ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bgColor) {
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
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGray, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCarPricingCard(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final purchasePrice = _getCarPurchasePrice(car);
    final sellingPrice = _getCarSellingPrice(car);
    final totalCost = _getCarTotalCost(car);
    final profitMargin = _getProfitMargin(car);
    final isProfit = profitMargin >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCostBreakdown(car),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: car icon + name + profit badge
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_car, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$make $model ${year.toString().isNotEmpty ? '($year)' : ''}'.trim(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'VIN: ${(car['vin'] ?? '-').toString().length > 12 ? '...${(car['vin'] ?? '').toString().substring((car['vin'] ?? '').toString().length - 8)}' : (car['vin'] ?? '-')}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  // Profit/loss badge
                  if (sellingPrice > 0 && totalCost > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isProfit ? 'ربح' : 'خسارة',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isProfit ? AppColors.success : AppColors.error),
                          ),
                          Text(
                            '${isProfit ? '+' : ''}${_formatAmount(profitMargin)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isProfit ? AppColors.success : AppColors.error),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Price details row
              Row(
                children: [
                  Expanded(
                    child: _miniStat('سعر الشراء', purchasePrice > 0 ? _formatAmount(purchasePrice) : '-', AppColors.blue600),
                  ),
                  Expanded(
                    child: _miniStat('سعر البيع', sellingPrice > 0 ? _formatAmount(sellingPrice) : '-', AppColors.success),
                  ),
                  Expanded(
                    child: _miniStat('إجمالي التكلفة', totalCost > 0 ? _formatAmount(totalCost) : '-', AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Profit margin percentage
              if (sellingPrice > 0 && totalCost > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.show_chart, size: 14, color: isProfit ? AppColors.success : AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      'هامش الربح: ${(profitMargin / totalCost * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isProfit ? AppColors.success : AppColors.error),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  void _showCostBreakdown(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final purchasePrice = _getCarPurchasePrice(car);
    final shippingCost = _getCarShippingCost(car);
    final customsCost = _getCarCustomsCost(car);
    final handlingCost = _getCarHandlingCost(car);
    final otherCosts = _getCarOtherCosts(car);
    final expensesTotal = _getCarExpensesTotal(car);
    final totalCost = _getCarTotalCost(car);
    final sellingPrice = _getCarSellingPrice(car);
    final profit = sellingPrice - totalCost;
    final isProfit = profit >= 0;

    // Get individual expenses for this car
    final carId = (car['id'] ?? car['_id'])?.toString();
    final carExpenses = carId != null
        ? _expenses.where((e) => (e['car_id']?.toString() ?? e['carId']?.toString()) == carId).toList()
        : <Map<String, dynamic>>[];

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
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '$make $model ${year.toString().isNotEmpty ? '($year)' : ''}'.trim(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('تفاصيل التكلفة والأسعار', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ),
              const SizedBox(height: 16),
              // Price comparison
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          const Text('إجمالي التكلفة', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                          const SizedBox(height: 4),
                          Text(_formatAmount(totalCost), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          const Text('سعر البيع', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                          const SizedBox(height: 4),
                          Text(sellingPrice > 0 ? _formatAmount(sellingPrice) : 'غير محدد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: sellingPrice > 0 ? AppColors.success : AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Profit/Loss
              if (sellingPrice > 0 && totalCost > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isProfit
                          ? [const Color(0xFFF0FDF4), const Color(0xFFECFDF5)]
                          : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(isProfit ? 'الربح المتوقع' : 'الخسارة المتوقعة', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                      const SizedBox(height: 4),
                      Text(
                        '${isProfit ? '+' : ''}${_formatAmount(profit)}',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isProfit ? AppColors.success : AppColors.error),
                      ),
                      Text(
                        'هامش: ${(profit / totalCost * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isProfit ? AppColors.success : AppColors.error),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Cost breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.calculate_outlined, size: 16, color: AppColors.textGray),
                      SizedBox(width: 6),
                      Text('تفصيل التكلفة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ]),
                    const SizedBox(height: 8),
                    if (purchasePrice > 0) _costRow('سعر الشراء', _formatAmount(purchasePrice)),
                    if (shippingCost > 0) _costRow('تكلفة الشحن', _formatAmount(shippingCost)),
                    if (customsCost > 0) _costRow('رسوم جمركية', _formatAmount(customsCost)),
                    if (handlingCost > 0) _costRow('تكلفة المناولة', _formatAmount(handlingCost)),
                    if (otherCosts > 0) _costRow('تكاليف أخرى', _formatAmount(otherCosts)),
                    if (expensesTotal > 0) _costRow('مصاريف إضافية', _formatAmount(expensesTotal)),
                    const Divider(height: 16),
                    _costRow('إجمالي التكلفة', _formatAmount(totalCost), bold: true),
                    if (sellingPrice > 0) ...[
                      const Divider(height: 16),
                      _costRow('سعر البيع', _formatAmount(sellingPrice), bold: true),
                      _costRow(
                        isProfit ? 'الربح' : 'الخسارة',
                        '${isProfit ? '+' : ''}${_formatAmount(profit)}',
                        bold: true,
                        color: isProfit ? AppColors.success : AppColors.error,
                      ),
                    ],
                  ],
                ),
              ),
              // Individual expenses
              if (carExpenses.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.textGray),
                        const SizedBox(width: 6),
                        Text('المصاريف المرتبطة (${carExpenses.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      ]),
                      const SizedBox(height: 8),
                      ...carExpenses.map((exp) {
                        final desc = exp['description'] ?? '';
                        final amount = _parseDouble(exp['amount'] ?? 0);
                        final category = exp['category'] ?? '';
                        final date = (exp['expense_date'] ?? exp['date'] ?? '').toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(4)),
                                child: Text(category.toString(), style: const TextStyle(fontSize: 9, color: AppColors.textGray)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(desc.toString(), style: const TextStyle(fontSize: 12, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text(_formatAmount(amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _costRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color ?? (bold ? AppColors.textDark : AppColors.textGray), fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 12, color: color ?? (bold ? AppColors.textDark : AppColors.textGray), fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      ),
    );
  }
}
