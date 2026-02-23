import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/financial_helpers.dart';

class ProfitsScreen extends StatefulWidget {
  const ProfitsScreen({super.key});
  @override
  State<ProfitsScreen> createState() => _ProfitsScreenState();
}

class _ProfitsScreenState extends State<ProfitsScreen> with SingleTickerProviderStateMixin {
  late final DataService _ds;
  late final TabController _tabController;

  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _exchangeRates = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCurrency = 'USD';
  FinancialHelpers? _fh;

  static const _currencyOptions = ['USD', 'AED', 'KRW', 'CNY', 'SYP', 'SAR'];

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _ds.getCars(_token),
        _ds.getSales(_token),
        _ds.getExpenses(_token),
        _ds.getAccounts(_token),
        _ds.getJournalEntries(_token),
        _ds.getCurrencies(_token).catchError((_) => <Map<String, dynamic>>[]),
        _ds.getExchangeRateHistory(_token).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _cars = results[0];
        _sales = results[1];
        _expenses = results[2];
        _accounts = results[3];
        _journalEntries = results[4];
        _currencies = results[5];
        _exchangeRates = results[6];
        _fh = FinancialHelpers(
          currencies: _currencies,
          exchangeRates: _exchangeRates,
          expenses: _expenses,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  // ── Computed data ──

  double _pd(dynamic v) => FinancialHelpers.pd(v);
  String _s(dynamic v) => (v ?? '').toString();

  List<Map<String, dynamic>> get _activeSales =>
      _sales.where((s) => s['is_cancelled'] != true && _s(s['is_cancelled']) != 'true').toList();

  List<Map<String, dynamic>> get _salesWithProfit {
    if (_fh == null) return [];
    return _activeSales.map((s) {
      final carId = _s(s['car_id'] ?? s['carId']);
      final car = _cars.cast<Map<String, dynamic>?>().firstWhere(
            (c) => _s(c!['id']) == carId, orElse: () => null);
      final salePriceUSD = _fh!.getSalePriceInUSD(s);
      final totalCost = car != null ? _fh!.calculateCarTotalCost(car) : _pd(s['total_cost']);
      final profit = salePriceUSD - totalCost;
      return {
        ...s,
        '_salePriceUSD': salePriceUSD,
        '_totalCost': totalCost,
        '_profit': profit,
        '_car': car,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get _unsoldCars =>
      _cars.where((c) => _s(c['status']) != 'sold').toList();

  double get _totalSalesRevenue {
    if (_fh == null) return 0;
    return _activeSales.fold(0.0, (sum, s) => sum + _fh!.getSalePriceInUSD(s));
  }

  double get _totalCOGS => _salesWithProfit.fold(0.0, (sum, s) => sum + _pd(s['_totalCost']));

  double get _grossProfitFromSales => _totalSalesRevenue - _totalCOGS;

  double get _inventoryValue {
    if (_fh == null) return 0;
    return _unsoldCars.fold(0.0, (sum, c) => sum + _fh!.calculateCarTotalCost(c));
  }

  double get _totalCarExpenses {
    if (_fh == null) return 0;
    return _expenses
        .where((e) => _s(e['car_id'] ?? e['carId']).isNotEmpty)
        .fold(0.0, (sum, e) => sum + _fh!.convertToUSD(_pd(e['amount']), _s(e['currency']).isEmpty ? 'USD' : _s(e['currency'])));
  }

  // ── Account-based calculations (Real Profits) ──

  Map<String, double> get _accountBalances {
    if (_fh == null) return {};
    return _fh!.calculateAccountBalances(_journalEntries, accounts: _accounts);
  }

  double _getAccountTypeTotal(List<String> types) {
    double total = 0;
    for (final acc in _accounts) {
      final type = _s(acc['type']);
      if (types.contains(type)) {
        final id = _s(acc['id']);
        total += _fh!.getHierarchicalBalance(id, _accountBalances, _accounts);
      }
    }
    return total;
  }

  double get _directRevenue => _getAccountTypeTotal(['revenue']);

  double get _generalExpensesTotal {
    if (_fh == null) return 0;
    // Sum journal entries where debit account is expense type, excluding car-linked
    double total = 0;
    final expenseAccountIds = _accounts
        .where((a) => _s(a['type']) == 'expense')
        .map((a) => _s(a['id']))
        .toSet();
    // Excluded account names (purchase/car expenses are in COGS, not general)
    final excludedNames = {'مصاريف المشتريات', 'مصاريف سيارات', 'مصاريف الشحن', 'car expenses', 'purchase expenses'};
    final excludedIds = _accounts
        .where((a) => excludedNames.contains(_s(a['name']).trim().toLowerCase()) || excludedNames.contains(_s(a['name']).trim()))
        .map((a) => _s(a['id']))
        .toSet();

    for (final je in _journalEntries) {
      final debitId = _s(je['debit_account_id'] ?? je['debitAccountId']);
      if (debitId.isEmpty || !expenseAccountIds.contains(debitId)) continue;
      if (excludedIds.contains(debitId)) continue;
      // Exclude car-linked entries
      final refType = _s(je['reference_type'] ?? je['referenceType']);
      if (refType == 'car' || refType == 'sale') continue;
      final amount = _pd(je['amount']);
      final currency = _s(je['currency']);
      total += _fh!.convertToUSD(amount, currency.isEmpty ? 'USD' : currency);
    }
    return total;
  }

  double get _netProfit => (_totalSalesRevenue + _directRevenue) - _totalCOGS - _generalExpensesTotal;

  double get _cashBankTotal {
    double total = 0;
    for (final acc in _accounts) {
      final type = _s(acc['type']);
      if (['cash_box', 'cash', 'bank'].contains(type)) {
        total += _fh!.getHierarchicalBalance(_s(acc['id']), _accountBalances, _accounts);
      }
    }
    return total;
  }

  double get _receivablesTotal {
    double total = 0;
    for (final acc in _accounts) {
      final type = _s(acc['type']);
      if (['customer', 'receivable', 'supplier', 'payable', 'liability'].contains(type)) {
        final bal = _fh!.getHierarchicalBalance(_s(acc['id']), _accountBalances, _accounts);
        final isDebitNormal = FinancialHelpers.isDebitNormalAccount(type);
        final normalizedBalance = isDebitNormal ? bal : -bal;
        if (normalizedBalance > 0) total += normalizedBalance;
      }
    }
    return total;
  }

  double get _payablesTotal {
    double total = 0;
    for (final acc in _accounts) {
      final type = _s(acc['type']);
      if (['customer', 'receivable', 'supplier', 'payable', 'liability'].contains(type)) {
        final bal = _fh!.getHierarchicalBalance(_s(acc['id']), _accountBalances, _accounts);
        final isDebitNormal = FinancialHelpers.isDebitNormalAccount(type);
        final normalizedBalance = isDebitNormal ? bal : -bal;
        if (normalizedBalance < 0) total += normalizedBalance.abs();
      }
    }
    return total;
  }

  double get _capitalTotal => _getAccountTypeTotal(['capital']);

  /// Adjustment for car costs recorded in cars/expenses tables but missing from purchase journal entries.
  /// This ensures balance sheet profit matches income statement profit.
  double get _inventoryAdjustment {
    final purchasesJE = _getAccountTypeTotal(['purchases']);
    final totalCarCosts = _inventoryValue + _totalCOGS;
    final diff = totalCarCosts - purchasesJE;
    return diff > 0.01 ? diff : 0;
  }

  double get _netAssets => _inventoryValue + _receivablesTotal + _cashBankTotal - _payablesTotal - _inventoryAdjustment;
  double get _balanceSheetProfit => _netAssets - _capitalTotal;

  String _fmt(double v) => FinancialHelpers.formatNumber(v);
  String _fmtUSD(double v) => FinancialHelpers.formatUSD(v);

  double _toDisplay(double usd) {
    if (_fh == null || _selectedCurrency == 'USD') return usd;
    return _fh!.convertFromUSD(usd, _selectedCurrency);
  }

  String _fmtDisplay(double usd) => _fmt(_toDisplay(usd));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرباح والإيرادات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'السيارات المباعة'),
            Tab(text: 'المخزون'),
            Tab(text: 'المصاريف'),
            Tab(text: 'الرسوم البيانية'),
            Tab(text: '  الأرباح الحقيقية  '),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.currency_exchange, color: Colors.white),
            onSelected: (v) => setState(() => _selectedCurrency = v),
            itemBuilder: (_) => _currencyOptions.map((c) =>
              PopupMenuItem(value: c, child: Text(c, style: TextStyle(
                fontWeight: c == _selectedCurrency ? FontWeight.bold : FontWeight.normal,
              )))).toList(),
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.profitsPage),
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
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSoldCarsTab(),
                    _buildInventoryTab(),
                    _buildExpensesTab(),
                    _buildChartsTab(),
                    _buildRealProfitsTab(),
                  ],
                ),
    );
  }

  // ══════════════════════════════════════════
  // TAB 1: Sold Cars
  // ══════════════════════════════════════════

  Widget _buildSoldCarsTab() {
    final data = _salesWithProfit;
    final totalRevenue = _totalSalesRevenue;
    final totalCost = _totalCOGS;
    final totalProfit = totalRevenue - totalCost;
    final profitPct = totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0.0;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Summary row
          _buildMiniSummaryRow([
            _MiniStat('المبيعات', _fmtDisplay(totalRevenue), AppColors.primary),
            _MiniStat('التكاليف', _fmtDisplay(totalCost), AppColors.error),
            _MiniStat('صافي الربح', _fmtDisplay(totalProfit), totalProfit >= 0 ? AppColors.success : AppColors.error),
            _MiniStat('النسبة', '${profitPct.toStringAsFixed(1)}%', AppColors.blue600),
          ]),
          const SizedBox(height: 8),
          Text('${data.length} سيارة مباعة', style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...data.map((s) => _buildSoldCarCard(s)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSoldCarCard(Map<String, dynamic> s) {
    final profit = _pd(s['_profit']);
    final isProfit = profit >= 0;
    final vin = _s(s['vin']);
    final brand = _s(s['car_brand'] ?? s['carBrand']);
    final model = _s(s['car_model'] ?? s['carModel']);
    final year = _s(s['car_year'] ?? s['carYear']);
    final buyer = _s(s['buyer_name'] ?? s['buyerName']);
    final saleDate = _s(s['sale_date'] ?? s['saleDate'] ?? s['created_at']).split('T').first;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(right: BorderSide(color: isProfit ? AppColors.success : AppColors.error, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text('$brand $model $year', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: (isProfit ? AppColors.success : AppColors.error).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('${isProfit ? '+' : ''}${_fmtDisplay(profit)} $_selectedCurrency',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isProfit ? AppColors.success : AppColors.error)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            if (vin.isNotEmpty) _infoChip(Icons.tag, vin),
            if (buyer.isNotEmpty) _infoChip(Icons.person, buyer),
            if (saleDate.isNotEmpty) _infoChip(Icons.calendar_today, saleDate),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: _miniLabel('سعر البيع', _fmtDisplay(_pd(s['_salePriceUSD'])))),
            Expanded(child: _miniLabel('التكلفة', _fmtDisplay(_pd(s['_totalCost'])))),
          ]),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // TAB 2: Inventory
  // ══════════════════════════════════════════

  Widget _buildInventoryTab() {
    final cars = _unsoldCars;
    final totalValue = _inventoryValue;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildMiniSummaryRow([
            _MiniStat('عدد السيارات', '${cars.length}', AppColors.primary),
            _MiniStat('قيمة المخزون', _fmtDisplay(totalValue), AppColors.blue600),
          ]),
          const SizedBox(height: 8),
          ...cars.map((c) => _buildInventoryCard(c)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> car) {
    final totalCost = _fh?.calculateCarTotalCost(car) ?? 0;
    final brand = _s(car['brand']);
    final model = _s(car['model']);
    final year = _s(car['year']);
    final vin = _s(car['vin']);
    final status = _s(car['status']);
    final purchaseUSD = _pd(car['purchase_price_usd'] ?? car['purchasePriceUSD']);
    final expenses = _fh?.getCarLinkedExpensesTotalUSD(_s(car['id'])) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('$brand $model $year', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          _statusBadge(status),
        ]),
        const SizedBox(height: 6),
        if (vin.isNotEmpty) Text('VIN: $vin', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _miniLabel('سعر الشراء', _fmtDisplay(purchaseUSD))),
          Expanded(child: _miniLabel('المصاريف', _fmtDisplay(expenses))),
          Expanded(child: _miniLabel('التكلفة الإجمالية', _fmtDisplay(totalCost))),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════
  // TAB 3: Expenses
  // ══════════════════════════════════════════

  Widget _buildExpensesTab() {
    final carExpenses = _expenses.where((e) => _s(e['car_id'] ?? e['carId']).isNotEmpty).toList();
    carExpenses.sort((a, b) => _s(b['date'] ?? b['created_at']).compareTo(_s(a['date'] ?? a['created_at'])));
    final display = carExpenses.take(50).toList();

    // Group by type
    final byType = <String, double>{};
    for (final e in carExpenses) {
      final type = _s(e['type'] ?? e['category'] ?? 'other');
      final amount = _fh != null ? _fh!.convertToUSD(_pd(e['amount']), _s(e['currency']).isEmpty ? 'USD' : _s(e['currency'])) : _pd(e['amount']);
      byType[type] = (byType[type] ?? 0) + amount;
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildMiniSummaryRow([
            _MiniStat('مصاريف السيارات', _fmtDisplay(_totalCarExpenses), AppColors.error),
            _MiniStat('عدد القيود', '${carExpenses.length}', AppColors.primary),
          ]),
          const SizedBox(height: 12),
          // Type breakdown
          if (byType.isNotEmpty) ...[
            const Text('تصنيف المصاريف', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...byType.entries.map((e) => _buildExpenseTypeRow(e.key, e.value, _totalCarExpenses)),
            const SizedBox(height: 16),
          ],
          Text('آخر ${display.length} قيد', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...display.map((e) => _buildExpenseRow(e)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildExpenseTypeRow(String type, double amount, double total) {
    final pct = total > 0 ? amount / total : 0.0;
    final labels = {
      'shipping': 'شحن', 'loading': 'تحميل', 'customs': 'جمارك', 'clearance': 'تخليص',
      'staff': 'موظفين', 'port_fees': 'رسوم ميناء', 'government': 'حكومي',
      'transport': 'نقل', 'car_expense': 'مصاريف سيارة', 'other': 'أخرى',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 90, child: Text(labels[type] ?? type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade200, color: AppColors.primary, minHeight: 8),
        )),
        const SizedBox(width: 8),
        Text(_fmtDisplay(amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildExpenseRow(Map<String, dynamic> e) {
    final desc = _s(e['description']);
    final amount = _pd(e['amount']);
    final currency = _s(e['currency']);
    final date = _s(e['date'] ?? e['created_at']).split('T').first;
    final amountUSD = _fh != null ? _fh!.convertToUSD(amount, currency.isEmpty ? 'USD' : currency) : amount;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)]),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(desc.isNotEmpty ? desc : 'مصروف', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ])),
        Text(_fmtDisplay(amountUSD), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.error)),
      ]),
    );
  }

  // ══════════════════════════════════════════
  // TAB 4: Charts (Monthly Performance)
  // ══════════════════════════════════════════

  Widget _buildChartsTab() {
    // Build monthly data for last 6 months
    final now = DateTime.now();
    final months = <Map<String, dynamic>>[];
    final monthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final y = date.year;
      final m = date.month;
      final prefix = '$y-${m.toString().padLeft(2, '0')}';

      final monthSales = _salesWithProfit.where((s) {
        final d = _s(s['sale_date'] ?? s['saleDate'] ?? s['created_at']);
        return d.startsWith(prefix);
      }).toList();

      final revenue = monthSales.fold(0.0, (sum, s) => sum + _pd(s['_salePriceUSD']));
      final cost = monthSales.fold(0.0, (sum, s) => sum + _pd(s['_totalCost']));
      final profit = revenue - cost;

      months.add({
        'label': monthNames[(m - 1) % 12],
        'revenue': revenue,
        'cost': cost,
        'profit': profit,
        'count': monthSales.length,
      });
    }

    final maxVal = months.fold(0.0, (max, m) {
      final v = [_pd(m['revenue']), _pd(m['cost'])].reduce((a, b) => a > b ? a : b);
      return v > max ? v : max;
    });

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('أداء آخر 6 أشهر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          // Bar chart
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final rev = _pd(m['revenue']);
                final cost = _pd(m['cost']);
                final profit = _pd(m['profit']);
                final revH = maxVal > 0 ? (rev / maxVal * 160) : 0.0;
                final costH = maxVal > 0 ? (cost / maxVal * 160) : 0.0;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('${m['count']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 12, height: revH.clamp(2.0, 160.0), decoration: BoxDecoration(
                        color: AppColors.primary, borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 2),
                      Container(width: 12, height: costH.clamp(2.0, 160.0), decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(3))),
                    ]),
                    const SizedBox(height: 4),
                    Text(m['label'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    Text(profit >= 0 ? '+${_fmt(profit)}' : _fmt(profit),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: profit >= 0 ? AppColors.success : AppColors.error)),
                  ]),
                ));
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot(AppColors.primary, 'إيرادات'),
            const SizedBox(width: 16),
            _legendDot(AppColors.error.withValues(alpha: 0.6), 'تكاليف'),
          ]),
          const SizedBox(height: 24),
          // Monthly details table
          const Text('تفاصيل شهرية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...months.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
            child: Row(children: [
              SizedBox(width: 60, child: Text(m['label'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('إيرادات: ${_fmtDisplay(_pd(m['revenue']))}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                Text('تكاليف: ${_fmtDisplay(_pd(m['cost']))}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${m['count']} مبيعات', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Text(_pd(m['profit']) >= 0 ? '+${_fmtDisplay(_pd(m['profit']))}' : _fmtDisplay(_pd(m['profit'])),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _pd(m['profit']) >= 0 ? AppColors.success : AppColors.error)),
              ]),
            ]),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // TAB 5: Real Profits (Income Statement + Balance Sheet)
  // ══════════════════════════════════════════

  Widget _buildRealProfitsTab() {
    final totalRevenue = _totalSalesRevenue + _directRevenue;
    final netProfit = _netProfit;
    final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue * 100) : 0.0;
    final bsProfit = _balanceSheetProfit;
    final diff = (netProfit - bsProfit).abs();
    final isMatch = diff < 1;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Income Statement
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.account_balance, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('قائمة الدخل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
              const SizedBox(height: 16),
              _incomeRow('إيرادات المبيعات', _toDisplay(_totalSalesRevenue)),
              _incomeRow('إيرادات مباشرة', _toDisplay(_directRevenue)),
              const Divider(color: Colors.white30, height: 16),
              _incomeRow('إجمالي الإيرادات', _toDisplay(totalRevenue), bold: true),
              const SizedBox(height: 8),
              _incomeRow('تكلفة البضاعة المباعة (COGS)', _toDisplay(_totalCOGS), negative: true),
              const Divider(color: Colors.white30, height: 16),
              _incomeRow('الربح الإجمالي', _toDisplay(_grossProfitFromSales + _directRevenue), bold: true),
              const SizedBox(height: 8),
              _incomeRow('المصاريف العامة', _toDisplay(_generalExpensesTotal), negative: true),
              const Divider(color: Colors.white54, height: 20),
              Row(children: [
                const Text('صافي الربح', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                const Spacer(),
                Text('${_fmt(_toDisplay(netProfit))} $_selectedCurrency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: netProfit >= 0 ? Colors.greenAccent : Colors.redAccent)),
              ]),
              if (totalRevenue > 0)
                Text('هامش الربح: ${profitMargin.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 16),

          // 5 clickable summary cards
          _buildMiniSummaryRow([
            _MiniStat('إيرادات المبيعات', _fmtDisplay(_totalSalesRevenue), AppColors.primary),
            _MiniStat('إيرادات مباشرة', _fmtDisplay(_directRevenue), AppColors.blue600),
            _MiniStat('COGS', _fmtDisplay(_totalCOGS), AppColors.error),
          ]),
          const SizedBox(height: 8),
          _buildMiniSummaryRow([
            _MiniStat('ربح إجمالي', _fmtDisplay(_grossProfitFromSales + _directRevenue), AppColors.success),
            _MiniStat('مصاريف عامة', _fmtDisplay(_generalExpensesTotal), const Color(0xFFD97706)),
          ]),
          const SizedBox(height: 16),

          // Balance Sheet
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.balance, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('الميزانية العمومية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 14),
              _balanceRow('قيمة المخزون', _inventoryValue),
              _balanceRow('المبالغ المستحقة (مدين)', _receivablesTotal),
              _balanceRow('النقد والبنوك', _cashBankTotal),
              _balanceRow('الالتزامات (دائن)', _payablesTotal, negative: true),
              if (_inventoryAdjustment > 0.01)
                _balanceRow('تعديل مصاريف بدون قيود', _inventoryAdjustment, negative: true),
              const Divider(height: 16),
              _balanceRow('صافي الأصول', _netAssets, bold: true),
              _balanceRow('رأس المال', _capitalTotal, negative: true),
              const Divider(height: 16),
              Row(children: [
                const Text('الربح المحسوب', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${_fmtDisplay(bsProfit)} $_selectedCurrency',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: bsProfit >= 0 ? AppColors.success : AppColors.error)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Verification
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMatch ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isMatch ? AppColors.success : AppColors.error, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(isMatch ? Icons.check_circle : Icons.warning, color: isMatch ? AppColors.success : AppColors.error, size: 20),
                const SizedBox(width: 8),
                Text(isMatch ? 'حساب الإقفال متطابق' : 'يوجد فرق في حساب الإقفال',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isMatch ? AppColors.success : AppColors.error)),
              ]),
              const SizedBox(height: 10),
              _verifyRow('ربح قائمة الدخل', netProfit),
              _verifyRow('ربح الميزانية', bsProfit),
              if (!isMatch) _verifyRow('الفرق', diff),
            ]),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ── Shared widgets ──

  Widget _incomeRow(String label, double value, {bool bold = false, bool negative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: Colors.white))),
        Text('${negative ? '-' : ''}${_fmt(value)} $_selectedCurrency',
          style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: Colors.white)),
      ]),
    );
  }

  Widget _balanceRow(String label, double value, {bool bold = false, bool negative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: AppColors.textDark))),
        Text('${negative ? '-' : ''}${_fmtDisplay(value)} $_selectedCurrency',
          style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: negative ? AppColors.error : AppColors.textDark)),
      ]),
    );
  }

  Widget _verifyRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        Text('${_fmtDisplay(value)} $_selectedCurrency', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildMiniSummaryRow(List<_MiniStat> stats) {
    return Row(children: stats.map((s) => Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Column(children: [
        Text(s.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted), maxLines: 1),
        const SizedBox(height: 4),
        FittedBox(child: Text(s.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: s.color))),
      ]),
    ))).toList());
  }

  Widget _statusBadge(String status) {
    final labels = {'in_stock': 'مخزون', 'in_showroom': 'معرض', 'in_transit': 'طريق', 'in_container': 'حاوية',
      'shipped': 'شُحنت', 'arrived': 'وصلت', 'customs': 'جمارك', 'in_korea_warehouse': 'كوريا', 'sold': 'مباعة'};
    final colors = {'in_stock': AppColors.blue600, 'in_showroom': AppColors.success, 'sold': AppColors.textMuted,
      'in_korea_warehouse': const Color(0xFF3B82F6)};
    final color = colors[status] ?? const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(labels[status] ?? status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _miniLabel(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
    ]);
  }
}

class _MiniStat {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);
}
