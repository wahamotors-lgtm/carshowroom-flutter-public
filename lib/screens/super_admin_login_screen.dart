import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/theme.dart';
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/logo_header.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});
  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  late final DataService _ds;
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _ds = DataService(ApiService());
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _ds.adminLogin(_emailC.text.trim(), _passC.text);
      if (!mounted) return;
      if (res['token'] != null) {
        final storage = StorageService();
        await storage.saveAdminToken(res['token']);
        if (res['admin'] != null) await storage.saveAdmin(res['admin']);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.superAdminDashboard);
      } else {
        setState(() { _error = res['message'] ?? 'فشل تسجيل الدخول'; _loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e is ApiException ? e.message : 'فشل الاتصال بالخادم'; _loading = false; });
    }
  }

  @override
  void dispose() { _emailC.dispose(); _passC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0000), Color(0xFF4A0E0E), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Admin icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFF991B1B)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 20),
                    const LogoHeader(iconSize: 0, fontSize: 24, showSubtitle: false),
                    const SizedBox(height: 8),
                    const Text('لوحة المدير العام', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      'أدخل بيانات المدير للدخول إلى لوحة التحكم',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 32),
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13), textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildDarkField(
                      label: 'البريد الإلكتروني',
                      controller: _emailC,
                      icon: Icons.email_outlined,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.trim().isEmpty) return 'مطلوب';
                        if (!v.contains('@')) return 'بريد غير صحيح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDarkField(
                      label: 'كلمة المرور',
                      controller: _passC,
                      icon: Icons.lock_outlined,
                      obscure: _obscure,
                      toggleObscure: () => setState(() => _obscure = !_obscure),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('تسجيل الدخول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.tenantLogin),
                      child: Text('دخول كشركة', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined, size: 16, color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text(
                          'info@carwhats.com',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextDirection? textDirection,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textDirection: textDirection,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white.withValues(alpha: 0.4), size: 20),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error)),
        errorStyle: const TextStyle(color: Color(0xFFFCA5A5)),
      ),
    );
  }
}
