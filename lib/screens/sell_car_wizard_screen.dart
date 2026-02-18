import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class SellCarWizardScreen extends StatefulWidget {
  const SellCarWizardScreen({super.key});
  @override
  State<SellCarWizardScreen> createState() => _SellCarWizardScreenState();
}

class _SellCarWizardScreenState extends State<SellCarWizardScreen> {
  late final DataService _ds;
  List<Map<String, dynamic>> _cars = [];
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  int _currentStep = 0;

  // Step 1: Car selection
  String? _selectedCarId;
  Map<String, dynamic>? _selectedCar;

  // Step 2: Customer selection/creation
  String? _selectedCustomerId;
  Map<String, dynamic>? _selectedCustomer;
  bool _createNewCustomer = false;
  final _newCustomerNameC = TextEditingController();
  final _newCustomerPhoneC = TextEditingController();

  // Step 3: Sale details
  final _priceC = TextEditingController();
  String _currency = 'USD';
  String _paymentMethod = 'cash';
  DateTime _saleDate = DateTime.now();
  final _notesC = TextEditingController();

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
    _priceC.dispose();
    _notesC.dispose();
    _newCustomerNameC.dispose();
    _newCustomerPhoneC.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _ds.getCars(_token),
        _ds.getCustomers(_token),
      ]);
      if (!mounted) return;
      setState(() {
        _cars = results[0];
        _customers = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل تحميل البيانات'; _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> get _availableCars {
    return _cars.where((c) {
      final status = (c['status'] ?? '').toString().toLowerCase();
      return status != 'sold';
    }).toList();
  }

  String _carDisplayName(Map<String, dynamic> car) {
    final make = car['make'] ?? car['brand'] ?? '';
    final model = car['model'] ?? '';
    final year = car['year'] ?? '';
    return '$make $model${year.toString().isNotEmpty ? ' ($year)' : ''}'.trim();
  }

  String _customerDisplayName(Map<String, dynamic> customer) {
    final name = customer['name'] ?? '';
    final code = customer['customer_code'] ?? customer['customerCode'] ?? '';
    return '$name${code.toString().isNotEmpty ? ' ($code)' : ''}'.trim();
  }

  String _paymentMethodLabel(String value) {
    for (final m in _paymentMethods) {
      if (m['value'] == value) return m['label']!;
    }
    return value;
  }

  String _currencySymbol(String code) {
    for (final c in _currencyOptions) {
      if (c['code'] == code) return c['symbol']!;
    }
    return code;
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_selectedCarId == null || _selectedCarId!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار سيارة'), backgroundColor: AppColors.error));
          return false;
        }
        return true;
      case 1:
        if (!_createNewCustomer && (_selectedCustomerId == null || _selectedCustomerId!.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار أو إنشاء عميل'), backgroundColor: AppColors.error));
          return false;
        }
        if (_createNewCustomer && _newCustomerNameC.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم العميل'), backgroundColor: AppColors.error));
          return false;
        }
        return true;
      case 2:
        if (_priceC.text.trim().isEmpty || (double.tryParse(_priceC.text.trim()) ?? 0) <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال سعر البيع'), backgroundColor: AppColors.error));
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submitSale() async {
    setState(() => _isSubmitting = true);
    try {
      String? customerId = _selectedCustomerId;

      // Create new customer if needed
      if (_createNewCustomer) {
        final newCustomer = await _ds.createCustomer(_token, {
          'name': _newCustomerNameC.text.trim(),
          if (_newCustomerPhoneC.text.trim().isNotEmpty)
            'phone': _newCustomerPhoneC.text.trim(),
        });
        customerId = (newCustomer['id'] ?? newCustomer['_id'])?.toString();
      }

      // Create sale
      await _ds.createSale(_token, {
        'car_id': int.tryParse(_selectedCarId!) ?? _selectedCarId,
        if (customerId != null && customerId.isNotEmpty)
          'customer_id': int.tryParse(customerId) ?? customerId,
        'sale_price': double.tryParse(_priceC.text.trim()) ?? 0,
        'currency': _currency,
        'payment_method': _paymentMethod,
        'sale_date': '${_saleDate.year}-${_saleDate.month.toString().padLeft(2, '0')}-${_saleDate.day.toString().padLeft(2, '0')}',
        if (_notesC.text.trim().isNotEmpty) 'notes': _notesC.text.trim(),
      });

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم بيع السيارة بنجاح'), backgroundColor: AppColors.success));
      Navigator.pushReplacementNamed(context, AppRoutes.salesPage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل إتمام عملية البيع'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بيع سيارة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.sellCarWizard),
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
              : Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  controlsBuilder: (context, details) {
                    final isLastStep = _currentStep == 3;
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          if (!isLastStep)
                            ElevatedButton(
                              onPressed: details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('التالي', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          if (isLastStep)
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : () => _submitSale(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('تأكيد البيع', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          const SizedBox(width: 8),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('السابق'),
                            ),
                        ],
                      ),
                    );
                  },
                  onStepContinue: () {
                    if (_validateStep(_currentStep)) {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      }
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) setState(() => _currentStep--);
                  },
                  onStepTapped: (step) {
                    // Only allow going back, or going forward if current step is valid
                    if (step < _currentStep) {
                      setState(() => _currentStep = step);
                    } else if (step == _currentStep + 1 && _validateStep(_currentStep)) {
                      setState(() => _currentStep = step);
                    }
                  },
                  steps: [
                    // Step 1: Select car
                    Step(
                      title: const Text('اختيار السيارة', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: _selectedCar != null ? Text(_carDisplayName(_selectedCar!), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)) : null,
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                      content: _buildStep1(),
                    ),
                    // Step 2: Select/Create customer
                    Step(
                      title: const Text('بيانات المشتري', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: _selectedCustomer != null
                          ? Text(_customerDisplayName(_selectedCustomer!), style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
                          : _createNewCustomer && _newCustomerNameC.text.isNotEmpty
                              ? Text('عميل جديد: ${_newCustomerNameC.text}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted))
                              : null,
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                      content: _buildStep2(),
                    ),
                    // Step 3: Sale details
                    Step(
                      title: const Text('تفاصيل البيع', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: _priceC.text.isNotEmpty ? Text('${_priceC.text} $_currency', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)) : null,
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                      content: _buildStep3(),
                    ),
                    // Step 4: Review
                    Step(
                      title: const Text('مراجعة وتأكيد', style: TextStyle(fontWeight: FontWeight.w700)),
                      isActive: _currentStep >= 3,
                      state: _currentStep == 3 ? StepState.indexed : StepState.indexed,
                      content: _buildStep4(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختر السيارة المراد بيعها:', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
        const SizedBox(height: 12),
        if (_availableCars.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('لا توجد سيارات متاحة للبيع', style: TextStyle(fontSize: 13, color: AppColors.error))),
            ]),
          )
        else
          ..._availableCars.map((car) {
            final carId = (car['id'] ?? car['_id'])?.toString();
            final isSelected = _selectedCarId == carId;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
              ),
              child: ListTile(
                dense: true,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_car, size: 18, color: isSelected ? AppColors.primary : AppColors.textMuted),
                ),
                title: Text(_carDisplayName(car), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : AppColors.textDark)),
                subtitle: Text(
                  'VIN: ${(car['vin'] ?? '-').toString().length > 12 ? '...${(car['vin'] ?? '').toString().substring((car['vin'] ?? '').toString().length - 8)}' : (car['vin'] ?? '-')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22) : null,
                onTap: () {
                  setState(() {
                    _selectedCarId = carId;
                    _selectedCar = car;
                    // Pre-fill selling price if available
                    final sellingPrice = car['selling_price'] ?? car['sellingPrice'] ?? car['price'];
                    if (sellingPrice != null && sellingPrice.toString().isNotEmpty && sellingPrice.toString() != '0') {
                      _priceC.text = sellingPrice.toString();
                    }
                  });
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle: existing vs new customer
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() { _createNewCustomer = false; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_createNewCustomer ? AppColors.primary : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('عميل موجود', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: !_createNewCustomer ? Colors.white : AppColors.textGray))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() { _createNewCustomer = true; _selectedCustomerId = null; _selectedCustomer = null; }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _createNewCustomer ? AppColors.primary : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('عميل جديد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _createNewCustomer ? Colors.white : AppColors.textGray))),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_createNewCustomer) ...[
          _input(_newCustomerNameC, 'اسم العميل', Icons.person_outline),
          _input(_newCustomerPhoneC, 'رقم الهاتف (اختياري)', Icons.phone_outlined, keyboard: TextInputType.phone),
        ] else ...[
          const Text('اختر العميل:', style: TextStyle(fontSize: 13, color: AppColors.textGray)),
          const SizedBox(height: 8),
          if (_customers.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('لا يوجد عملاء مسجلين. يمكنك إنشاء عميل جديد.', style: TextStyle(fontSize: 13, color: AppColors.textGray))),
              ]),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: _customers.length,
                itemBuilder: (ctx, i) {
                  final customer = _customers[i];
                  final custId = (customer['id'] ?? customer['_id'])?.toString();
                  final isSelected = _selectedCustomerId == custId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.bgLight,
                        child: Icon(Icons.person, size: 16, color: isSelected ? AppColors.primary : AppColors.textMuted),
                      ),
                      title: Text(_customerDisplayName(customer), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textDark)),
                      subtitle: (customer['phone'] ?? '').toString().isNotEmpty
                          ? Text(customer['phone'].toString(), style: const TextStyle(fontSize: 11, color: AppColors.textMuted))
                          : null,
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 22) : null,
                      onTap: () => setState(() { _selectedCustomerId = custId; _selectedCustomer = customer; }),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _input(_priceC, 'سعر البيع', Icons.attach_money, keyboard: const TextInputType.numberWithOptions(decimal: true)),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<String>(
            value: _currency,
            items: _currencyOptions.map((c) => DropdownMenuItem(value: c['code'], child: Text(c['label']!))).toList(),
            onChanged: (v) => setState(() => _currency = v ?? 'USD'),
            decoration: InputDecoration(
              labelText: 'العملة',
              prefixIcon: const Icon(Icons.currency_exchange, size: 20),
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DropdownButtonFormField<String>(
            value: _paymentMethod,
            items: _paymentMethods.map((m) => DropdownMenuItem(value: m['value'], child: Text(m['label']!))).toList(),
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            decoration: InputDecoration(
              labelText: 'طريقة الدفع',
              prefixIcon: const Icon(Icons.payment, size: 20),
              filled: true,
              fillColor: AppColors.bgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),
        // Date picker
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _saleDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _saleDate = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'تاريخ البيع',
                prefixIcon: const Icon(Icons.calendar_today, size: 20),
                filled: true,
                fillColor: AppColors.bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              child: Text(
                '${_saleDate.year}-${_saleDate.month.toString().padLeft(2, '0')}-${_saleDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
        _input(_notesC, 'ملاحظات (اختياري)', Icons.notes),
      ],
    );
  }

  Widget _buildStep4() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.fact_check_outlined, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('ملخص عملية البيع', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          // Car
          _reviewRow('السيارة', _selectedCar != null ? _carDisplayName(_selectedCar!) : '-'),
          if (_selectedCar != null && (_selectedCar!['vin'] ?? '').toString().isNotEmpty)
            _reviewRow('رقم الشاصي', _selectedCar!['vin'].toString()),
          const Divider(height: 16),
          // Customer
          _reviewRow(
            'المشتري',
            _createNewCustomer
                ? 'عميل جديد: ${_newCustomerNameC.text.trim()}'
                : _selectedCustomer != null
                    ? _customerDisplayName(_selectedCustomer!)
                    : '-',
          ),
          if (_createNewCustomer && _newCustomerPhoneC.text.trim().isNotEmpty)
            _reviewRow('هاتف المشتري', _newCustomerPhoneC.text.trim()),
          const Divider(height: 16),
          // Sale details
          _reviewRow('سعر البيع', '${_priceC.text.trim()} $_currency'),
          _reviewRow('طريقة الدفع', _paymentMethodLabel(_paymentMethod)),
          _reviewRow('التاريخ', '${_saleDate.year}-${_saleDate.month.toString().padLeft(2, '0')}-${_saleDate.day.toString().padLeft(2, '0')}'),
          if (_notesC.text.trim().isNotEmpty)
            _reviewRow('ملاحظات', _notesC.text.trim()),
          const SizedBox(height: 12),
          // Confirmation notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(child: Text('بعد التأكيد سيتم تسجيل عملية البيع وتحديث حالة السيارة إلى "مباعة".', style: TextStyle(fontSize: 12, color: AppColors.textGray, height: 1.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon, {TextInputType? keyboard}) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
