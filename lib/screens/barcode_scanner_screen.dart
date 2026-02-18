import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final DataService _ds;
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _scanned = false;
  bool _isLoadingCars = true;
  List<Map<String, dynamic>> _cars = [];
  String? _error;

  static const Map<String, String> _statusLabels = {
    'in_korea_warehouse': 'في مستودع كوريا',
    'in_container': 'في الحاوية',
    'shipped': 'في الطريق',
    'arrived': 'وصلت',
    'customs': 'في الجمارك',
    'in_showroom': 'في المعرض',
    'sold': 'مباعة',
    'purchased_local': 'شراء محلي',
  };

  static const Map<String, Color> _statusColors = {
    'in_korea_warehouse': Color(0xFF2563EB),
    'in_container': Color(0xFF7C3AED),
    'shipped': Color(0xFFD97706),
    'arrived': Color(0xFF0891B2),
    'customs': Color(0xFFDB2777),
    'in_showroom': Color(0xFF22C55E),
    'sold': Color(0xFFEF4444),
    'purchased_local': Color(0xFF64748B),
  };

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
    _loadCars();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadCars() async {
    setState(() { _isLoadingCars = true; _error = null; });
    try {
      final cars = await _ds.getCars(_token);
      if (!mounted) return;
      setState(() { _cars = cars; _isLoadingCars = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل بيانات السيارات'; _isLoadingCars = false; });
    }
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scanned = false;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    });
  }

  void _stopScanning() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() { _isScanning = false; _scanned = false; });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final scannedValue = barcodes.first.rawValue;
    if (scannedValue == null || scannedValue.isEmpty) return;

    setState(() { _scanned = true; });

    // Clean up VIN (remove spaces, uppercase)
    final vin = scannedValue.trim().toUpperCase();

    // Search for VIN in cars list
    final foundCar = _cars.firstWhere(
      (c) => (c['vin'] ?? '').toString().toUpperCase() == vin,
      orElse: () => <String, dynamic>{},
    );

    if (foundCar.isNotEmpty) {
      _showFoundCarSheet(foundCar, vin);
    } else {
      _showNotFoundDialog(vin);
    }
  }

  void _showFoundCarSheet(Map<String, dynamic> car, String vin) {
    _stopScanning();

    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    final color = car['color'] ?? '';
    final status = (car['status'] ?? '').toString();
    final sellingPrice = car['selling_price'] ?? car['sellingPrice'] ?? car['price'];
    final purchasePrice = car['purchase_price'] ?? car['purchasePrice'];
    final stockNumber = car['stock_number'] ?? '';
    final fuelType = car['fuel_type'] ?? car['fuelType'] ?? '';
    final mileage = car['mileage'] ?? '';

    final statusLabel = _statusLabels[status] ?? status;
    final statusColor = _statusColors[status] ?? AppColors.textMuted;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SafeArea(child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 32),
              ),
              const SizedBox(height: 12),
              const Text('تم العثور على السيارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('$make $model ${year != '' ? '($year)' : ''}', style: const TextStyle(fontSize: 14, color: AppColors.textGray)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
              ),
              const SizedBox(height: 12),
            ])),
            const Divider(height: 1),
            Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.fromLTRB(20, 12, 20, 20), children: [
              _detailRow('رقم الشاصي (VIN)', vin),
              if (stockNumber.toString().isNotEmpty) _detailRow('رقم المخزون', stockNumber.toString()),
              if (make.toString().isNotEmpty) _detailRow('البراند', make.toString()),
              if (model.toString().isNotEmpty) _detailRow('الموديل', model.toString()),
              if (year.toString().isNotEmpty) _detailRow('السنة', year.toString()),
              if (color.toString().isNotEmpty) _detailRow('اللون', color.toString()),
              if (fuelType.toString().isNotEmpty) _detailRow('نوع الوقود', fuelType.toString()),
              if (mileage.toString().isNotEmpty && mileage.toString() != '0') _detailRow('العداد', '$mileage كم'),
              if (purchasePrice != null && purchasePrice.toString().isNotEmpty && purchasePrice.toString() != '0')
                _detailRow('سعر الشراء', '\$$purchasePrice'),
              if (sellingPrice != null && sellingPrice.toString().isNotEmpty && sellingPrice.toString() != '0')
                _detailRow('سعر البيع', '\$$sellingPrice'),
              const SizedBox(height: 16),
              Center(child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _startScanning(); },
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('مسح رمز آخر', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ])),
          ])),
        ),
      ),
    );
  }

  void _showNotFoundDialog(String vin) {
    _stopScanning();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.search_off, color: Color(0xFFD97706), size: 32),
        ),
        const SizedBox(height: 12),
        const Text('لم يتم العثور', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('لم يتم العثور على سيارة برقم الشاصي:', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: AppColors.bgLight, borderRadius: BorderRadius.circular(10)),
          child: Text(vin, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 1.2)),
        ),
        const SizedBox(height: 12),
        const Text('هل تريد إضافة سيارة جديدة؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textGray)),
      ]),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () { Navigator.pop(ctx); setState(() { _scanned = false; }); },
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(ctx);
            _showAddCarDialog(vin);
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة سيارة', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    ));
  }

  void _showAddCarDialog(String vin) {
    final vinC = TextEditingController(text: vin);
    final makeC = TextEditingController();
    final modelC = TextEditingController();
    final yearC = TextEditingController();
    final colorC = TextEditingController();
    final purchasePriceC = TextEditingController();
    final sellingPriceC = TextEditingController();
    String status = 'in_korea_warehouse';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('إضافة سيارة جديدة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _input(vinC, 'رقم الشاصي (VIN)', Icons.qr_code, uppercase: true),
        _input(makeC, 'البراند', Icons.directions_car),
        _input(modelC, 'الموديل', Icons.model_training),
        _input(yearC, 'السنة', Icons.calendar_today, keyboard: TextInputType.number),
        _input(colorC, 'اللون', Icons.palette_outlined),
        _input(purchasePriceC, 'سعر الشراء', Icons.money_off, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        _input(sellingPriceC, 'سعر البيع', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<String>(
            value: status,
            items: _statusLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setS(() => status = v ?? 'in_korea_warehouse'),
            decoration: InputDecoration(labelText: 'الحالة', prefixIcon: const Icon(Icons.flag_outlined, size: 20), filled: true, fillColor: AppColors.bgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          ),
        ),
      ]))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        ElevatedButton(onPressed: () async {
          if (vinC.text.trim().isEmpty || makeC.text.trim().isEmpty || modelC.text.trim().isEmpty) {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('يرجى ملء الحقول المطلوبة (VIN، البراند، الموديل)'), backgroundColor: AppColors.error));
            return;
          }
          Navigator.pop(ctx);
          try {
            final body = <String, dynamic>{
              'vin': vinC.text.trim().toUpperCase(),
              'make': makeC.text.trim(),
              'model': modelC.text.trim(),
              'year': yearC.text.trim(),
              'color': colorC.text.trim(),
              'status': status,
              'selling_price': double.tryParse(sellingPriceC.text.trim()) ?? 0,
              'purchase_price': double.tryParse(purchasePriceC.text.trim()) ?? 0,
            };
            await _ds.createCar(_token, body);
            _loadCars();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة السيارة بنجاح'), backgroundColor: AppColors.success));
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إضافة السيارة'), backgroundColor: AppColors.error));
          }
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.w700))),
      ],
    )));
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard, bool uppercase = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      onChanged: uppercase ? (v) { final upper = v.toUpperCase(); if (v != upper) { c.value = c.value.copyWith(text: upper, selection: TextSelection.collapsed(offset: upper.length)); } } : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: AppColors.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
    ),
  );

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning && _scannerController != null) {
      return Scaffold(
        body: Stack(children: [
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onBarcodeDetected,
          ),
          // Scan overlay frame
          Center(child: Container(
            width: 300, height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('ضع الباركود داخل الإطار', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 8, color: Colors.black)]))),
          )),
          // Top bar
          Positioned(top: 0, left: 0, right: 0, child: Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: _stopScanning),
              const Expanded(child: Text('ماسح الباركود VIN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
              const SizedBox(width: 48),
            ]),
          )),
          // Bottom instructions
          Positioned(bottom: 40, left: 0, right: 0, child: Center(child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
              child: const Text('وجّه الكاميرا نحو باركود الشاصي', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _stopScanning,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('إلغاء المسح', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]))),
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ماسح الباركود VIN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingCars
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('جاري تحميل بيانات السيارات...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ]))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.textGray)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadCars, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
                ]))
              : Center(child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Icon
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF9333EA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: const Icon(Icons.qr_code_scanner, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text('ماسح باركود VIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('امسح باركود رقم الشاصي للبحث عن\nالسيارة أو إضافة سيارة جديدة', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.6)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('${_cars.length} سيارة محملة في قاعدة البيانات', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _startScanning,
                      icon: const Icon(Icons.camera_alt_outlined, size: 22),
                      label: const Text('بدء المسح', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Features
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                      child: Column(children: [
                        _featureRow(Icons.search, 'البحث التلقائي', 'يبحث في قاعدة البيانات عن VIN'),
                        const Divider(height: 20),
                        _featureRow(Icons.check_circle_outline, 'عرض التفاصيل', 'يعرض بيانات السيارة مباشرة'),
                        const Divider(height: 20),
                        _featureRow(Icons.add_circle_outline, 'إضافة سريعة', 'إضافة سيارة جديدة بـ VIN مملوء'),
                      ]),
                    ),
                  ]),
                )),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ])),
    ]);
  }
}
