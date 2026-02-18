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
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }
  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getStoreSettings(_token);
      if (!mounted) return;
      setState(() { _settings = data; _isLoading = false; });
    } catch (e) { if (!mounted) return; setState(() { _error = 'فشل تحميل إعدادات المتجر'; _isLoading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المتجر', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      drawer: const AppDrawer(currentRoute: AppRoutes.storeSettingsPage),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة')),
            ]))
          : RefreshIndicator(color: AppColors.primary, onRefresh: _load, child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection('معلومات المتجر', Icons.store, [
                  _buildSettingRow('اسم المتجر', _settings['store_name'] ?? _settings['storeName'] ?? '-'),
                  _buildSettingRow('رابط المتجر', _settings['store_url'] ?? _settings['storeUrl'] ?? '-'),
                  _buildSettingRow('البريد الإلكتروني', _settings['email'] ?? '-'),
                  _buildSettingRow('الهاتف', _settings['phone'] ?? '-'),
                ]),
                const SizedBox(height: 16),
                _buildSection('إعدادات العرض', Icons.display_settings, [
                  _buildSettingRow('إظهار الأسعار', _settings['show_prices'] ?? _settings['showPrices'] == true ? 'نعم' : 'لا'),
                  _buildSettingRow('العملة الافتراضية', _settings['default_currency'] ?? _settings['defaultCurrency'] ?? 'USD'),
                  _buildSettingRow('اللغة', _settings['language'] ?? 'العربية'),
                ]),
                const SizedBox(height: 16),
                _buildSection('إعدادات المبيعات', Icons.point_of_sale, [
                  _buildSettingRow('ضريبة القيمة المضافة', '${_settings['vat'] ?? _settings['tax'] ?? _settings['vat_percentage'] ?? 0}%'),
                  _buildSettingRow('الخصم الافتراضي', '${_settings['default_discount'] ?? _settings['defaultDiscount'] ?? 0}%'),
                  _buildSettingRow('طريقة الدفع الافتراضية', _settings['default_payment_method'] ?? _settings['defaultPaymentMethod'] ?? '-'),
                ]),
                const SizedBox(height: 16),
                _buildSection('إعدادات الشحن', Icons.local_shipping, [
                  _buildSettingRow('تكلفة الشحن الافتراضية', '${_settings['default_shipping_cost'] ?? _settings['defaultShippingCost'] ?? 0}'),
                  _buildSettingRow('ميناء الوصول', _settings['arrival_port'] ?? _settings['arrivalPort'] ?? '-'),
                ]),
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

  Widget _buildSettingRow(String label, String value) {
    if (value == '-' || value == 'null') value = '-';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600), textAlign: TextAlign.start)),
      ]),
    );
  }
}
