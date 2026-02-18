import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/data_service.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DataService _ds;
  late final ApiService _api;
  bool _isLoading = true;

  // ── Stats ──
  int _totalCars = 0;
  int _carsInKorea = 0;
  int _carsInTransit = 0;
  int _carsInShowroom = 0;
  int _carsSold = 0;
  int _activeContainers = 0;
  double _totalProfit = 0;
  int _salesToday = 0;
  double _profitToday = 0;
  int _salesThisMonth = 0;
  double _profitThisMonth = 0;

  // ── Chart data ──
  List<_MonthData> _monthlyData = [];
  List<_StatusSlice> _statusSlices = [];

  // ── Lists ──
  List<Map<String, dynamic>> _readyCars = [];
  List<Map<String, dynamic>> _recentSales = [];
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _api = ApiService();
    _ds = DataService(_api);
    _loadAll();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  double _pd(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _ds.getCars(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getSales(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getExpenses(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getContainers(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getMonthlyBills(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getRentals(_token).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;

      final cars = results[0];
      final sales = results[1];
      final containers = results[3];

      // ── Bills & Rentals for alerts ──
      List<Map<String, dynamic>> alertsList = [];
      final bills = results[4];
      for (final b in bills) {
        if (b['status'] == 'pending' || b['status'] == 'overdue') {
          alertsList.add({'type': 'bill', 'title': b['name'] ?? 'فاتورة', 'amount': _pd(b['amount']), 'isOverdue': b['status'] == 'overdue'});
        }
      }
      final rentals = results[5];
      for (final r in rentals) {
        if (r['status'] == 'active') {
          final nextDate = r['next_payment_date']?.toString() ?? '';
          final isOverdue = nextDate.isNotEmpty && DateTime.tryParse(nextDate)?.isBefore(DateTime.now()) == true;
          alertsList.add({'type': 'rental', 'title': r['name'] ?? 'إيجار', 'amount': _pd(r['monthly_amount']), 'isOverdue': isOverdue});
        }
      }

      // ── Categorize cars by status ──
      final inKorea = cars.where((c) => c['status'] == 'in_korea_warehouse').toList();
      final inContainer = cars.where((c) => c['status'] == 'in_container').toList();
      final shipped = cars.where((c) => c['status'] == 'shipped').toList();
      final arrived = cars.where((c) => c['status'] == 'arrived').toList();
      final customs = cars.where((c) => c['status'] == 'customs').toList();
      final inShowroom = cars.where((c) => c['status'] == 'in_showroom' || c['status'] == 'in_stock').toList();
      final sold = cars.where((c) => c['status'] == 'sold').toList();
      final transit = inContainer.length + shipped.length + arrived.length + customs.length;

      // ── Active containers ──
      final activeConts = containers.where((c) => !['unloaded_syria', 'delivered'].contains(c['status'])).length;

      // ── Sales calculations ──
      final today = DateTime.now().toIso8601String().split('T').first;
      final now = DateTime.now();
      final salesToday = sales.where((s) => (s['sale_date'] ?? s['saleDate'] ?? '').toString().split('T').first == today).toList();
      final salesMonth = sales.where((s) {
        final d = DateTime.tryParse((s['sale_date'] ?? s['saleDate'] ?? '').toString());
        return d != null && d.month == now.month && d.year == now.year;
      }).toList();

      double calcProfit(Map<String, dynamic> s) {
        final salePrice = _pd(s['sale_price'] ?? s['selling_price'] ?? s['sellingPrice'] ?? s['salePrice']);
        final purchasePrice = _pd(s['purchase_price'] ?? s['purchasePrice'] ?? s['cost']);
        return salePrice - purchasePrice;
      }

      final profitAll = sales.fold<double>(0, (sum, s) => sum + calcProfit(s));
      final profitTodayVal = salesToday.fold<double>(0, (sum, s) => sum + calcProfit(s));
      final profitMonthVal = salesMonth.fold<double>(0, (sum, s) => sum + calcProfit(s));

      // ── Monthly chart data (last 6 months) ──
      List<_MonthData> monthly = [];
      for (int i = 5; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        final mSales = sales.where((s) {
          final d = DateTime.tryParse((s['sale_date'] ?? s['saleDate'] ?? '').toString());
          return d != null && d.month == m.month && d.year == m.year;
        }).toList();
        monthly.add(_MonthData(
          label: DateFormat('MMM', 'ar').format(m),
          salesCount: mSales.length,
          profit: mSales.fold<double>(0, (sum, s) => sum + calcProfit(s)),
        ));
      }

      // ── Status pie slices ──
      final slices = <_StatusSlice>[
        _StatusSlice('في كوريا', inKorea.length, const Color(0xFF3B82F6)),
        _StatusSlice('في الحاوية', inContainer.length, const Color(0xFF8B5CF6)),
        _StatusSlice('في الطريق', shipped.length, const Color(0xFFF59E0B)),
        _StatusSlice('وصلت', arrived.length, const Color(0xFF06B6D4)),
        _StatusSlice('في الجمارك', customs.length, const Color(0xFFEF4444)),
        _StatusSlice('في المعرض', inShowroom.length, const Color(0xFF10B981)),
        _StatusSlice('مباعة', sold.length, const Color(0xFF6B7280)),
      ];

      setState(() {
        _totalCars = cars.length;
        _carsInKorea = inKorea.length;
        _carsInTransit = transit;
        _carsInShowroom = inShowroom.length;
        _carsSold = sold.length;
        _activeContainers = activeConts;
        _totalProfit = profitAll;
        _salesToday = salesToday.length;
        _profitToday = profitTodayVal;
        _salesThisMonth = salesMonth.length;
        _profitThisMonth = profitMonthVal;
        _monthlyData = monthly;
        _statusSlices = slices;
        _readyCars = inShowroom.take(5).toList();
        _recentSales = sales.toList()
          ..sort((a, b) => (b['sale_date'] ?? b['saleDate'] ?? '').toString().compareTo((a['sale_date'] ?? a['saleDate'] ?? '').toString()));
        _recentSales = _recentSales.take(5).toList();
        _alerts = alertsList.take(5).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fmtNum(num v) => NumberFormat('#,###', 'en_US').format(v);
  String _fmtCur(double v) => '\$${NumberFormat('#,###.##', 'en_US').format(v.abs())}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.dashboard),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadAll,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // ═══════════════════════════════════════
                  // 1) Header with date
                  // ═══════════════════════════════════════
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('لوحة التحكم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text('مرحباً بك في نظام كارواتس المحاسبي', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ])),
                    Row(children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ]),
                  ]),
                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════
                  // 2) Hero Banner (today/month stats)
                  // ═══════════════════════════════════════
                  _buildHeroBanner(),
                  const SizedBox(height: 14),

                  // ═══════════════════════════════════════
                  // 3) Alerts (if any)
                  // ═══════════════════════════════════════
                  if (_alerts.isNotEmpty) ...[_buildAlerts(), const SizedBox(height: 14)],

                  // ═══════════════════════════════════════
                  // 4) Four stat cards
                  // ═══════════════════════════════════════
                  _buildStatCardsGrid(),
                  const SizedBox(height: 14),

                  // ═══════════════════════════════════════
                  // 5) Charts (bar + pie)
                  // ═══════════════════════════════════════
                  _buildPerformanceChart(),
                  const SizedBox(height: 14),
                  _buildInventoryPieChart(),
                  const SizedBox(height: 14),

                  // ═══════════════════════════════════════
                  // 6) Ready cars + Recent sales
                  // ═══════════════════════════════════════
                  _buildReadyCars(),
                  const SizedBox(height: 14),
                  _buildRecentSales(),
                  const SizedBox(height: 14),

                  // ═══════════════════════════════════════
                  // 7) Quick links (6 buttons)
                  // ═══════════════════════════════════════
                  _buildQuickLinks(),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  HERO BANNER
  // ════════════════════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF9333EA), Color(0xFFEC4899)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: _hereStat('مبيعات اليوم', '$_salesToday', 'سيارة')),
          Expanded(child: _hereStat('أرباح اليوم', _fmtCur(_profitToday), 'دولار')),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _hereStat('مبيعات الشهر', '$_salesThisMonth', 'سيارة')),
          Expanded(child: _hereStat('أرباح الشهر', _fmtCur(_profitThisMonth), 'دولار')),
        ]),
      ]),
    );
  }

  Widget _hereStat(String label, String value, String unit) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      const SizedBox(height: 4),
      FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))),
      Text(unit, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
    ]);
  }

  // ════════════════════════════════════════════════════════
  //  ALERTS
  // ════════════════════════════════════════════════════════
  Widget _buildAlerts() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 6),
          Text('تنبيهات مهمة (${_alerts.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _alerts.map((a) {
          final isOverdue = a['isOverdue'] == true;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isOverdue ? const Color(0xFFFEE2E2) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFFDE68A)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(a['type'] == 'bill' ? Icons.receipt_outlined : Icons.home_outlined, size: 16, color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a['title'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOverdue ? const Color(0xFF991B1B) : const Color(0xFF1F2937))),
                Text('\$${(a['amount'] as double).toStringAsFixed(2)}${isOverdue ? ' - متأخر!' : ''}',
                    style: TextStyle(fontSize: 10, color: isOverdue ? const Color(0xFFDC2626) : Colors.grey.shade500)),
              ]),
            ]),
          );
        }).toList()),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  4 STAT CARDS
  // ════════════════════════════════════════════════════════
  Widget _buildStatCardsGrid() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.6,
      children: [
        _mainStatCard('إجمالي السيارات', _fmtNum(_totalCars), '$_carsInKorea في كوريا',
            Icons.directions_car, const Color(0xFF3B82F6), const Color(0xFF4F46E5)),
        _mainStatCard('في المعرض', _fmtNum(_carsInShowroom), 'جاهزة للبيع',
            Icons.storefront, const Color(0xFF10B981), const Color(0xFF059669)),
        _mainStatCard('في الطريق', _fmtNum(_carsInTransit), '$_activeContainers حاوية نشطة',
            Icons.local_shipping, const Color(0xFFF59E0B), const Color(0xFFEA580C)),
        _mainStatCard(
            _totalProfit >= 0 ? 'إجمالي الأرباح' : 'إجمالي الخسائر',
            _fmtCur(_totalProfit),
            '$_carsSold سيارة مباعة',
            _totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
            _totalProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            _totalProfit >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626)),
      ],
    );
  }

  Widget _mainStatCard(String label, String value, String subtitle, IconData icon, Color color, Color gradEnd) {
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
          decoration: BoxDecoration(gradient: LinearGradient(colors: [color, gradEnd], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  BAR CHART - 6 MONTHS PERFORMANCE
  // ════════════════════════════════════════════════════════
  Widget _buildPerformanceChart() {
    final maxSales = _monthlyData.isEmpty ? 1.0 : _monthlyData.map((m) => m.salesCount.toDouble()).reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    return _cardWrapper(
      icon: Icons.trending_up, iconColor: const Color(0xFF10B981), title: 'أداء آخر 6 أشهر',
      child: SizedBox(
        height: 220,
        child: _monthlyData.isEmpty
            ? const Center(child: Text('لا توجد بيانات', style: TextStyle(color: AppColors.textMuted)))
            : BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSales + 2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = _monthlyData[groupIndex];
                      return BarTooltipItem('${d.salesCount} سيارة\n\$${d.profit.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= _monthlyData.length) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(top: 6), child: Text(_monthlyData[i].label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)));
                  })),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: (maxSales / 4).clamp(1, double.infinity),
                    getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_monthlyData.length, (i) {
                  final d = _monthlyData[i];
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: d.salesCount.toDouble(), color: const Color(0xFF8B5CF6), width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ]);
                }),
              )),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PIE CHART - INVENTORY DISTRIBUTION
  // ════════════════════════════════════════════════════════
  Widget _buildInventoryPieChart() {
    final activeSlices = _statusSlices.where((s) => s.value > 0).toList();
    return _cardWrapper(
      icon: Icons.pie_chart_outline, iconColor: const Color(0xFF4F46E5), title: 'توزيع المخزون',
      child: activeSlices.isEmpty
          ? const SizedBox(height: 200, child: Center(child: Text('لا توجد بيانات', style: TextStyle(color: AppColors.textMuted))))
          : SizedBox(
              height: 240,
              child: Row(children: [
                Expanded(
                  flex: 3,
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: activeSlices.map((s) => PieChartSectionData(
                      value: s.value.toDouble(), color: s.color, radius: 50, showTitle: false,
                    )).toList(),
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: activeSlices.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 6),
                        Expanded(child: Text('${s.label} (${s.value})', style: const TextStyle(fontSize: 11, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    )).toList(),
                  ),
                ),
              ]),
            ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  READY CARS LIST
  // ════════════════════════════════════════════════════════
  Widget _buildReadyCars() {
    return _cardWrapper(
      icon: Icons.directions_car, iconColor: const Color(0xFF10B981), title: 'سيارات جاهزة للبيع',
      trailing: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.cars), child: const Text('عرض الكل', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600))),
      child: _readyCars.isEmpty
          ? _emptyList(Icons.directions_car, 'لا توجد سيارات جاهزة للبيع')
          : Column(children: _readyCars.map((car) {
              final brand = car['brand'] ?? car['make'] ?? '';
              final model = car['model'] ?? '';
              final vin = car['vin'] ?? '';
              final year = car['year'] ?? '';
              final color = car['color'] ?? '';
              final cost = _pd(car['purchase_price'] ?? car['purchasePrice'] ?? car['selling_price']);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$brand $model', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text('$vin | $year | $color', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ])),
                  if (cost > 0) Text('\$${cost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                ]),
              );
            }).toList()),
    );
  }

  // ════════════════════════════════════════════════════════
  //  RECENT SALES LIST
  // ════════════════════════════════════════════════════════
  Widget _buildRecentSales() {
    return _cardWrapper(
      icon: Icons.receipt_long, iconColor: const Color(0xFF8B5CF6), title: 'آخر المبيعات',
      trailing: TextButton(onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.salesPage), child: const Text('عرض الكل', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.w600))),
      child: _recentSales.isEmpty
          ? _emptyList(Icons.receipt_long, 'لا توجد مبيعات بعد')
          : Column(children: _recentSales.map((s) {
              final brand = s['car_brand'] ?? s['carBrand'] ?? s['brand'] ?? s['make'] ?? '';
              final model = s['car_model'] ?? s['carModel'] ?? s['model'] ?? '';
              final buyer = s['buyer_name'] ?? s['buyerName'] ?? s['customer_name'] ?? s['customerName'] ?? '';
              final salePrice = _pd(s['sale_price'] ?? s['selling_price'] ?? s['sellingPrice'] ?? s['salePrice']);
              final purchasePrice = _pd(s['purchase_price'] ?? s['purchasePrice'] ?? s['cost']);
              final profit = salePrice - purchasePrice;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$brand $model', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    if (buyer.toString().isNotEmpty) Text(buyer.toString(), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(_fmtCur(salePrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
                    Text('${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: profit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                  ]),
                ]),
              );
            }).toList()),
    );
  }

  // ════════════════════════════════════════════════════════
  //  6 QUICK LINKS
  // ════════════════════════════════════════════════════════
  Widget _buildQuickLinks() {
    return _cardWrapper(
      icon: Icons.link, iconColor: const Color(0xFFF59E0B), title: 'روابط سريعة',
      child: GridView.count(
        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
        children: [
          _quickBtn(Icons.directions_car, 'السيارات', const Color(0xFF3B82F6), AppRoutes.cars),
          _quickBtn(Icons.point_of_sale, 'المبيعات', const Color(0xFF8B5CF6), AppRoutes.salesPage),
          _quickBtn(Icons.people, 'الموردين', const Color(0xFF10B981), AppRoutes.suppliersPage),
          _quickBtn(Icons.inventory_2, 'الحاويات', const Color(0xFFF59E0B), AppRoutes.containersPage),
          _quickBtn(Icons.show_chart, 'الأرباح', const Color(0xFF059669), AppRoutes.profitsPage),
          _quickBtn(Icons.account_balance, 'الحسابات', const Color(0xFF4F46E5), AppRoutes.accounts),
        ],
      ),
    );
  }

  Widget _quickBtn(IconData icon, String label, Color color, String route) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => Navigator.pushReplacementNamed(context, route),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════
  Widget _cardWrapper({required IconData icon, required Color iconColor, required String title, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
          if (trailing != null) trailing,
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }

  Widget _emptyList(IconData icon, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Icon(icon, size: 36, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(msg, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ]),
    );
  }
}

// ── Data classes ──

class _MonthData {
  final String label;
  final int salesCount;
  final double profit;
  _MonthData({required this.label, required this.salesCount, required this.profit});
}

class _StatusSlice {
  final String label;
  final int value;
  final Color color;
  _StatusSlice(this.label, this.value, this.color);
}
