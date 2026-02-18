import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class MarketResearchScreen extends StatefulWidget {
  const MarketResearchScreen({super.key});
  @override
  State<MarketResearchScreen> createState() => _MarketResearchScreenState();
}

class _MarketResearchScreenState extends State<MarketResearchScreen> {
  late final DataService _ds;
  bool _isLoading = true;
  String? _error;

  // Data
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _sales = [];

  // Computed stats
  int _totalSales = 0;
  double _totalRevenue = 0;
  double _totalProfit = 0;
  double _avgProfitMargin = 0;
  List<_MakeStats> _makeStats = [];

  static const List<Color> _chartColors = [
    Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFF06B6D4), Color(0xFFEC4899), Color(0xFF6366F1),
    Color(0xFF14B8A6), Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadData();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  double _pd(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _fmtNum(num v) => NumberFormat('#,###', 'en_US').format(v);
  String _fmtCur(double v) => '\$${NumberFormat('#,###.##', 'en_US').format(v.abs())}';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _ds.getCars(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getSales(_token).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;

      final cars = results[0] as List<Map<String, dynamic>>;
      final sales = results[1] as List<Map<String, dynamic>>;

      // Calculate stats by make
      final makeMap = <String, _MakeStats>{};

      for (final car in cars) {
        final make = (car['make'] ?? car['brand'] ?? 'غير محدد').toString().trim();
        if (make.isEmpty) continue;
        final entry = makeMap.putIfAbsent(make, () => _MakeStats(make: make));
        entry.totalCars++;
        final price = _pd(car['selling_price'] ?? car['sellingPrice'] ?? car['price']);
        if (price > 0) {
          entry.totalSellingPrice += price;
          entry.sellingPriceCount++;
        }
        final purchasePrice = _pd(car['purchase_price'] ?? car['purchasePrice']);
        if (purchasePrice > 0) {
          entry.totalPurchasePrice += purchasePrice;
          entry.purchasePriceCount++;
        }
      }

      // Sales calculations
      double totalRevenue = 0;
      double totalProfit = 0;
      int salesWithProfit = 0;
      double totalProfitMarginSum = 0;

      for (final sale in sales) {
        final salePrice = _pd(sale['sale_price'] ?? sale['selling_price'] ?? sale['sellingPrice'] ?? sale['salePrice']);
        final purchasePrice = _pd(sale['purchase_price'] ?? sale['purchasePrice'] ?? sale['cost']);
        totalRevenue += salePrice;
        final profit = salePrice - purchasePrice;
        totalProfit += profit;

        if (salePrice > 0 && purchasePrice > 0) {
          totalProfitMarginSum += ((profit / purchasePrice) * 100);
          salesWithProfit++;
        }

        // Attribute sale to make
        final saleBrand = (sale['car_brand'] ?? sale['carBrand'] ?? sale['brand'] ?? sale['make'] ?? '').toString().trim();
        if (saleBrand.isNotEmpty && makeMap.containsKey(saleBrand)) {
          makeMap[saleBrand]!.salesCount++;
          makeMap[saleBrand]!.salesRevenue += salePrice;
        }
      }

      // Sort makes by total cars descending
      final makeList = makeMap.values.toList()..sort((a, b) => b.totalCars.compareTo(a.totalCars));

      setState(() {
        _cars = cars;
        _sales = sales;
        _totalSales = sales.length;
        _totalRevenue = totalRevenue;
        _totalProfit = totalProfit;
        _avgProfitMargin = salesWithProfit > 0 ? totalProfitMarginSum / salesWithProfit : 0;
        _makeStats = makeList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحليل السوق', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.dashboard),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
                ]))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      // Summary cards
                      _buildSummaryCards(),
                      const SizedBox(height: 14),

                      // Average price by make - bar chart
                      _buildAvgPriceChart(),
                      const SizedBox(height: 14),

                      // Sales volume by make
                      _buildSalesVolumeChart(),
                      const SizedBox(height: 14),

                      // Profit margin analysis
                      _buildProfitAnalysis(),
                      const SizedBox(height: 14),

                      // Make breakdown table
                      _buildMakeBreakdown(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
      children: [
        _summaryCard('إجمالي السيارات', _fmtNum(_cars.length), '${_makeStats.length} ماركة', Icons.directions_car, const Color(0xFF3B82F6), const Color(0xFF4F46E5)),
        _summaryCard('إجمالي المبيعات', _fmtNum(_totalSales), 'عملية بيع', Icons.point_of_sale, const Color(0xFF8B5CF6), const Color(0xFF7C3AED)),
        _summaryCard('إجمالي الإيرادات', _fmtCur(_totalRevenue), 'دولار', Icons.attach_money, const Color(0xFF10B981), const Color(0xFF059669)),
        _summaryCard(
          _totalProfit >= 0 ? 'إجمالي الأرباح' : 'إجمالي الخسائر',
          _fmtCur(_totalProfit),
          'هامش ${_avgProfitMargin.toStringAsFixed(1)}%',
          _totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
          _totalProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          _totalProfit >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, String subtitle, IconData icon, Color color, Color gradEnd) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.08), gradEnd.withValues(alpha: 0.15)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.9)))),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.6))),
        ])),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [color, gradEnd]), borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ]),
    );
  }

  Widget _buildAvgPriceChart() {
    final topMakes = _makeStats.where((m) => m.avgSellingPrice > 0).take(8).toList();
    if (topMakes.isEmpty) {
      return _cardWrapper(icon: Icons.bar_chart, iconColor: const Color(0xFF3B82F6), title: 'متوسط أسعار البيع حسب الماركة',
        child: const SizedBox(height: 100, child: Center(child: Text('لا توجد بيانات كافية', style: TextStyle(color: AppColors.textMuted)))));
    }

    final maxPrice = topMakes.map((m) => m.avgSellingPrice).reduce((a, b) => a > b ? a : b);

    return _cardWrapper(
      icon: Icons.bar_chart, iconColor: const Color(0xFF3B82F6), title: 'متوسط أسعار البيع حسب الماركة',
      child: SizedBox(
        height: 240,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxPrice * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final m = topMakes[groupIndex];
                return BarTooltipItem('${m.make}\n\$${m.avgSellingPrice.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600));
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36, getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= topMakes.length) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(top: 6), child: Text(topMakes[i].make, style: const TextStyle(fontSize: 9, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis));
            })),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 50, getTitlesWidget: (v, _) {
              return Text('\$${(v / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
            })),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxPrice / 4,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(topMakes.length, (i) => BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: topMakes[i].avgSellingPrice, color: _chartColors[i % _chartColors.length], width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
          ])),
        )),
      ),
    );
  }

  Widget _buildSalesVolumeChart() {
    final salesMakes = _makeStats.where((m) => m.salesCount > 0).toList()..sort((a, b) => b.salesCount.compareTo(a.salesCount));
    final topSales = salesMakes.take(8).toList();
    if (topSales.isEmpty) {
      return _cardWrapper(icon: Icons.pie_chart_outline, iconColor: const Color(0xFF8B5CF6), title: 'حجم المبيعات حسب الماركة',
        child: const SizedBox(height: 100, child: Center(child: Text('لا توجد بيانات مبيعات', style: TextStyle(color: AppColors.textMuted)))));
    }

    return _cardWrapper(
      icon: Icons.pie_chart_outline, iconColor: const Color(0xFF8B5CF6), title: 'حجم المبيعات حسب الماركة',
      child: SizedBox(
        height: 240,
        child: Row(children: [
          Expanded(
            flex: 3,
            child: PieChart(PieChartData(
              sectionsSpace: 2, centerSpaceRadius: 40,
              sections: List.generate(topSales.length, (i) => PieChartSectionData(
                value: topSales[i].salesCount.toDouble(),
                color: _chartColors[i % _chartColors.length],
                radius: 50, showTitle: false,
              )),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(topSales.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: _chartColors[i % _chartColors.length], borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${topSales[i].make} (${topSales[i].salesCount})', style: const TextStyle(fontSize: 11, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              )),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildProfitAnalysis() {
    return _cardWrapper(
      icon: Icons.analytics_outlined, iconColor: const Color(0xFF10B981), title: 'تحليل هوامش الربح',
      child: Column(children: [
        _profitRow('إجمالي الإيرادات', _fmtCur(_totalRevenue), const Color(0xFF3B82F6)),
        _profitRow('إجمالي الأرباح', _fmtCur(_totalProfit), _totalProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
        _profitRow('متوسط هامش الربح', '${_avgProfitMargin.toStringAsFixed(1)}%', const Color(0xFF8B5CF6)),
        _profitRow('عدد المبيعات', '$_totalSales', const Color(0xFFF59E0B)),
        if (_totalSales > 0) _profitRow('متوسط سعر البيع', _fmtCur(_totalRevenue / _totalSales), const Color(0xFF06B6D4)),
        if (_totalSales > 0) _profitRow('متوسط الربح لكل سيارة', _fmtCur(_totalProfit / _totalSales), const Color(0xFFEC4899)),
      ]),
    );
  }

  Widget _profitRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 4, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _buildMakeBreakdown() {
    if (_makeStats.isEmpty) {
      return _cardWrapper(icon: Icons.table_chart_outlined, iconColor: const Color(0xFFF59E0B), title: 'تفاصيل الماركات',
        child: const SizedBox(height: 80, child: Center(child: Text('لا توجد بيانات', style: TextStyle(color: AppColors.textMuted)))));
    }

    return _cardWrapper(
      icon: Icons.table_chart_outlined, iconColor: const Color(0xFFF59E0B), title: 'تفاصيل الماركات',
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Expanded(flex: 3, child: Text('الماركة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
            Expanded(flex: 2, child: Text('عدد', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text('مبيعات', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.center)),
            Expanded(flex: 3, child: Text('متوسط السعر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.end)),
          ]),
        ),
        const SizedBox(height: 4),
        // Rows
        ...List.generate(_makeStats.length.clamp(0, 15), (i) {
          final m = _makeStats[i];
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: Row(children: [
              Expanded(flex: 3, child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _chartColors[i % _chartColors.length], borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Expanded(child: Text(m.make, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ])),
              Expanded(flex: 2, child: Text('${m.totalCars}', style: const TextStyle(fontSize: 12, color: AppColors.textGray), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('${m.salesCount}', style: const TextStyle(fontSize: 12, color: AppColors.textGray), textAlign: TextAlign.center)),
              Expanded(flex: 3, child: Text(m.avgSellingPrice > 0 ? '\$${m.avgSellingPrice.toStringAsFixed(0)}' : '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark), textAlign: TextAlign.end)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _cardWrapper({required IconData icon, required Color iconColor, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _MakeStats {
  final String make;
  int totalCars = 0;
  int salesCount = 0;
  double totalSellingPrice = 0;
  int sellingPriceCount = 0;
  double totalPurchasePrice = 0;
  int purchasePriceCount = 0;
  double salesRevenue = 0;

  _MakeStats({required this.make});

  double get avgSellingPrice => sellingPriceCount > 0 ? totalSellingPrice / sellingPriceCount : 0;
  double get avgPurchasePrice => purchasePriceCount > 0 ? totalPurchasePrice / purchasePriceCount : 0;
}
