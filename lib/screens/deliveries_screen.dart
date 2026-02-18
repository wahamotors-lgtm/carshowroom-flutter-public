import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});
  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late final DataService _ds;
  late final TabController _tabController;

  // Data
  List<Map<String, dynamic>> _deliveries = [];
  List<Map<String, dynamic>> _shipments = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _customers = [];

  // Filtered lists
  List<Map<String, dynamic>> _pendingShipments = [];
  List<Map<String, dynamic>> _deliveryHistory = [];

  // State
  bool _isLoading = true;
  String? _error;
  String? _selectedWarehouseId;
  final _searchController = TextEditingController();
  final _historySearchController = TextEditingController();

  // Sort
  String _sortField = 'created_at';
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _historySearchController.dispose();
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
        _ds.getDeliveries(_token),
        _ds.getShipments(_token),
        _ds.getWarehouses(_token),
        _ds.getCustomers(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _deliveries = results[0];
        _shipments = results[1];
        _warehouses = results[2];
        _customers = results[3];
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'فشل تحميل التوصيلات';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    // Pending shipments - those in warehouse (ready for delivery)
    _pendingShipments = _shipments.where((s) {
      final status = (s['status'] ?? '').toString().toLowerCase();
      final warehouseMatch = _selectedWarehouseId == null ||
          _selectedWarehouseId!.isEmpty ||
          (s['destination_warehouse']?.toString() ?? s['warehouse_id']?.toString() ?? '') ==
              _selectedWarehouseId;
      return (status == 'in_warehouse' || status == 'arrived') && warehouseMatch;
    }).toList();

    // Apply search to pending shipments
    final sq = _searchController.text.trim().toLowerCase();
    if (sq.isNotEmpty) {
      _pendingShipments = _pendingShipments.where((s) {
        final receipt = (s['receipt_number'] ?? s['receiptNumber'] ?? '').toString().toLowerCase();
        final tracking = (s['tracking_number'] ?? s['trackingNumber'] ?? '').toString().toLowerCase();
        final custCode = (s['customer_code'] ?? s['customerCode'] ?? '').toString().toLowerCase();
        final custName = _getShipmentCustomerName(s).toLowerCase();
        final phone = (s['customer_phone'] ?? s['phone'] ?? '').toString().toLowerCase();
        return receipt.contains(sq) ||
            tracking.contains(sq) ||
            custCode.contains(sq) ||
            custName.contains(sq) ||
            phone.contains(sq);
      }).toList();
    }

    // Delivery history
    _deliveryHistory = List.from(_deliveries);

    // Apply search to history
    final hq = _historySearchController.text.trim().toLowerCase();
    if (hq.isNotEmpty) {
      _deliveryHistory = _deliveryHistory.where((d) {
        final recipient = (d['recipient_name'] ?? d['recipientName'] ?? '').toString().toLowerCase();
        final customer = (d['customer_name'] ?? d['customerName'] ?? '').toString().toLowerCase();
        final phone = (d['recipient_phone'] ?? d['recipientPhone'] ?? '').toString().toLowerCase();
        final notes = (d['notes'] ?? '').toString().toLowerCase();
        return recipient.contains(hq) ||
            customer.contains(hq) ||
            phone.contains(hq) ||
            notes.contains(hq);
      }).toList();
    }

    // Sort delivery history
    _deliveryHistory.sort((a, b) {
      dynamic aVal = a[_sortField] ?? '';
      dynamic bVal = b[_sortField] ?? '';
      final compare = aVal.toString().compareTo(bVal.toString());
      return _sortAsc ? compare : -compare;
    });
  }

  // ── Lookup helpers ──

  String _getShipmentCustomerName(Map<String, dynamic> shipment) {
    final custId = shipment['customer_id']?.toString();
    if (custId != null && custId.isNotEmpty) {
      final match = _customers
          .where((c) => (c['id']?.toString() ?? c['_id']?.toString()) == custId)
          .firstOrNull;
      if (match != null) return (match['name'] ?? '').toString();
    }
    return (shipment['customer_name'] ?? shipment['customerName'] ?? '').toString();
  }

  String _getShipmentCustomerCode(Map<String, dynamic> shipment) {
    final custId = shipment['customer_id']?.toString();
    if (custId != null && custId.isNotEmpty) {
      final match = _customers
          .where((c) => (c['id']?.toString() ?? c['_id']?.toString()) == custId)
          .firstOrNull;
      if (match != null) return (match['customer_code'] ?? match['customerCode'] ?? '').toString();
    }
    return (shipment['customer_code'] ?? shipment['customerCode'] ?? '').toString();
  }

  String _getShipmentCustomerPhone(Map<String, dynamic> shipment) {
    final custId = shipment['customer_id']?.toString();
    if (custId != null && custId.isNotEmpty) {
      final match = _customers
          .where((c) => (c['id']?.toString() ?? c['_id']?.toString()) == custId)
          .firstOrNull;
      if (match != null) return (match['phone'] ?? '').toString();
    }
    return (shipment['customer_phone'] ?? shipment['phone'] ?? '').toString();
  }

  Map<String, dynamic>? _getShipmentForDelivery(Map<String, dynamic> delivery) {
    final shipmentId = delivery['shipment_id']?.toString();
    if (shipmentId != null && shipmentId.isNotEmpty) {
      return _shipments
          .where((s) => (s['id']?.toString() ?? s['_id']?.toString()) == shipmentId)
          .firstOrNull;
    }
    return null;
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  // Used in warehouse display
  String _getWarehouseName(String? id) {
    if (id == null || id.isEmpty) return '';
    final w = _warehouses
        .where((w) => (w['id']?.toString() ?? w['_id']?.toString()) == id)
        .firstOrNull;
    return w != null ? (w['name'] ?? '').toString() : '';
  }

  // ── Stats ──

  Map<String, dynamic> get _stats {
    final delivered = _deliveries.where((d) {
      final status = (d['status'] ?? '').toString().toLowerCase();
      return status == 'delivered' || status == 'paid' || status == 'completed';
    }).toList();

    double collectedAmount = 0;
    double pendingAmount = 0;

    for (final d in _deliveries) {
      final amount = _parseDouble(d['amount_paid'] ?? d['amountPaid'] ?? d['agreed_amount'] ?? 0);
      final status = (d['status'] ?? '').toString().toLowerCase();
      if (status == 'paid') {
        collectedAmount += amount;
      } else if (status == 'delivered' || status == 'pending') {
        pendingAmount += amount;
      }
    }

    return {
      'total': _deliveries.length,
      'delivered': delivered.length,
      'pending': _pendingShipments.length,
      'collected': collectedAmount,
      'pendingAmount': pendingAmount,
    };
  }

  // ── Status helpers ──

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'delivered':
      case 'completed':
        return AppColors.success;
      case 'paid':
        return AppColors.blue600;
      case 'pending':
        return const Color(0xFFD97706);
      case 'in_transit':
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'delivered':
      case 'completed':
        return 'تم التسليم';
      case 'paid':
        return 'مدفوع';
      case 'pending':
        return 'قيد الانتظار';
      case 'in_transit':
      case 'in_progress':
        return 'في الطريق';
      case 'cancelled':
        return 'ملغى';
      default:
        return status ?? '-';
    }
  }

  String _paymentMethodLabel(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':
        return 'نقداً';
      case 'transfer':
        return 'تحويل بنكي';
      case 'check':
        return 'شيك';
      case 'debt':
        return 'آجل';
      default:
        return method ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('التوصيلات',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.local_shipping_outlined, size: 20),
              text: 'التوزيع والتسليم (${_pendingShipments.length})',
            ),
            Tab(
              icon: const Icon(Icons.history, size: 20),
              text: 'سجل التسليمات (${_deliveryHistory.length})',
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.deliveriesPage),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDeliveryTab(stats),
                    _buildHistoryTab(stats),
                  ],
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

  // ══════════════════════════════════════════
  // TAB 1: Delivery (Pending Shipments)
  // ══════════════════════════════════════════

  Widget _buildDeliveryTab(Map<String, dynamic> stats) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Stats cards
          SliverToBoxAdapter(child: _buildDeliveryStats(stats)),
          // Warehouse selector
          SliverToBoxAdapter(child: _buildWarehouseSelector()),
          // Search
          SliverToBoxAdapter(child: _buildSearchBar(_searchController, 'بحث برقم الإيصال/التتبع/اسم العميل...', true)),
          // Count
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white,
              child: Text(
                '${_pendingShipments.length} شحنة جاهزة للتسليم',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          // Shipments list
          _pendingShipments.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _selectedWarehouseId != null
                              ? 'لا توجد شحنات في هذا المستودع'
                              : 'لا توجد شحنات جاهزة للتسليم',
                          style: const TextStyle(color: AppColors.textGray),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildShipmentCard(_pendingShipments[i]),
                    childCount: _pendingShipments.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildDeliveryStats(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _statCard(
              'إجمالي التسليمات',
              '${stats['total']}',
              Icons.local_shipping_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF3E8FF),
            ),
            _statCard(
              'شحنات جاهزة',
              '${stats['pending']}',
              Icons.inventory_2_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _statCard(
              'تم تسليمها',
              '${stats['delivered']}',
              Icons.check_circle_outline,
              AppColors.success,
              const Color(0xFFF0FDF4),
            ),
            _statCard(
              'المبلغ المحصل',
              '\$${(stats['collected'] as double).toStringAsFixed(0)}',
              Icons.attach_money,
              AppColors.blue600,
              const Color(0xFFEFF6FF),
            ),
            _statCard(
              'المبلغ المعلق',
              '\$${(stats['pendingAmount'] as double).toStringAsFixed(0)}',
              Icons.hourglass_empty,
              AppColors.error,
              const Color(0xFFFEF2F2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      width: 140,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textGray, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseSelector() {
    final deliveryWarehouses = _warehouses.where((w) {
      final type = (w['type'] ?? w['warehouse_type'] ?? '').toString().toLowerCase();
      return type.contains('delivery') || type.contains('توصيل') || type.isEmpty;
    }).toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: DropdownButtonFormField<String>(
        value: _selectedWarehouseId,
        hint: const Text('جميع المستودعات', style: TextStyle(fontSize: 13)),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'المستودع',
          prefixIcon: const Icon(Icons.warehouse_outlined, size: 20),
          filled: true,
          fillColor: AppColors.bgLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
        items: [
          const DropdownMenuItem<String>(
              value: '', child: Text('جميع المستودعات', style: TextStyle(fontSize: 13))),
          ...deliveryWarehouses.map((w) {
            final id = w['id']?.toString() ?? w['_id']?.toString() ?? '';
            final name = w['name'] ?? 'مستودع';
            return DropdownMenuItem<String>(
                value: id,
                child: Text(name.toString(), style: const TextStyle(fontSize: 13)));
          }),
        ],
        onChanged: (v) {
          setState(() {
            _selectedWarehouseId = (v != null && v.isNotEmpty) ? v : null;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildSearchBar(TextEditingController controller, String hint, bool isDeliveryTab) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() => _applyFilters()),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 22),
          filled: true,
          fillColor: AppColors.bgLight,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildShipmentCard(Map<String, dynamic> shipment) {
    final receiptNumber = (shipment['receipt_number'] ?? shipment['receiptNumber'] ?? '').toString();
    final trackingNumber = (shipment['tracking_number'] ?? shipment['trackingNumber'] ?? '').toString();
    final customerName = _getShipmentCustomerName(shipment);
    final customerCode = _getShipmentCustomerCode(shipment);
    final customerPhone = _getShipmentCustomerPhone(shipment);
    final goodsType = (shipment['goods_type'] ?? shipment['goodsType'] ?? '').toString();
    final warehouseId = (shipment['destination_warehouse'] ?? shipment['warehouse_id'] ?? '').toString();
    final warehouseName = _getWarehouseName(warehouseId);
    final agreedAmount = _parseDouble(shipment['agreed_amount'] ?? shipment['agreedAmount'] ?? shipment['total_cost'] ?? 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDeliverDialog(shipment),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2,
                        color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customerName.isNotEmpty ? customerName : 'شحنة',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (customerCode.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  customerCode,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                        if (customerPhone.isNotEmpty)
                          Text(customerPhone,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Receipt / Tracking / Goods
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (receiptNumber.isNotEmpty)
                    _infoChip(Icons.receipt_long, 'إيصال: $receiptNumber'),
                  if (trackingNumber.isNotEmpty)
                    _infoChip(Icons.qr_code, 'تتبع: $trackingNumber'),
                  if (goodsType.isNotEmpty)
                    _infoChip(Icons.category_outlined, goodsType),
                  if (warehouseName.isNotEmpty)
                    _infoChip(Icons.warehouse_outlined, warehouseName),
                ],
              ),
              const SizedBox(height: 8),
              // Amount + Deliver button
              Row(
                children: [
                  if (agreedAmount > 0)
                    Text(
                      '\$${agreedAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showDeliverDialog(shipment),
                    icon: const Icon(Icons.local_shipping, size: 16),
                    label: const Text('تسليم',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(text,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  // ══════════════════════════════════════════
  // TAB 2: Delivery History
  // ══════════════════════════════════════════

  Widget _buildHistoryTab(Map<String, dynamic> stats) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Search
          SliverToBoxAdapter(
            child: _buildSearchBar(_historySearchController, 'بحث في سجل التسليمات...', false),
          ),
          // Sort options
          SliverToBoxAdapter(child: _buildSortBar()),
          // Count
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.white,
              child: Text(
                '${_deliveryHistory.length} تسليم',
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 1)),
          // Deliveries list
          _deliveryHistory.isEmpty
              ? SliverFillRemaining(
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delivery_dining_outlined,
                            size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('لا توجد تسليمات',
                            style: TextStyle(color: AppColors.textGray)),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildDeliveryCard(_deliveryHistory[i]),
                    childCount: _deliveryHistory.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('ترتيب: ',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            _sortChip('التاريخ', 'delivery_date'),
            _sortChip('المستلم', 'recipient_name'),
            _sortChip('الحالة', 'status'),
            _sortChip('المبلغ', 'amount_paid'),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(String label, String field) {
    final isActive = _sortField == field;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: isActive ? Colors.white : AppColors.textGray)),
            if (isActive)
              Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12, color: Colors.white),
          ],
        ),
        selected: isActive,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.bgLight,
        onSelected: (_) {
          setState(() {
            if (_sortField == field) {
              _sortAsc = !_sortAsc;
            } else {
              _sortField = field;
              _sortAsc = true;
            }
            _applyFilters();
          });
        },
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final recipientName = (delivery['recipient_name'] ??
            delivery['recipientName'] ??
            delivery['customer_name'] ??
            delivery['customerName'] ??
            '')
        .toString();
    final recipientPhone = (delivery['recipient_phone'] ??
            delivery['recipientPhone'] ??
            '')
        .toString();
    final date = (delivery['delivery_date'] ??
            delivery['deliveryDate'] ??
            delivery['date'] ??
            delivery['created_at'] ??
            '')
        .toString();
    final status = (delivery['status'] ?? '').toString();
    final notes = (delivery['notes'] ?? '').toString();
    final amountPaid = _parseDouble(
        delivery['amount_paid'] ?? delivery['amountPaid'] ?? 0);
    final paymentMethod =
        (delivery['payment_method'] ?? delivery['paymentMethod'] ?? '')
            .toString();
    final address = (delivery['delivery_address'] ??
            delivery['deliveryAddress'] ??
            delivery['address'] ??
            '')
        .toString();

    // Get linked shipment info
    final shipment = _getShipmentForDelivery(delivery);
    final receiptNumber = shipment != null
        ? (shipment['receipt_number'] ?? shipment['receiptNumber'] ?? '').toString()
        : '';
    final trackingNumber = shipment != null
        ? (shipment['tracking_number'] ?? shipment['trackingNumber'] ?? '').toString()
        : '';

    final cancelled = status.toLowerCase() == 'cancelled';

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
        onTap: () => _showDeliveryDetails(delivery),
        onLongPress: () => _showDeliveryActions(delivery),
        child: Opacity(
          opacity: cancelled ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.delivery_dining,
                          color: _statusColor(status), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipientName.isNotEmpty ? recipientName : 'تسليم',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              decoration:
                                  cancelled ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (recipientPhone.isNotEmpty)
                            Text(recipientPhone,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(status)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Shipment info
                if (receiptNumber.isNotEmpty || trackingNumber.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (receiptNumber.isNotEmpty)
                        _infoChip(Icons.receipt_long, 'إيصال: $receiptNumber'),
                      if (trackingNumber.isNotEmpty)
                        _infoChip(Icons.qr_code, 'تتبع: $trackingNumber'),
                    ],
                  ),
                if (address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(address,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                // Bottom row: date, amount, payment method
                Row(
                  children: [
                    if (date.isNotEmpty)
                      Text(date.split('T').first,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    const Spacer(),
                    if (amountPaid > 0)
                      Text(
                        '\$${amountPaid.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                      ),
                    if (paymentMethod.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.blue600.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _paymentMethodLabel(paymentMethod),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blue600),
                        ),
                      ),
                    ],
                  ],
                ),
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(notes,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // Delivery Details Bottom Sheet
  // ══════════════════════════════════════════

  void _showDeliveryDetails(Map<String, dynamic> d) {
    final shipment = _getShipmentForDelivery(d);
    final recipientName = (d['recipient_name'] ?? d['recipientName'] ?? d['customer_name'] ?? d['customerName'] ?? '-').toString();
    final recipientPhone = (d['recipient_phone'] ?? d['recipientPhone'] ?? '-').toString();
    final address = (d['delivery_address'] ?? d['deliveryAddress'] ?? d['address'] ?? '-').toString();
    final date = (d['delivery_date'] ?? d['deliveryDate'] ?? d['date'] ?? '-').toString();
    final status = (d['status'] ?? '-').toString();
    final notes = (d['notes'] ?? '-').toString();
    final amountPaid = _parseDouble(d['amount_paid'] ?? d['amountPaid'] ?? 0);
    final paymentMethod = (d['payment_method'] ?? d['paymentMethod'] ?? '-').toString();
    final cancelled = status.toLowerCase() == 'cancelled';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
              Center(
                child: Text('تفاصيل التسليم',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: cancelled ? AppColors.error : AppColors.textDark)),
              ),
              if (cancelled)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('تسليم ملغى',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                  ),
                ),
              const SizedBox(height: 16),
              // Shipment info
              if (shipment != null)
                _detailSection('معلومات الشحنة', Icons.inventory_2, [
                  _detailRow('رقم الإيصال', (shipment['receipt_number'] ?? shipment['receiptNumber'] ?? '-').toString()),
                  _detailRow('رقم التتبع', (shipment['tracking_number'] ?? shipment['trackingNumber'] ?? '-').toString()),
                  _detailRow('نوع البضاعة', (shipment['goods_type'] ?? shipment['goodsType'] ?? '-').toString()),
                  _detailRow('عدد الطرود', (shipment['package_count'] ?? shipment['packageCount'] ?? '-').toString()),
                  _detailRow('الوزن', (shipment['weight'] ?? '-').toString()),
                  _detailRow('الحجم', (shipment['volume'] ?? '-').toString()),
                ]),
              if (shipment != null) const SizedBox(height: 12),
              // Delivery info
              _detailSection('معلومات التسليم', Icons.delivery_dining, [
                _detailRow('المستلم', recipientName),
                _detailRow('هاتف المستلم', recipientPhone),
                _detailRow('العنوان', address),
                _detailRow('تاريخ التسليم', date.split('T').first),
                _detailRow('الحالة', _statusLabel(status)),
              ]),
              const SizedBox(height: 12),
              // Payment info
              if (amountPaid > 0)
                _detailSection('معلومات الدفع', Icons.payment, [
                  _detailRow('المبلغ المدفوع', '\$${amountPaid.toStringAsFixed(2)}'),
                  _detailRow('طريقة الدفع', _paymentMethodLabel(paymentMethod)),
                ]),
              if (notes != '-' && notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes, size: 16, color: Color(0xFFD97706)),
                          SizedBox(width: 6),
                          Text('ملاحظات',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(notes, style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Actions
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (!cancelled)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditDialog(d);
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
                      _confirmCancelDelivery(d);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('إلغاء التسليم'),
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
                    final id = d['id']?.toString() ?? d['_id']?.toString() ?? '';
                    _confirmDelete(id, recipientName);
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

  Widget _detailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
          ]),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value == '-' || value == 'null' || value.trim().isEmpty) {
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

  // ── Delivery Actions ──

  void _showDeliveryActions(Map<String, dynamic> delivery) {
    final id = delivery['id']?.toString() ?? delivery['_id']?.toString();
    if (id == null) return;
    final recipientName = (delivery['recipient_name'] ?? delivery['recipientName'] ?? 'تسليم').toString();
    final cancelled = (delivery['status'] ?? '').toString().toLowerCase() == 'cancelled';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
                  Navigator.pop(ctx);
                  _showDeliveryDetails(delivery);
                },
              ),
              if (!cancelled)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.blue600),
                  title: const Text('تعديل'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(delivery);
                  },
                ),
              if (!cancelled)
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: Color(0xFFD97706)),
                  title: const Text('إلغاء التسليم', style: TextStyle(color: Color(0xFFD97706))),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmCancelDelivery(delivery);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('حذف', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(id, recipientName);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // Deliver Shipment Dialog
  // ══════════════════════════════════════════

  void _showDeliverDialog(Map<String, dynamic> shipment) {
    final customerName = _getShipmentCustomerName(shipment);
    final customerPhone = _getShipmentCustomerPhone(shipment);
    final agreedAmount = _parseDouble(shipment['agreed_amount'] ?? shipment['agreedAmount'] ?? shipment['total_cost'] ?? 0);

    final recipientNameC = TextEditingController(text: customerName);
    final recipientPhoneC = TextEditingController(text: customerPhone);
    final addressC = TextEditingController();
    final amountPaidC = TextEditingController(text: agreedAmount > 0 ? agreedAmount.toStringAsFixed(0) : '');
    final notesC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate = DateTime.now();
    String paymentType = 'cash'; // cash or debt
    String paymentMethod = 'cash'; // cash, transfer, check

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تسليم شحنة',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shipment info summary
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                if (agreedAmount > 0)
                                  Text('المبلغ المتفق: \$${agreedAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textGray)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: recipientNameC,
                      decoration: _fieldDecor('اسم المستلم', Icons.person_outline),
                      validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: recipientPhoneC,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecor('هاتف المستلم', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressC,
                      decoration: _fieldDecor('عنوان التسليم', Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 12),
                    // Date picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context)
                                      .colorScheme
                                      .copyWith(primary: AppColors.primary)),
                              child: child!),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: _fieldDecor('تاريخ التسليم', Icons.calendar_today_outlined),
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                              : '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Payment type
                    const Text('نوع الدفع',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _paymentTypeButton(
                            'نقداً',
                            Icons.attach_money,
                            paymentType == 'cash',
                            () => setDialogState(() => paymentType = 'cash'),
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _paymentTypeButton(
                            'آجل (دين)',
                            Icons.credit_card,
                            paymentType == 'debt',
                            () => setDialogState(() => paymentType = 'debt'),
                            const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (paymentType == 'cash') ...[
                      TextFormField(
                        controller: amountPaidC,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecor('المبلغ المدفوع', Icons.attach_money),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: _fieldDecor('وسيلة الدفع', Icons.payment),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('نقداً')),
                          DropdownMenuItem(value: 'transfer', child: Text('تحويل بنكي')),
                          DropdownMenuItem(value: 'check', child: Text('شيك')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => paymentMethod = v);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: notesC,
                      maxLines: 2,
                      decoration: _fieldDecor('ملاحظات', Icons.notes_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  final shipmentId = shipment['id']?.toString() ?? shipment['_id']?.toString();
                  await _ds.createDelivery(_token, {
                    if (shipmentId != null) 'shipment_id': int.tryParse(shipmentId) ?? shipmentId,
                    'recipient_name': recipientNameC.text.trim(),
                    if (recipientPhoneC.text.trim().isNotEmpty)
                      'recipient_phone': recipientPhoneC.text.trim(),
                    if (addressC.text.trim().isNotEmpty)
                      'delivery_address': addressC.text.trim(),
                    if (selectedDate != null)
                      'delivery_date':
                          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                    'status': paymentType == 'cash' ? 'paid' : 'delivered',
                    if (paymentType == 'cash')
                      'amount_paid': double.tryParse(amountPaidC.text.trim()) ?? 0,
                    if (paymentType == 'cash') 'payment_method': paymentMethod,
                    if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
                  });

                  // Update shipment status to delivered
                  if (shipmentId != null) {
                    try {
                      await _ds.updateShipment(_token, shipmentId, {'status': 'delivered'});
                    } catch (_) {}
                  }

                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم تسليم الشحنة بنجاح'),
                        backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e is ApiException ? e.message : 'فشل تسليم الشحنة'),
                        backgroundColor: AppColors.error));
                  }
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('تأكيد التسليم',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentTypeButton(
      String label, IconData icon, bool isSelected, VoidCallback onTap, Color activeColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : AppColors.bgLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : AppColors.textMuted, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? activeColor : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // Add Dialog (standalone - from history tab)
  // ══════════════════════════════════════════

  void _showAddDialog() {
    final recipientNameC = TextEditingController();
    final recipientPhoneC = TextEditingController();
    final addressC = TextEditingController();
    final amountPaidC = TextEditingController();
    final notesC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedStatus = 'pending';
    String paymentMethod = 'cash';
    DateTime? selectedDate;
    String? selectedShipmentId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('إضافة تسليم',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shipment selector
                    DropdownButtonFormField<String>(
                      value: selectedShipmentId,
                      hint: const Text('اختر شحنة (اختياري)', style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      decoration: _fieldDecor('الشحنة', Icons.inventory_2_outlined),
                      items: _shipments.map((s) {
                        final id = s['id']?.toString() ?? s['_id']?.toString() ?? '';
                        final receipt = s['receipt_number'] ?? s['receiptNumber'] ?? '';
                        final name = _getShipmentCustomerName(s);
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text('$receipt - $name', style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          selectedShipmentId = v;
                          if (v != null) {
                            final s = _shipments.where((s) =>
                                (s['id']?.toString() ?? s['_id']?.toString()) == v).firstOrNull;
                            if (s != null) {
                              recipientNameC.text = _getShipmentCustomerName(s);
                              recipientPhoneC.text = _getShipmentCustomerPhone(s);
                              final amount = _parseDouble(s['agreed_amount'] ?? s['agreedAmount'] ?? s['total_cost'] ?? 0);
                              if (amount > 0) amountPaidC.text = amount.toStringAsFixed(0);
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: recipientNameC,
                      decoration: _fieldDecor('اسم المستلم', Icons.person_outline),
                      validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: recipientPhoneC,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecor('هاتف المستلم', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressC,
                      decoration: _fieldDecor('عنوان التسليم', Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context)
                                      .colorScheme
                                      .copyWith(primary: AppColors.primary)),
                              child: child!),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: _fieldDecor('تاريخ التسليم', Icons.calendar_today_outlined),
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                              : '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountPaidC,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecor('المبلغ المدفوع', Icons.attach_money),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: _fieldDecor('وسيلة الدفع', Icons.payment),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقداً')),
                        DropdownMenuItem(value: 'transfer', child: Text('تحويل بنكي')),
                        DropdownMenuItem(value: 'check', child: Text('شيك')),
                        DropdownMenuItem(value: 'debt', child: Text('آجل')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => paymentMethod = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: _fieldDecor('الحالة', Icons.flag_outlined),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
                        DropdownMenuItem(value: 'in_transit', child: Text('في الطريق')),
                        DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
                        DropdownMenuItem(value: 'paid', child: Text('مدفوع')),
                        DropdownMenuItem(value: 'cancelled', child: Text('ملغى')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedStatus = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesC,
                      maxLines: 2,
                      decoration: _fieldDecor('ملاحظات', Icons.notes_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await _ds.createDelivery(_token, {
                    if (selectedShipmentId != null && selectedShipmentId!.isNotEmpty)
                      'shipment_id': int.tryParse(selectedShipmentId!) ?? selectedShipmentId,
                    'recipient_name': recipientNameC.text.trim(),
                    if (recipientPhoneC.text.trim().isNotEmpty)
                      'recipient_phone': recipientPhoneC.text.trim(),
                    if (addressC.text.trim().isNotEmpty)
                      'delivery_address': addressC.text.trim(),
                    if (selectedDate != null)
                      'delivery_date':
                          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                    'status': selectedStatus,
                    if (amountPaidC.text.trim().isNotEmpty)
                      'amount_paid': double.tryParse(amountPaidC.text.trim()) ?? 0,
                    'payment_method': paymentMethod,
                    if (notesC.text.trim().isNotEmpty) 'notes': notesC.text.trim(),
                  });
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم إضافة التسليم بنجاح'),
                        backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            e is ApiException ? e.message : 'فشل إضافة التسليم'),
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

  // ── Edit Dialog ──

  void _showEditDialog(Map<String, dynamic> delivery) {
    final id = delivery['id']?.toString() ?? delivery['_id']?.toString();
    if (id == null) return;

    final recipientNameC = TextEditingController(
        text: delivery['recipient_name'] ?? delivery['recipientName'] ?? delivery['customer_name'] ?? delivery['customerName'] ?? '');
    final recipientPhoneC = TextEditingController(
        text: delivery['recipient_phone'] ?? delivery['recipientPhone'] ?? '');
    final addressC = TextEditingController(
        text: delivery['delivery_address'] ?? delivery['deliveryAddress'] ?? delivery['address'] ?? '');
    final amountPaidC = TextEditingController(
        text: _parseDouble(delivery['amount_paid'] ?? delivery['amountPaid'] ?? 0) > 0
            ? _parseDouble(delivery['amount_paid'] ?? delivery['amountPaid'] ?? 0).toStringAsFixed(0)
            : '');
    final notesC = TextEditingController(text: delivery['notes'] ?? '');
    final formKey = GlobalKey<FormState>();

    String currentStatus = (delivery['status'] ?? 'pending').toString().toLowerCase();
    if (!['pending', 'in_transit', 'delivered', 'paid', 'cancelled'].contains(currentStatus)) {
      if (currentStatus == 'completed') {
        currentStatus = 'delivered';
      } else if (currentStatus == 'in_progress') {
        currentStatus = 'in_transit';
      } else {
        currentStatus = 'pending';
      }
    }
    String selectedStatus = currentStatus;
    String paymentMethod = (delivery['payment_method'] ?? delivery['paymentMethod'] ?? 'cash').toString().toLowerCase();
    if (!['cash', 'transfer', 'check', 'debt'].contains(paymentMethod)) paymentMethod = 'cash';

    DateTime? selectedDate;
    final rawDate = (delivery['delivery_date'] ?? delivery['deliveryDate'] ?? delivery['date'] ?? '').toString();
    if (rawDate.isNotEmpty && rawDate != 'null') {
      try {
        selectedDate = DateTime.parse(rawDate.split('T').first);
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تعديل التسليم',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: recipientNameC,
                      decoration: _fieldDecor('اسم المستلم', Icons.person_outline),
                      validator: (v) => v!.trim().isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: recipientPhoneC,
                      keyboardType: TextInputType.phone,
                      decoration: _fieldDecor('هاتف المستلم', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressC,
                      decoration: _fieldDecor('عنوان التسليم', Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context)
                                      .colorScheme
                                      .copyWith(primary: AppColors.primary)),
                              child: child!),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: _fieldDecor('تاريخ التسليم', Icons.calendar_today_outlined),
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                              : '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountPaidC,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecor('المبلغ المدفوع', Icons.attach_money),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      decoration: _fieldDecor('وسيلة الدفع', Icons.payment),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('نقداً')),
                        DropdownMenuItem(value: 'transfer', child: Text('تحويل بنكي')),
                        DropdownMenuItem(value: 'check', child: Text('شيك')),
                        DropdownMenuItem(value: 'debt', child: Text('آجل')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => paymentMethod = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: _fieldDecor('الحالة', Icons.flag_outlined),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
                        DropdownMenuItem(value: 'in_transit', child: Text('في الطريق')),
                        DropdownMenuItem(value: 'delivered', child: Text('تم التسليم')),
                        DropdownMenuItem(value: 'paid', child: Text('مدفوع')),
                        DropdownMenuItem(value: 'cancelled', child: Text('ملغى')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedStatus = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesC,
                      maxLines: 2,
                      decoration: _fieldDecor('ملاحظات', Icons.notes_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await _ds.updateDelivery(_token, id, {
                    'recipient_name': recipientNameC.text.trim(),
                    'recipient_phone': recipientPhoneC.text.trim(),
                    'delivery_address': addressC.text.trim(),
                    if (selectedDate != null)
                      'delivery_date':
                          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                    'status': selectedStatus,
                    'amount_paid': double.tryParse(amountPaidC.text.trim()) ?? 0,
                    'payment_method': paymentMethod,
                    'notes': notesC.text.trim(),
                  });
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم تعديل التسليم بنجاح'),
                        backgroundColor: AppColors.success));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            e is ApiException ? e.message : 'فشل تعديل التسليم'),
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

  // ── Cancel Delivery ──

  void _confirmCancelDelivery(Map<String, dynamic> delivery) {
    final id = delivery['id']?.toString() ?? delivery['_id']?.toString();
    if (id == null || id.isEmpty) return;
    final name = (delivery['recipient_name'] ?? delivery['recipientName'] ?? 'التسليم').toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأكيد إلغاء التسليم',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل تريد إلغاء تسليم "$name"؟', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سيتم:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('• تعليم التسليم كملغى', style: TextStyle(fontSize: 11)),
                  Text('• إعادة الشحنة للمستودع', style: TextStyle(fontSize: 11)),
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
                await _ds.updateDelivery(_token, id, {'status': 'cancelled'});

                // Return shipment to warehouse
                final shipmentId = delivery['shipment_id']?.toString();
                if (shipmentId != null && shipmentId.isNotEmpty) {
                  try {
                    await _ds.updateShipment(_token, shipmentId, {'status': 'in_warehouse'});
                  } catch (_) {}
                }

                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم إلغاء التسليم'),
                      backgroundColor: Color(0xFFD97706)));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          e is ApiException ? e.message : 'فشل إلغاء التسليم'),
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

  // ── Delete Confirmation ──

  void _confirmDelete(String id, String name) {
    if (id.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف التسليم',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('هل تريد حذف "$name" نهائياً؟',
            textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _ds.deleteDelivery(_token, id);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم حذف التسليم'),
                      backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          e is ApiException ? e.message : 'فشل حذف التسليم'),
                      backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('حذف',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Helper ──

  InputDecoration _fieldDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppColors.bgLight,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
    );
  }
}
