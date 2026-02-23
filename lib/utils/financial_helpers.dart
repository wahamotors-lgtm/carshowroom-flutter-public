/// Financial helper functions matching the web app (carwhats-group-app) calculations exactly.
/// These replicate: getExchangeRateValue, getCarLinkedExpensesTotalUSD,
/// calculateCarTotalCost, getSalePriceInUSD, getSaleDynamicProfit.

class FinancialHelpers {
  final List<Map<String, dynamic>> _currencies;
  final List<Map<String, dynamic>> _exchangeRates;
  final List<Map<String, dynamic>> _expenses;

  FinancialHelpers({
    required List<Map<String, dynamic>> currencies,
    List<Map<String, dynamic>> exchangeRates = const [],
    List<Map<String, dynamic>> expenses = const [],
  })  : _currencies = currencies,
        _exchangeRates = exchangeRates,
        _expenses = expenses;

  // ── Parse helpers ──

  static double pd(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static String _s(dynamic v) => (v ?? '').toString();

  // ── Exchange Rate ──

  /// Get the latest exchange rate value from fromCurrency to toCurrency.
  /// Matches web: getExchangeRateValue(fromCurrency, toCurrency)
  double getExchangeRateValue(String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return 1;

    // Try direct rate from exchange rate history
    final direct = _getLatestRate(fromCurrency, toCurrency);
    if (direct != null) return direct;

    // Try inverse
    final inverse = _getLatestRate(toCurrency, fromCurrency);
    if (inverse != null && inverse != 0) return 1 / inverse;

    // Try using currencies table (rate_to_usd)
    if (toCurrency == 'USD') {
      final fromRate = _getCurrencyRateToUSD(fromCurrency);
      if (fromRate != null && fromRate != 0) return 1 / fromRate;
    }
    if (fromCurrency == 'USD') {
      final toRate = _getCurrencyRateToUSD(toCurrency);
      if (toRate != null) return toRate;
    }

    // Hardcoded fallbacks (matching web app exactly)
    if (fromCurrency == 'AED' && toCurrency == 'USD') return 1 / 3.67;
    if (fromCurrency == 'USD' && toCurrency == 'AED') return 3.67;

    return 1; // Ultimate fallback
  }

  double? _getLatestRate(String from, String to) {
    final matching = _exchangeRates.where((r) {
      final fc = _s(r['from_currency'] ?? r['fromCurrency']);
      final tc = _s(r['to_currency'] ?? r['toCurrency']);
      return fc == from && tc == to;
    }).toList();
    if (matching.isEmpty) return null;
    matching.sort((a, b) {
      final da = _s(a['date'] ?? a['effective_from'] ?? a['created_at']);
      final db = _s(b['date'] ?? b['effective_from'] ?? b['created_at']);
      return db.compareTo(da);
    });
    return pd(matching.first['rate'] ?? matching.first['rate_to_usd']);
  }

  double? _getCurrencyRateToUSD(String code) {
    for (final c in _currencies) {
      if (_s(c['code']) == code) {
        final rate = pd(c['rate_to_usd'] ?? c['rateToUsd']);
        if (rate > 0) return rate;
      }
    }
    return null;
  }

  /// Convert any amount to USD
  double convertToUSD(double amount, String currency) {
    if (currency == 'USD') return amount;
    final rate = getExchangeRateValue(currency, 'USD');
    return amount * rate;
  }

  /// Convert amount from USD to target currency
  double convertFromUSD(double amountUSD, String targetCurrency) {
    if (targetCurrency == 'USD') return amountUSD;
    final rate = getExchangeRateValue('USD', targetCurrency);
    return amountUSD * rate;
  }

  // ── Car Cost Calculations ──

  /// Get expenses linked to a specific car.
  List<Map<String, dynamic>> getCarLinkedExpenses(String carId) {
    return _expenses
        .where((e) => _s(e['car_id'] ?? e['carId']) == carId)
        .toList();
  }

  /// Total of car-linked expenses converted to USD.
  /// Matches web: getCarLinkedExpensesTotalUSD(carId)
  double getCarLinkedExpensesTotalUSD(String carId) {
    final carExpenses = getCarLinkedExpenses(carId);
    double total = 0;
    for (final e in carExpenses) {
      final amount = pd(e['amount']);
      final currency = _s(e['currency']);
      if (currency.isEmpty || currency == 'USD') {
        total += amount;
      } else {
        // Try exchange rate history first
        final rates = _exchangeRates.where((r) {
          final fc = _s(r['from_currency'] ?? r['fromCurrency'] ?? r['currency_id']);
          final tc = _s(r['to_currency'] ?? r['toCurrency']);
          return (fc == currency.toLowerCase() || fc == currency) &&
              (tc == 'USD' || tc == 'usd' || tc.isEmpty);
        }).toList();
        if (rates.isNotEmpty) {
          rates.sort((a, b) {
            final da = _s(a['date'] ?? a['effective_from'] ?? a['created_at']);
            final db = _s(b['date'] ?? b['effective_from'] ?? b['created_at']);
            return db.compareTo(da);
          });
          final rate = pd(rates.first['rate'] ?? rates.first['rate_to_usd']);
          if (rate > 0) {
            total += amount / rate;
            continue;
          }
        }
        // Fallback using currencies table
        final currRate = _getCurrencyRateToUSD(currency);
        if (currRate != null && currRate > 0) {
          total += amount / currRate;
        } else if (currency == 'AED') {
          total += amount / 3.67;
        } else if (currency == 'KRW') {
          total += amount / 1333;
        } else {
          total += amount;
        }
      }
    }
    return total;
  }

  /// Calculate total cost of a car in USD.
  /// Matches web: calculateCarTotalCost(car)
  /// Formula: purchasePriceUSD + containerShareExpenses + shippingShareExpenses
  ///          + customsExpenses + transportExpenses + linkedExpenses (or directExpenses)
  double calculateCarTotalCost(Map<String, dynamic> car) {
    final carId = _s(car['id']);
    final linkedExpenses = getCarLinkedExpensesTotalUSD(carId);
    final directExpenses = pd(car['direct_expenses'] ?? car['directExpenses']);
    final expensesPart = linkedExpenses > 0 ? linkedExpenses : directExpenses;

    return pd(car['purchase_price_usd'] ?? car['purchasePriceUSD']) +
        pd(car['container_share_expenses'] ?? car['containerShareExpenses']) +
        pd(car['shipping_share_expenses'] ?? car['shippingShareExpenses']) +
        pd(car['customs_expenses'] ?? car['customsExpenses']) +
        pd(car['transport_expenses'] ?? car['transportExpenses']) +
        expensesPart;
  }

  // ── Sale Calculations ──

  /// Get sale price in USD.
  /// Matches web: getSalePriceInUSD(sale)
  double getSalePriceInUSD(Map<String, dynamic> sale) {
    final spUSD = pd(sale['sale_price_usd'] ?? sale['salePriceUSD']);
    if (spUSD > 0) return spUSD;

    final sp = pd(sale['sale_price'] ?? sale['salePrice']);
    final sc = _s(sale['sale_currency'] ?? sale['saleCurrency']);
    if (sp > 0 && sc.isNotEmpty) {
      if (sc == 'USD') return sp;
      return sp * getExchangeRateValue(sc, 'USD');
    }
    return 0;
  }

  /// Calculate dynamic profit for a sale.
  /// Matches web: getSaleDynamicProfit(sale)
  /// Formula: salePriceInUSD - calculateCarTotalCost(car)
  double getSaleDynamicProfit(
      Map<String, dynamic> sale, List<Map<String, dynamic>> cars) {
    final carId = _s(sale['car_id'] ?? sale['carId']);
    final car = cars.cast<Map<String, dynamic>?>().firstWhere(
          (c) => _s(c!['id']) == carId,
          orElse: () => null,
        );
    if (car == null) return pd(sale['profit']);

    final salePriceUSD = getSalePriceInUSD(sale);
    if (salePriceUSD <= 0) return pd(sale['profit']);

    final totalCost = calculateCarTotalCost(car);
    return salePriceUSD - totalCost;
  }

  /// Get total profit across all non-cancelled sales.
  /// Matches web: getTotalProfit()
  double getTotalProfit(List<Map<String, dynamic>> sales,
      List<Map<String, dynamic>> cars) {
    return sales
        .where((s) => s['is_cancelled'] != true && _s(s['is_cancelled']) != 'true')
        .fold(0.0, (sum, s) => sum + getSaleDynamicProfit(s, cars));
  }

  // ── Account Balance Calculations ──

  /// تحديد ما إذا كان الحساب ذو طبيعة مدينة
  static bool isDebitNormalAccount(String accountType) {
    const debitNormalTypes = [
      'cash_box', 'cash', 'bank', 'customer', 'receivable', 'expense',
      'showroom', 'customs', 'employee', 'purchases', 'shipping_company', 'asset'
    ];
    return debitNormalTypes.contains(accountType);
  }

  /// Calculate account balances from journal entries (matching web app).
  /// Returns map of accountId -> balance in USD (with isDebitNormal awareness)
  Map<String, double> calculateAccountBalances(
      List<Map<String, dynamic>> journalEntries,
      {List<Map<String, dynamic>> accounts = const []}) {
    // بناء خريطة معلومات الحسابات
    final accountInfoMap = <String, bool>{};
    for (final acc in accounts) {
      final id = _s(acc['id']);
      final type = _s(acc['type']);
      if (id.isNotEmpty) {
        accountInfoMap[id] = isDebitNormalAccount(type);
      }
    }

    final balances = <String, double>{};
    for (final je in journalEntries) {
      final amount = pd(je['amount']);
      final currency = _s(je['currency']);
      final amountUSD = convertToUSD(amount, currency.isEmpty ? 'USD' : currency);

      final debitId = _s(je['debit_account_id'] ?? je['debitAccountId']);
      final creditId = _s(je['credit_account_id'] ?? je['creditAccountId']);

      // التحقق من نفس الحساب على الجانبين
      final isSameAccount = debitId.isNotEmpty && creditId.isNotEmpty && debitId == creditId;

      // دعم القيود متعددة العملات
      final creditAmount = pd(je['credit_amount'] ?? je['creditAmount']);
      final creditCurrency = _s(je['credit_currency'] ?? je['creditCurrency']);
      final effectiveCreditAmount = creditAmount > 0 ? creditAmount : amount;
      final effectiveCreditCurrency = creditCurrency.isNotEmpty ? creditCurrency : (currency.isNotEmpty ? currency : 'USD');
      final creditAmountUSD = convertToUSD(effectiveCreditAmount, effectiveCreditCurrency);

      if (debitId.isNotEmpty) {
        final isDebitNormal = accountInfoMap[debitId] ?? true;
        balances[debitId] = (balances[debitId] ?? 0) + (isDebitNormal ? amountUSD : -amountUSD);
      }
      if (creditId.isNotEmpty && !isSameAccount) {
        final isDebitNormal = accountInfoMap[creditId] ?? true;
        balances[creditId] = (balances[creditId] ?? 0) + (isDebitNormal ? -creditAmountUSD : creditAmountUSD);
      }
    }
    return balances;
  }

  /// Hierarchical balance rollup (parent accounts include children).
  double getHierarchicalBalance(
    String accountId,
    Map<String, double> flatBalances,
    List<Map<String, dynamic>> accounts,
  ) {
    double balance = flatBalances[accountId] ?? 0;
    for (final acc in accounts) {
      final parentId = _s(acc['parent_id'] ?? acc['parentId']);
      if (parentId == accountId) {
        balance += getHierarchicalBalance(_s(acc['id']), flatBalances, accounts);
      }
    }
    return balance;
  }

  // ── Formatting ──

  static String formatNumber(double value, {int decimals = 2}) {
    final isNegative = value < 0;
    final absValue = value.abs();
    final parts = absValue.toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()}$decPart';
  }

  static String formatUSD(double value) => '\$${formatNumber(value)}';
}
