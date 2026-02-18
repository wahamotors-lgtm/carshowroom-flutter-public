import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});
  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  late final DataService _ds;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;

  final _companyNameC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _websiteC = TextEditingController();
  final _descriptionC = TextEditingController();

  @override
  void initState() { super.initState(); _ds = DataService(ApiService()); _load(); }

  @override
  void dispose() {
    _companyNameC.dispose(); _emailC.dispose(); _phoneC.dispose();
    _addressC.dispose(); _websiteC.dispose(); _descriptionC.dispose();
    super.dispose();
  }

  String get _token => Provider.of<AuthProvider>(context, listen: false).token ?? '';

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _ds.getCompanySettings(_token);
      if (!mounted) return;
      setState(() {
        _companyNameC.text = data['company_name'] ?? data['companyName'] ?? '';
        _emailC.text = data['email'] ?? '';
        _phoneC.text = (data['phone_numbers'] ?? data['phoneNumbers'] ?? []).join(', ');
        _addressC.text = data['address'] ?? '';
        _websiteC.text = data['website'] ?? '';
        _descriptionC.text = data['description'] ?? '';
        _isLoading = false;
      });
    } catch (e) { if (!mounted) return; setState(() { _error = 'فشل تحميل الإعدادات'; _isLoading = false; }); }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _ds.updateCompanySettings(_token, {
        'company_name': _companyNameC.text.trim(),
        'email': _emailC.text.trim(),
        'address': _addressC.text.trim(),
        'website': _websiteC.text.trim(),
        'description': _descriptionC.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل حفظ الإعدادات'), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات الشركة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _error == null)
            IconButton(icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save), onPressed: _isSaving ? null : _save),
        ],
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.companySettingsPage),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: AppColors.error), const SizedBox(height: 12), Text(_error!), const SizedBox(height: 16), ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: const Text('إعادة المحاولة'))]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildField('اسم الشركة', _companyNameC, Icons.business),
                _buildField('البريد الإلكتروني', _emailC, Icons.email_outlined, keyboard: TextInputType.emailAddress),
                _buildField('أرقام الهاتف', _phoneC, Icons.phone_outlined, keyboard: TextInputType.phone),
                _buildField('العنوان', _addressC, Icons.location_on_outlined),
                _buildField('الموقع الإلكتروني', _websiteC, Icons.language, keyboard: TextInputType.url),
                _buildField('وصف الشركة', _descriptionC, Icons.description_outlined, maxLines: 3),
              ]),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboard, int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller, keyboardType: keyboard, maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label, prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }
}
