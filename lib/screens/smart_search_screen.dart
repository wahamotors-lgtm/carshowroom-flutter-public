import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class SmartSearchScreen extends StatefulWidget {
  const SmartSearchScreen({super.key});

  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  late final DataService _dataService;
  final _searchController = TextEditingController();
  Map<String, dynamic> _results = {};
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;

  // Debounce timer
  DateTime _lastSearchTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dataService = DataService(ApiService());
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = {}; _hasSearched = false; _error = null; });
      return;
    }

    final searchTime = DateTime.now();
    _lastSearchTime = searchTime;

    // Debounce: wait 400ms before searching
    await Future.delayed(const Duration(milliseconds: 400));
    if (_lastSearchTime != searchTime) return; // A newer search was triggered

    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _dataService.smartSearch(_token, query.trim());
      if (!mounted) return;
      if (_lastSearchTime != searchTime) return; // Stale result
      setState(() { _results = data; _hasSearched = true; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      if (_lastSearchTime != searchTime) return;
      setState(() { _error = 'فشل البحث، حاول مرة أخرى'; _isLoading = false; _hasSearched = true; });
    }
  }

  int get _totalResults {
    int count = 0;
    for (final key in _results.keys) {
      final val = _results[key];
      if (val is List) count += val.length;
    }
    return count;
  }

  // Category config: key -> (Arabic label, icon, color, route)
  static const Map<String, _CategoryConfig> _categoryConfigs = {
    'cars': _CategoryConfig('السيارات', Icons.directions_car, Color(0xFF059669), AppRoutes.cars),
    'customers': _CategoryConfig('العملاء', Icons.people_outline, Color(0xFF0891B2), AppRoutes.customersPage),
    'suppliers': _CategoryConfig('الموردين', Icons.local_shipping_outlined, Color(0xFFD97706), AppRoutes.suppliersPage),
    'employees': _CategoryConfig('الموظفين', Icons.badge_outlined, Color(0xFF2563EB), AppRoutes.employeesPage),
    'sales': _CategoryConfig('المبيعات', Icons.point_of_sale_outlined, Color(0xFF7C3AED), AppRoutes.salesPage),
    'expenses': _CategoryConfig('المصروفات', Icons.add_card_outlined, Color(0xFFEF4444), AppRoutes.expenseRecord),
    'shipments': _CategoryConfig('الشحنات', Icons.local_shipping, Color(0xFF0D9488), AppRoutes.shipmentsPage),
    'containers': _CategoryConfig('الحاويات', Icons.inventory_2_outlined, Color(0xFF6366F1), AppRoutes.containersPage),
    'warehouses': _CategoryConfig('المستودعات', Icons.warehouse_outlined, Color(0xFF78716C), AppRoutes.warehousesPage),
    'accounts': _CategoryConfig('الحسابات', Icons.account_balance_outlined, Color(0xFF0284C7), AppRoutes.accounts),
    'payments': _CategoryConfig('المدفوعات', Icons.payment_outlined, Color(0xFF059669), AppRoutes.paymentsPage),
    'rentals': _CategoryConfig('الإيجارات', Icons.home_outlined, Color(0xFFB45309), AppRoutes.rentalsPage),
    'bills': _CategoryConfig('الفواتير', Icons.receipt_outlined, Color(0xFFDC2626), AppRoutes.billsPage),
    'notes': _CategoryConfig('الملاحظات', Icons.note_outlined, Color(0xFF64748B), AppRoutes.notesPage),
    'commissions': _CategoryConfig('العمولات', Icons.monetization_on_outlined, Color(0xFF16A34A), AppRoutes.commissionsPage),
    'deliveries': _CategoryConfig('التسليمات', Icons.delivery_dining_outlined, Color(0xFF9333EA), AppRoutes.deliveriesPage),
    'consignment_cars': _CategoryConfig('سيارات الأمانة', Icons.car_rental_outlined, Color(0xFF0891B2), AppRoutes.consignmentCarsPage),
    'air_flights': _CategoryConfig('الرحلات الجوية', Icons.flight_outlined, Color(0xFF2563EB), AppRoutes.airFlightsPage),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث الذكي', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.smartSearchPage),
      body: Column(children: [
        // Search field
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (q) => _performSearch(q),
            decoration: InputDecoration(
              hintText: 'ابحث في كل شيء...', hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 24),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() { _results = {}; _hasSearched = false; _error = null; });
                      },
                    )
                  : null,
              filled: true, fillColor: AppColors.bgLight,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
        ),
        // Results count
        if (_hasSearched && !_isLoading && _error == null)
          Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: Colors.white,
            child: Text('$_totalResults نتيجة', style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        const Divider(height: 1),
        // Body
        Expanded(
          child: _isLoading
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('جاري البحث...', style: TextStyle(color: AppColors.textGray, fontSize: 14)),
                ]))
              : _error != null
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _performSearch(_searchController.text),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ]))
                  : !_hasSearched
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.manage_search_rounded, size: 72, color: AppColors.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text('ابدأ البحث...', style: TextStyle(color: AppColors.textGray, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('ابحث في السيارات، العملاء، الموردين، الموظفين والمزيد',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
                        ]))
                      : _totalResults == 0
                          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
                              SizedBox(height: 12),
                              Text('لا توجد نتائج', style: TextStyle(color: AppColors.textGray, fontSize: 16, fontWeight: FontWeight.w600)),
                              SizedBox(height: 8),
                              Text('جرب كلمات بحث مختلفة', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            ]))
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 24),
                              children: _buildCategorySections(),
                            ),
        ),
      ]),
    );
  }

  List<Widget> _buildCategorySections() {
    final List<Widget> sections = [];

    for (final key in _results.keys) {
      final val = _results[key];
      if (val is! List || val.isEmpty) continue;
      final items = val.cast<Map<String, dynamic>>();
      final config = _categoryConfigs[key] ?? _CategoryConfig(key, Icons.article_outlined, AppColors.textGray, AppRoutes.dashboard);

      sections.add(_buildSectionHeader(config.label, config.icon, config.color, items.length));
      for (final item in items) {
        sections.add(_buildResultCard(item, key, config));
      }
      sections.add(const SizedBox(height: 8));
    }

    return sections;
  }

  Widget _buildSectionHeader(String label, IconData icon, Color color, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
      ]),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item, String category, _CategoryConfig config) {
    final name = _extractName(item, category);
    final subtitle = _extractSubtitle(item, category);
    final trailing = _extractTrailing(item, category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: config.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(config.icon, color: config.color, size: 22),
        ),
        title: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: trailing.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: config.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(trailing, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: config.color)),
              )
            : null,
        onTap: () => Navigator.pushNamed(context, config.route),
      ),
    );
  }

  String _extractName(Map<String, dynamic> item, String category) {
    switch (category) {
      case 'cars':
        final make = item['make'] ?? item['brand'] ?? '';
        final model = item['model'] ?? '';
        final year = item['year'] ?? '';
        return '$make $model ${year != '' ? '($year)' : ''}'.trim();
      case 'customers':
        return item['name'] ?? item['customer_name'] ?? '';
      case 'suppliers':
        return item['name'] ?? item['supplier_name'] ?? '';
      case 'employees':
        return item['name'] ?? item['employee_name'] ?? '';
      case 'sales':
        final customer = item['customer_name'] ?? item['customerName'] ?? '';
        final car = item['car_name'] ?? item['carName'] ?? '';
        if (customer.toString().isNotEmpty && car.toString().isNotEmpty) return '$customer - $car';
        if (customer.toString().isNotEmpty) return customer.toString();
        return 'عملية بيع #${item['_id'] ?? item['id'] ?? ''}';
      case 'expenses':
        return item['description'] ?? item['category'] ?? 'مصروف';
      case 'shipments':
        return item['tracking_number'] ?? item['trackingNumber'] ?? item['name'] ?? 'شحنة';
      case 'containers':
        return item['container_number'] ?? item['containerNumber'] ?? item['name'] ?? 'حاوية';
      case 'warehouses':
        return item['name'] ?? 'مستودع';
      case 'accounts':
        return item['name'] ?? item['account_name'] ?? 'حساب';
      case 'payments':
        return item['description'] ?? item['reference'] ?? 'دفعة';
      case 'rentals':
        return item['property_name'] ?? item['propertyName'] ?? item['name'] ?? 'إيجار';
      case 'bills':
        return item['name'] ?? item['bill_name'] ?? item['type'] ?? 'فاتورة';
      case 'notes':
        return item['title'] ?? item['content']?.toString().substring(0, (item['content']?.toString().length ?? 0).clamp(0, 50)) ?? 'ملاحظة';
      case 'commissions':
        return item['employee_name'] ?? item['employeeName'] ?? 'عمولة';
      case 'deliveries':
        return item['recipient'] ?? item['recipient_name'] ?? item['name'] ?? 'تسليم';
      case 'consignment_cars':
        final make = item['make'] ?? item['brand'] ?? '';
        final model = item['model'] ?? '';
        return '$make $model'.trim().isEmpty ? 'سيارة أمانة' : '$make $model'.trim();
      case 'air_flights':
        return item['flight_number'] ?? item['flightNumber'] ?? item['name'] ?? 'رحلة جوية';
      default:
        return item['name'] ?? item['title'] ?? item['_id']?.toString() ?? '';
    }
  }

  String _extractSubtitle(Map<String, dynamic> item, String category) {
    final parts = <String>[];
    switch (category) {
      case 'cars':
        final vin = item['vin'] ?? '';
        final color = item['color'] ?? '';
        final status = item['status'] ?? '';
        if (vin.toString().isNotEmpty) parts.add('VIN: ${vin.toString().length > 10 ? '...${vin.toString().substring(vin.toString().length - 10)}' : vin}');
        if (color.toString().isNotEmpty) parts.add(color.toString());
        if (status.toString().isNotEmpty) parts.add(_translateCarStatus(status.toString()));
        break;
      case 'customers':
        final phone = item['phone'] ?? '';
        final code = item['customer_code'] ?? item['customerCode'] ?? '';
        if (code.toString().isNotEmpty) parts.add('كود: $code');
        if (phone.toString().isNotEmpty) parts.add(phone.toString());
        break;
      case 'suppliers':
        final phone = item['phone'] ?? '';
        final country = item['country'] ?? '';
        if (phone.toString().isNotEmpty) parts.add(phone.toString());
        if (country.toString().isNotEmpty) parts.add(country.toString());
        break;
      case 'employees':
        final role = item['role'] ?? '';
        final email = item['email'] ?? '';
        if (role.toString().isNotEmpty) parts.add(role.toString());
        if (email.toString().isNotEmpty) parts.add(email.toString());
        break;
      case 'sales':
        final amount = item['total_amount'] ?? item['totalAmount'] ?? item['amount'];
        final date = item['date'] ?? item['created_at'] ?? item['createdAt'] ?? '';
        if (amount != null) parts.add('$amount \$');
        if (date.toString().isNotEmpty) parts.add(_formatDate(date.toString()));
        break;
      case 'expenses':
        final amount = item['amount'];
        final date = item['date'] ?? item['created_at'] ?? '';
        if (amount != null) parts.add('$amount \$');
        if (date.toString().isNotEmpty) parts.add(_formatDate(date.toString()));
        break;
      case 'shipments':
        final status = item['status'] ?? '';
        final origin = item['origin'] ?? '';
        final dest = item['destination'] ?? '';
        if (status.toString().isNotEmpty) parts.add(status.toString());
        if (origin.toString().isNotEmpty && dest.toString().isNotEmpty) parts.add('$origin -> $dest');
        break;
      case 'containers':
        final status = item['status'] ?? '';
        final size = item['size'] ?? '';
        if (status.toString().isNotEmpty) parts.add(status.toString());
        if (size.toString().isNotEmpty) parts.add(size.toString());
        break;
      case 'accounts':
        final type = item['type'] ?? item['account_type'] ?? '';
        final balance = item['balance'];
        if (type.toString().isNotEmpty) parts.add(type.toString());
        if (balance != null) parts.add('$balance \$');
        break;
      case 'payments':
        final amount = item['amount'];
        final date = item['date'] ?? item['created_at'] ?? '';
        if (amount != null) parts.add('$amount \$');
        if (date.toString().isNotEmpty) parts.add(_formatDate(date.toString()));
        break;
      case 'notes':
        final content = item['content'] ?? '';
        if (content.toString().isNotEmpty) {
          parts.add(content.toString().length > 60 ? '${content.toString().substring(0, 60)}...' : content.toString());
        }
        break;
      default:
        final phone = item['phone'] ?? '';
        final email = item['email'] ?? '';
        if (phone.toString().isNotEmpty) parts.add(phone.toString());
        if (email.toString().isNotEmpty) parts.add(email.toString());
    }
    return parts.join(' | ');
  }

  String _extractTrailing(Map<String, dynamic> item, String category) {
    switch (category) {
      case 'cars':
        final price = item['price'] ?? item['selling_price'] ?? item['sellingPrice'];
        return price != null ? '$price \$' : '';
      case 'customers':
        final balance = item['balance'];
        return balance != null ? '${balance.toString()} \$' : '';
      case 'employees':
        final isActive = item['is_active'] ?? item['isActive'];
        if (isActive == true) return 'نشط';
        if (isActive == false) return 'معطل';
        return '';
      case 'sales':
        final status = item['status'] ?? '';
        return status.toString();
      case 'expenses':
        final category = item['category'] ?? '';
        return category.toString();
      case 'bills':
        final isPaid = item['is_paid'] ?? item['isPaid'];
        if (isPaid == true) return 'مدفوعة';
        if (isPaid == false) return 'غير مدفوعة';
        return '';
      default:
        return '';
    }
  }

  String _translateCarStatus(String status) {
    switch (status.toLowerCase()) {
      case 'sold': return 'مباع';
      case 'in_showroom': case 'available': return 'في المعرض';
      case 'in_transit': case 'shipping': return 'في الشحن';
      case 'in_korea': case 'purchased': return 'في كوريا';
      default: return status;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }
}

class _CategoryConfig {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _CategoryConfig(this.label, this.icon, this.color, this.route);
}
