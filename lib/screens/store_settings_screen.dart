import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});
  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  late final DataService _ds;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;

  // Controllers
  final _storeNameC = TextEditingController();
  final _storeUrlC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _vatC = TextEditingController();
  final _discountC = TextEditingController();
  final _paymentMethodC = TextEditingController();
  final _shippingCostC = TextEditingController();
  final _arrivalPortC = TextEditingController();

  String _currency = 'USD';
  bool _showPrices = true;
  String _language = 'العربية';

  static const List<String> _currencies = ['USD', 'AED', 'KRW', 'SYP', 'SAR', 'CNY', 'EUR', 'GBP'];

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }

  @override
  void dispose() {
    _storeNameC.dispose(); _storeUrlC.dispose(); _emailC.dispose();
    _phoneC.dispose(); _vatC.dispose(); _discountC.dispose();
    _paymentMethodC.dispose(); _shippingCostC.dispose(); _arrivalPortC.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getStoreSettings(_token);
      if (!mounted) return;
      setState(() {
        _storeNameC.text = data['store_name'] ?? data['storeName'] ?? '';
        _storeUrlC.text = data['store_url'] ?? data['storeUrl'] ?? '';
        _emailC.text = data['email'] ?? '';
        _phoneC.text = data['phone'] ?? '';
        _vatC.text = (data['vat'] ?? data['tax'] ?? data['vat_percentage'] ?? '0').toString();
        _discountC.text = (data['default_discount'] ?? data['defaultDiscount'] ?? '0').toString();
        _paymentMethodC.text = data['default_payment_method'] ?? data['defaultPaymentMethod'] ?? '';
        _shippingCostC.text = (data['default_shipping_cost'] ?? data['defaultShippingCost'] ?? '0').toString();
        _arrivalPortC.text = data['arrival_port'] ?? data['arrivalPort'] ?? '';
        _currency = data['default_currency'] ?? data['defaultCurrency'] ?? 'USD';
        if (!_currencies.contains(_currency)) _currency = 'USD';
        _showPrices = data['show_prices'] ?? data['showPrices'] ?? true;
        _language = data['language'] ?? 'العربية';
        _isLoading = false;
      });
    } catch (e) { if (!mounted) return; setState(() { _error = e is ApiException ? e.message : 'فشل تحميل إعدادات المتجر'; _isLoading = false; }); }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _ds.updateStoreSettings(_token, {
        'store_name': _storeNameC.text.trim(),
        'store_url': _storeUrlC.text.trim(),
        'email': _emailC.text.trim(),
        'phone': _phoneC.text.trim(),
        'show_prices': _showPrices,
        'default_currency': _currency,
        'language': _language,
        'vat': num.tryParse(_vatC.text.trim()) ?? 0,
        'default_discount': num.tryParse(_discountC.text.trim()) ?? 0,
        'default_payment_method': _paymentMethodC.text.trim(),
        'default_shipping_cost': num.tryParse(_shippingCostC.text.trim()) ?? 0,
        'arrival_port': _arrivalPortC.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات بنجاح'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'فشل حفظ الإعدادات'), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات المتجر', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _save,
            ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.storeSettingsPage),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12), Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
                ]))
              : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSection('معلومات المتجر', Icons.store, [
                      _buildField('اسم المتجر', _storeNameC, Icons.store_outlined),
                      _buildField('رابط المتجر', _storeUrlC, Icons.link, keyboard: TextInputType.url),
                      _buildField('البريد الإلكتروني', _emailC, Icons.email_outlined, keyboard: TextInputType.emailAddress),
                      _buildField('الهاتف', _phoneC, Icons.phone_outlined, keyboard: TextInputType.phone),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection('إعدادات العرض', Icons.display_settings, [
                      // Show prices toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('إظهار الأسعار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          Switch(value: _showPrices, activeColor: AppColors.primary, onChanged: (v) => setState(() => _showPrices = v)),
                        ]),
                      ),
                      // Currency dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: InputDecoration(
                            labelText: 'العملة الافتراضية',
                            prefixIcon: const Icon(Icons.currency_exchange, size: 20),
                            filled: true, fillColor: AppColors.bgLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _currency = v ?? 'USD'),
                        ),
                      ),
                      // Language dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: DropdownButtonFormField<String>(
                          value: _language,
                          decoration: InputDecoration(
                            labelText: 'اللغة',
                            prefixIcon: const Icon(Icons.language, size: 20),
                            filled: true, fillColor: AppColors.bgLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'العربية', child: Text('العربية')),
                            DropdownMenuItem(value: 'English', child: Text('English')),
                          ],
                          onChanged: (v) => setState(() => _language = v ?? 'العربية'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection('إعدادات المبيعات', Icons.point_of_sale, [
                      _buildField('ضريبة القيمة المضافة %', _vatC, Icons.percent, keyboard: TextInputType.number),
                      _buildField('الخصم الافتراضي %', _discountC, Icons.discount_outlined, keyboard: TextInputType.number),
                      _buildField('طريقة الدفع الافتراضية', _paymentMethodC, Icons.payment_outlined),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection('إعدادات الشحن', Icons.local_shipping, [
                      _buildField('تكلفة الشحن الافتراضية', _shippingCostC, Icons.attach_money, keyboard: TextInputType.number),
                      _buildField('ميناء الوصول', _arrivalPortC, Icons.anchor_outlined),
                    ]),
                    const SizedBox(height: 24),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الإعدادات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                )),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ]),
        ),
        const Divider(height: 1),
        ...children,
      ]),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller, keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
          filled: true, fillColor: AppColors.bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }
}
