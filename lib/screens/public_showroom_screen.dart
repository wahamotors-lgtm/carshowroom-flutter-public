import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';

class PublicShowroomScreen extends StatefulWidget {
  const PublicShowroomScreen({super.key});
  @override
  State<PublicShowroomScreen> createState() => _PublicShowroomScreenState();
}

class _PublicShowroomScreenState extends State<PublicShowroomScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedMake;
  List<String> _makes = [];
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final allCars = await _ds.getCars('');
      if (!mounted) return;

      // Filter for showroom/in_stock cars only
      final showroomCars = allCars.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        return status == 'in_showroom' || status == 'in_stock';
      }).toList();

      // Extract unique makes
      final makesSet = <String>{};
      for (final car in showroomCars) {
        final make = (car['make'] ?? car['brand'] ?? '').toString().trim();
        if (make.isNotEmpty) makesSet.add(make);
      }

      setState(() {
        _cars = showroomCars;
        _makes = makesSet.toList()..sort();
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل بيانات المعرض'; _isLoading = false; });
    }
  }

  void _applyFilter() {
    if (_selectedMake == null) {
      _filtered = List.from(_cars);
    } else {
      _filtered = _cars.where((c) {
        final make = (c['make'] ?? c['brand'] ?? '').toString().trim();
        return make == _selectedMake;
      }).toList();
    }
  }

  String _fmtPrice(dynamic price) {
    if (price == null) return '';
    final p = double.tryParse(price.toString()) ?? 0;
    if (p == 0) return '';
    return '\$${NumberFormat('#,###', 'en_US').format(p)}';
  }

  String? _getFirstImage(Map<String, dynamic> car) {
    final images = car['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String && first.isNotEmpty) return first;
      if (first is Map && first['url'] != null) return first['url'].toString();
    }
    final image = car['image'] ?? car['imageUrl'] ?? car['image_url'];
    if (image != null && image.toString().isNotEmpty) return image.toString();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('المعرض', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, size: 22),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
                  value: _selectedMake,
                  isExpanded: true,
                  hint: const Text('جميع الماركات', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('جميع الماركات')),
                    ..._makes.map((m) => DropdownMenuItem<String?>(value: m, child: Text(m))),
                  ],
                  onChanged: (v) => setState(() { _selectedMake = v; _applyFilter(); }),
                )),
              )),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text('${_filtered.length} سيارة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ]),
          ),
          const Divider(height: 1),

          // Cars display
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadData, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
                      ]))
                    : _filtered.isEmpty
                        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.storefront_outlined, size: 48, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('لا توجد سيارات في المعرض حالياً', style: TextStyle(color: AppColors.textGray)),
                          ]))
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadData,
                            child: _isGridView ? _buildGridView() : _buildListView(),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.72,
      ),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _buildGridCard(_filtered[i]),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _buildListCard(_filtered[i]),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final sellingPrice = car['selling_price'] ?? car['sellingPrice'] ?? car['price'];
    final imageUrl = _getFirstImage(car);
    final color = car['color'] ?? '';

    return GestureDetector(
      onTap: () => _showCarDetails(car),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Container(
              height: 120, width: double.infinity, color: AppColors.bgLight,
              child: imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _carPlaceholder())
                  : _carPlaceholder(),
            ),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$make $model', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  if (year.toString().isNotEmpty) ...[
                    const Icon(Icons.calendar_today, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text('$year', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                  if (color.toString().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.palette_outlined, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(child: Text(color.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ]),
              ]),
              if (_fmtPrice(sellingPrice).isNotEmpty)
                Text(_fmtPrice(sellingPrice), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildListCard(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final sellingPrice = car['selling_price'] ?? car['sellingPrice'] ?? car['price'];
    final imageUrl = _getFirstImage(car);
    final color = car['color'] ?? '';
    final fuelType = car['fuel_type'] ?? car['fuelType'] ?? '';

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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 80, height: 60, color: AppColors.bgLight,
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _carPlaceholder())
                    : _carPlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$make $model', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (year.toString().isNotEmpty) ...[
                  Text('$year', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                ],
                if (color.toString().isNotEmpty) ...[
                  Text(color.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                ],
                if (fuelType.toString().isNotEmpty)
                  Text(fuelType.toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ]),
            ])),
            if (_fmtPrice(sellingPrice).isNotEmpty)
              Text(_fmtPrice(sellingPrice), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ]),
        ),
      ),
    );
  }

  Widget _carPlaceholder() {
    return Center(child: Icon(Icons.directions_car, size: 32, color: Colors.grey.shade300));
  }

  void _showCarDetails(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final sellingPrice = car['selling_price'] ?? car['sellingPrice'] ?? car['price'];
    final imageUrl = _getFirstImage(car);
    final color = car['color'] ?? '';
    final fuelType = car['fuel_type'] ?? car['fuelType'] ?? '';
    final mileage = car['mileage'] ?? '';
    final vin = car['vin'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('$make $model', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 12),
            ])),
            const Divider(height: 1),
            Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
              // Image
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 200, color: AppColors.bgLight, child: _carPlaceholder())),
                ),
                const SizedBox(height: 16),
              ],
              // Details
              if (year.toString().isNotEmpty) _detailRow('السنة', '$year'),
              if (color.toString().isNotEmpty) _detailRow('اللون', color.toString()),
              if (fuelType.toString().isNotEmpty) _detailRow('نوع الوقود', fuelType.toString()),
              if (mileage.toString().isNotEmpty && mileage.toString() != '0') _detailRow('العداد', '$mileage كم'),
              if (vin.toString().isNotEmpty) _detailRow('رقم الشاصي', vin.toString()),
              if (_fmtPrice(sellingPrice).isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('السعر: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    Text(_fmtPrice(sellingPrice), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ]),
                ),
              ],
            ])),
          ])),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
